import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'AlertDeactivation.dart';
import 'features/sos_alert/service/location_service.dart'
    as sos_location; // Add alias
import 'features/sos_alert/service/audio_recorder_service.dart';
import 'BlinkingIcon.dart';
import 'GuardianModeSafetyManual.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hello_flutter/features/sos_alert/guard_view/RouteTracker.dart';

class GuardianModeScreen extends StatefulWidget {
  final String initialMessage;
  final String alertId;
  final AudioPlayer audioPlayer;

  const GuardianModeScreen({
    super.key,
    required this.initialMessage,
    required this.alertId,
    required this.audioPlayer,
  });

  @override
  State<GuardianModeScreen> createState() => _GuardianModeScreenState();
}

class _GuardianModeScreenState extends State<GuardianModeScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String _distanceRemaining = "";
  String _durationRemaining = "";

  late sos_location.LocationService _locationService;
  late AudioRecorderService _audioRecorder;
  RouteTracker? _routeTracker; // Make nullable
  StreamSubscription? _alertStatusSubscription;
  final pinController = TextEditingController();
  final String safePin = "0000";
  final String duressPin = "1234";
  bool _isDuressExit = false;
  StreamSubscription? _guardLocationSubscription;
  LatLng? _userPosition;
  LatLng? _guardPosition;
  String? _guardIdOnAlert;
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();

  // 路线跟踪
  double _trackedDistance = 0;
  int _trackedPoints = 0;
  bool _isRouteTrackerInitialized = false;
  final String _apiKey = "AIzaSyALfVigfIlFFmcVIEy-5OGos42GViiQe-M";

  @override
  void initState() {
    super.initState();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // 开始共享用户的位置
    _locationService = sos_location.LocationService(
      widget.alertId,
      isAlert: true,
    );
    _locationService.startSharingLocation();

    // 开始录音
    _audioRecorder = AudioRecorderService(widget.alertId, isAlert: true);
    _audioRecorder.initRecorder().then((_) => _audioRecorder.startRecording());

    // 监听 alert 状态
    _alertStatusSubscription = FirebaseFirestore.instance
        .collection('alerts')
        .doc(widget.alertId)
        .snapshots()
        .listen((doc) async {
      if (!mounted || !doc.exists || doc.data() == null) return;

      final data = doc.data()!;
      final status = data['status'];

      // ✅ 如果结束或取消，停止所有服务
      if (status == 'completed' || status == 'cancelled') {
        _alertStatusSubscription?.cancel();
        _alertStatusSubscription = null;

        await _audioRecorder.stopAndUpload();
        await _locationService.stopSharingLocation();
        _routeTracker?.stopTracking();

        if (!mounted) return;
        final navContext = context;
        ScaffoldMessenger.of(navContext).showSnackBar(
          SnackBar(
            content: Text(
              status == 'completed'
                  ? "Alert has been resolved by the guard."
                  : "Alert has been cancelled.",
            ),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.of(navContext).pop();
        }
        return;
      }

      // ✅ 实时更新 user 位置
      if (data['latitude'] != null && data['longitude'] != null) {
        final newUserPosition = LatLng(data['latitude'], data['longitude']);
        if (newUserPosition != _userPosition) {
          setState(() {
            _userPosition = newUserPosition;
            _updateMarkers();

            // 当用户位置更新时，重新初始化路线跟踪
            if (_guardPosition != null && _userPosition != null) {
              _initializeRouteTracker();
            }
          });
        }
      }

      // ✅ 有守卫 ID → 开始监听守卫位置
      final guardId = data['guardId'] as String?;
      if (guardId != null && _guardIdOnAlert != guardId) {
        _guardIdOnAlert = guardId;
        _listenToGuardLocation();
      }
    });
  }

  void _initializeRouteTracker() async {
    try {
      // 停止现有的跟踪
      _routeTracker?.stopTracking();

      // 确保我们有有效的起点和终点
      if (_guardPosition == null || _userPosition == null) {
        debugPrint("Cannot initialize route tracker: missing positions");
        return;
      }

      _routeTracker = RouteTracker(
        apiKey: _apiKey,
        origin: _guardPosition,
        destination: _userPosition!,
        onRouteReady: (points) {
          if (!mounted) return;
          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                width: 6,
                color: Colors.blue,
              ),
            };
          });
        },
        onLocationUpdated: (latlng) {
          if (!mounted) return;
          setState(() {
            _guardPosition = latlng;
            _updateGuardMarker();
          });
        },
        onProgressUpdated: (remainingMeters, etaMinutes) {
          if (!mounted) return;
          setState(() {
            _distanceRemaining =
                '${(remainingMeters / 1000.0).toStringAsFixed(2)} km';
            _durationRemaining = '${etaMinutes.toStringAsFixed(0)} min';
            _trackedDistance = remainingMeters;
          });
        },
        onArrived: () {
          if (!mounted) return;
          setState(() {
            // 到达目的地
          });
        },
        onError: (err) {
          debugPrint("RouteTracker error: $err");
        },
      );

      await _routeTracker!.initialize();
      _routeTracker!.startTracking();
      setState(() {
        _isRouteTrackerInitialized = true;
      });
    } catch (e) {
      debugPrint("Failed to initialize route tracker: $e");
      setState(() {
        _isRouteTrackerInitialized = false;
      });
    }
  }

  void _updateMarkers() {
    _markers.clear();
    if (_userPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: "Your Location"),
        ),
      );
    }
    if (_guardPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('guard_location'),
          position: _guardPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: "Guard's Location"),
        ),
      );
    }
    _updateCameraBounds();
  }

  void _updateGuardMarker() {
    _updateMarkers();
  }

  void _listenToGuardLocation() {
    if (_guardIdOnAlert == null) return;
    _guardLocationSubscription?.cancel();
    _guardLocationSubscription = FirebaseFirestore.instance
        .collection('guards')
        .doc(_guardIdOnAlert)
        .snapshots()
        .listen((doc) {
      if (mounted && doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['latitude'] != null && data['longitude'] != null) {
          final newGuardPosition = LatLng(
            data['latitude'],
            data['longitude'],
          );
          if (newGuardPosition != _guardPosition) {
            setState(() {
              _guardPosition = newGuardPosition;
              _updateMarkers();

              // 当守卫位置更新时，重新初始化路线跟踪
              if (_guardPosition != null && _userPosition != null) {
                _initializeRouteTracker();
              }
            });
          }
        }
      }
    });
  }

  Future<void> _updateCameraBounds() async {
    if (!mounted ||
        _userPosition == null ||
        !_mapControllerCompleter.isCompleted) return;

    final controller = await _mapControllerCompleter.future;

    if (_guardPosition == null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(_userPosition!, 16));
    } else {
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              _userPosition!.latitude < _guardPosition!.latitude
                  ? _userPosition!.latitude
                  : _guardPosition!.latitude,
              _userPosition!.longitude < _guardPosition!.longitude
                  ? _userPosition!.longitude
                  : _guardPosition!.longitude,
            ),
            northeast: LatLng(
              _userPosition!.latitude > _guardPosition!.latitude
                  ? _userPosition!.latitude
                  : _guardPosition!.latitude,
              _userPosition!.longitude > _guardPosition!.longitude
                  ? _userPosition!.longitude
                  : _guardPosition!.longitude,
            ),
          ),
          100.0,
        ),
      );
    }
  }

  Future<void> _onDeactivatePressed() async {
    final result = await showDeactivationDialog(
      context,
      pinController,
      safePin,
      duressPin,
      widget.audioPlayer,
      alertId: widget.alertId,
      onDeactivate: () async {
        await _locationService.stopSharingLocation();
        _routeTracker?.stopTracking();
      },
    );

    if (!mounted) return;

    if (result == 'safe') {
    } else if (result == 'duress') {
      setState(() {
        _isDuressExit = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            "✅ Alert appears cancelled. Security notified of duress.",
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _alertStatusSubscription?.cancel();
    _guardLocationSubscription?.cancel();
    pinController.dispose();
    _routeTracker?.dispose();

    if (!_isDuressExit) {
      _audioRecorder.stopAndUpload();
      _locationService.stopSharingLocation();
      _audioRecorder.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Column(
                  children: [
                    Text(
                      widget.initialMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Help is on the way...",
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const BlinkingIcon(iconSize: 30),
                      const SizedBox(height: 8),
                      const Text(
                        "Recording in progress",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (_distanceRemaining.isNotEmpty)
                        Text(
                          "Guard is ${_distanceRemaining} away (${_durationRemaining})",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: GoogleMap(
                            initialCameraPosition: const CameraPosition(
                              target: LatLng(1.5583, 103.6375),
                              zoom: 15,
                            ),
                            onMapCreated: (c) {
                              if (!_mapControllerCompleter.isCompleted) {
                                _mapControllerCompleter.complete(c);
                              }
                            },
                            markers: _markers,
                            polylines: _polylines,
                            myLocationEnabled: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _onDeactivatePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade900,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("Deactivate with PIN"),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Route Information"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Distance remaining: ${_trackedDistance.toStringAsFixed(2)} meters",
                      ),
                      Text("Route points: ${_polylines.isNotEmpty ? _polylines.first.points.length : 0}"),
                      Text(
                        "Status: ${_routeTracker?.isTracking == true ? 'Tracking' : 'Not Tracking'}",
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              ),
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade900,
              child: const Icon(Icons.route),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              onPressed: () =>
                  showSafetyManualDialog(context, widget.initialMessage),
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade900,
              child: const Icon(Icons.menu_book),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}