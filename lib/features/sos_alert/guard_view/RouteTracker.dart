import 'dart:async';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// RouteTracker: 计算一次完整路线（origin -> destination），
/// 然后订阅位置流并持续更新剩余距离/ETA。
class RouteTracker {
  final String apiKey;
  LatLng? origin; // 可选：如果为 null，initialize() 会自动获取当前位置作为 origin
  final LatLng destination;

  final void Function(List<LatLng> routePoints)? onRouteReady;
  final void Function(LatLng current)? onLocationUpdated;
  /// remainingMeters, etaMinutes
  final void Function(double remainingMeters, double etaMinutes)? onProgressUpdated;
  final VoidCallback? onArrived;
  final void Function(Object error)? onError;

  StreamSubscription<Position>? _positionSub;
  List<LatLng> _routePoints = [];
  List<Map<String, dynamic>> _steps = [];

  double totalDistanceMeters = 0;
  double totalDurationSeconds = 0;
  bool _isTracking = false;
  bool _hasArrived = false;

  /// 可配置：到达判定阈值（米）
  final double arrivalThresholdMeters;

  RouteTracker({
    required this.apiKey,
    this.origin,
    required this.destination,
    this.onRouteReady,
    this.onLocationUpdated,
    this.onProgressUpdated,
    this.onArrived,
    this.onError,
    this.arrivalThresholdMeters = 50.0,
  });

  bool get isTracking => _isTracking;

  /// 初始化：若 origin 为空会尝试获取当前位置，然后调用 Directions API 获取路线
  Future<void> initialize() async {
    try {
      // 如果没有 origin，先取当前设备位置
      if (origin == null) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );
        origin = LatLng(pos.latitude, pos.longitude);
      }

      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${origin!.latitude},${origin!.longitude}"
        "&destination=${destination.latitude},${destination.longitude}"
        "&mode=walking&key=$apiKey",
      );

      final res = await http.get(url).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        throw Exception("Directions API failed (HTTP ${res.statusCode})");
      }

      final data = json.decode(res.body);
      if (data == null || data['status'] != 'OK' || (data['routes'] as List).isEmpty) {
        final status = data?['status'] ?? 'UNKNOWN_ERROR';
        throw Exception("Directions API returned status: $status");
      }

      final route = data['routes'][0];
      final points = (route['overview_polyline']?['points'] ?? '') as String;
      _routePoints = _decodePolyline(points);

      final leg = route['legs'][0];
      totalDistanceMeters = (leg['distance']?['value'] ?? 0).toDouble();
      totalDurationSeconds = (leg['duration']?['value'] ?? 0).toDouble();
      _steps = List<Map<String, dynamic>>.from(leg['steps'] ?? []);

      onRouteReady?.call(_routePoints);
    } catch (e) {
      onError?.call(e);
      rethrow;
    }
  }

  /// 开始订阅位置变化（不会重复请求 Directions API）
  void startTracking() {
    if (_positionSub != null) return; // 防重入
    _hasArrived = false;

    _isTracking = true;
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      final latLng = LatLng(pos.latitude, pos.longitude);
      onLocationUpdated?.call(latLng);

      // 剩余直线距离（米）
      final remainingMeters = Geolocator.distanceBetween(
        latLng.latitude,
        latLng.longitude,
        destination.latitude,
        destination.longitude,
      );

      // 更准确 ETA：用 Google 的总 duration 按比例缩放
      double etaMinutes;
      if (totalDistanceMeters > 0 && totalDurationSeconds > 0) {
        final ratio = remainingMeters / totalDistanceMeters;
        etaMinutes = (totalDurationSeconds * ratio) / 60.0;
      } else {
        // fallback：固定步速 5 km/h
        etaMinutes = (remainingMeters / 1000.0) / 5.0 * 60.0;
      }

      onProgressUpdated?.call(remainingMeters, etaMinutes);

      // 判定到达
      if (!_hasArrived && remainingMeters <= arrivalThresholdMeters) {
        _hasArrived = true;
        onArrived?.call();
        stopTracking();
      }
    }, onError: (e) {
      onError?.call(e);
    });
  }

  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _isTracking = false;
  }

  void dispose() => stopTracking();

  List<LatLng> get routePoints => List.unmodifiable(_routePoints);
  List<Map<String, dynamic>> get steps => List.unmodifiable(_steps);

  // --- polyline 解码（Google 的 encoded polyline） ---
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
