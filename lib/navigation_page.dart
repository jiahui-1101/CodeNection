import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'SmartSosButton.dart';
import 'package:hello_flutter/SafetyCompanionBottomSheet.dart';

class NavigationPage extends StatefulWidget {
  final String currentLocation;
  final String destination;
  final bool isWalkingTogether;
  final List<Map<String, dynamic>>? matchedPartners;
  final LatLng? destinationLatLng;
  final VoidCallback onStartJourney;

  const NavigationPage({
    super.key,
    required this.currentLocation,
    required this.destination,
    required this.onStartJourney,
    this.destinationLatLng,
    this.isWalkingTogether = false,
    this.matchedPartners,
  });

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final Completer<GoogleMapController> _controller = Completer();

  // ✅ Use only serverApiKey in HTTP calls
  final String serverApiKey = "AIzaSyD8v9hGJLHwma7zYUFhpW4WVbNlehYhpGk";

  LatLng? _currentPosition;
  LatLng? _destinationLatLng;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Timer? _locationTimer;

  double _distanceRemaining = 0;
  double _timeRemaining = 0;
  String _nextInstruction = "";
  bool _isNavigating = true;
  bool _isLocationAccurate = true;
  double _locationAccuracy = 0.0;
  bool _isLoading = true;
  String _errorMessage = "";

  bool _showSafetyCompanion = false;
  final AudioPlayer _safetyAudioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _safetyAudioPlayer.dispose();
    super.dispose();
  }

  void _toggleSafetyCompanion() {
    if (!widget.isWalkingTogether) {
      setState(() {
        _showSafetyCompanion = !_showSafetyCompanion;
      });
    }
  }

  Future<void> _initializeNavigation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = "";
      });

      _destinationLatLng =
          widget.destinationLatLng ??
          await _resolveDestination(widget.destination);

      if (_destinationLatLng == null) {
        throw Exception("Could not resolve destination coordinates");
      }

      await _getCurrentLocationWithRetry();
      await _calculateRoute();
      _startLocationUpdates();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to initialize navigation: ${e.toString()}";
      });
    }
  }

  Future<LatLng?> _resolveDestination(String address) async {
    try {
      final placeUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
        '?query=${Uri.encodeComponent(address)}&key=$serverApiKey',
      );

      final placeRes = await http.get(placeUrl);
      final placeData = json.decode(placeRes.body);

      if (placeData['status'] == 'OK' && placeData['results'].isNotEmpty) {
        final placeId = placeData['results'][0]['place_id'];

        final geoUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?place_id=$placeId&key=$serverApiKey',
        );

        final geoRes = await http.get(geoUrl);
        final geoData = json.decode(geoRes.body);

        if (geoData['status'] == 'OK' && geoData['results'].isNotEmpty) {
          final loc = geoData['results'][0]['geometry']['location'];
          return LatLng(loc['lat'], loc['lng']);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _getCurrentLocationWithRetry({int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 10),
        );

        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _locationAccuracy = position.accuracy;
          _isLocationAccurate = position.accuracy < 20.0;
        });

        if (_controller.isCompleted) {
          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition!, 15),
          );
        }

        if (_isLocationAccurate) break;
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        if (i == retryCount - 1) {
          throw Exception("Failed to get current location: $e");
        }
      }
    }
  }

  Future<void> _calculateRoute() async {
    if (_currentPosition == null || _destinationLatLng == null) return;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?'
      'origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&'
      'destination=${_destinationLatLng!.latitude},${_destinationLatLng!.longitude}&'
      'mode=walking&key=$serverApiKey',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final points = data['routes'][0]['overview_polyline']['points'];
      final List<LatLng> routeCoordinates = _decodePolyline(points);

      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('current'),
            position: _currentPosition!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
          Marker(
            markerId: const MarkerId('destination'),
            position: _destinationLatLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        };

        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: routeCoordinates,
            color: Colors.blue,
            width: 6,
          ),
        };

        final route = data['routes'][0]['legs'][0];
        _distanceRemaining = route['distance']['value'] / 1000;
        _timeRemaining = route['duration']['value'] / 60;
        if (route['steps'].isNotEmpty) {
          _nextInstruction = route['steps'][0]['html_instructions']
              .toString()
              .replaceAll(RegExp(r'<[^>]*>'), '');
        }
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        await _getCurrentLocationWithRetry(retryCount: 1);
        _updateNavigationInfo();

        // 👇 Keep the map camera centered on you
        if (_currentPosition != null && _controller.isCompleted) {
          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentPosition!,
                zoom: 18, // 👈 adjust zoom (higher = closer in)
                tilt: 60, // optional: 3D tilt
                bearing: 0, // could be heading if you want compass follow
              ),
            ),
          );
        }
      } catch (_) {}
    });
  }

  void _updateNavigationInfo() {
    if (_currentPosition == null || _destinationLatLng == null) return;
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _destinationLatLng!.latitude,
      _destinationLatLng!.longitude,
    );
    setState(() {
      _distanceRemaining = distance / 1000;
      _timeRemaining = (_distanceRemaining / 5) * 60;
      if (distance < 50) {
        _isNavigating = false;
        _nextInstruction = "You have arrived at your destination!";
        _locationTimer?.cancel();
      }
    });
  }

  void _recalibrateLocation() async {
    try {
      await _getCurrentLocationWithRetry();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to recalibrate: $e")));
    }
  }

  void _endNavigation() {
    _locationTimer?.cancel();
    Navigator.pop(context);
  }

  Widget _buildNavigationCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.navigation, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.destination,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Distance and Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricItem(
                      Icons.directions_walk,
                      "${_distanceRemaining.toStringAsFixed(1)} km",
                      "Distance",
                      Colors.blue,
                    ),
                    _buildMetricItem(
                      Icons.access_time,
                      "${_timeRemaining.toStringAsFixed(0)} min",
                      "Time",
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Next Instruction
                if (_nextInstruction.isNotEmpty && _isNavigating)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Next Instruction:",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.turn_right,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _nextInstruction,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                // Accuracy Warning
                if (!_isLocationAccurate && _isNavigating)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Low location accuracy (±${_locationAccuracy.toStringAsFixed(0)}m)",
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildWalkingTogetherCard() {
    if (widget.matchedPartners == null || widget.matchedPartners!.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "👥 Walking Together With",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.matchedPartners!.map((partner) {
                return Chip(
                  label: Text(partner['name'] ?? 'Partner'),
                  avatar: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(partner['profileImage'] ?? '👤'),
                  ),
                  backgroundColor: Colors.blue.shade50,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Build the arrival overlay
  Widget _buildArrivalOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                const Text(
                  "Destination Reached!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "You have arrived at ${widget.destination}",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _endNavigation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Done",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Navigation"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isNavigating)
            IconButton(
              icon: const Icon(Icons.gps_fixed),
              onPressed: _recalibrateLocation,
              tooltip: "Recalibrate GPS",
            ),
          IconButton(icon: const Icon(Icons.close), onPressed: _endNavigation),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Setting up navigation..."),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeNavigation,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? const LatLng(0, 0),
                    zoom: 18,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: true,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _controller.complete(controller);
                  },
                ),

                // Navigation Card (only show when navigating)
                if (_isNavigating)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: _buildNavigationCard(),
                  ),

                // Walking Together Card (only show when navigating and with partners)
                if (widget.isWalkingTogether && _isNavigating)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: _buildWalkingTogetherCard(),
                  ),

                // Safety Companion Bottom Sheet - Only show when walking alone and navigating
                if (_showSafetyCompanion &&
                    !widget.isWalkingTogether &&
                    _isNavigating)
                  Positioned(
                    bottom: widget.isWalkingTogether ? 170.0 : 86.0,
                    left: 16.0,
                    right: 16.0,
                    child: const SafetyCompanionBottomSheetWrapper(),
                  ),

                // Safety Companion Toggle Button - Only show when walking alone and navigating
                if (!widget.isWalkingTogether && _isNavigating)
                  Positioned(
                    bottom: widget.isWalkingTogether ? 100 : 16,
                    left: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: _showSafetyCompanion
                          ? Colors.blue
                          : Colors.white,
                      onPressed: _toggleSafetyCompanion,
                      child: Icon(
                        Icons.record_voice_over,
                        color: _showSafetyCompanion
                            ? Colors.white
                            : Colors.blue,
                      ),
                    ),
                  ),

                // Zoom Controls (only show when navigating) - Moved up to avoid SOS button
                if (_isNavigating)
                  Positioned(
                    bottom: widget.isWalkingTogether ? 170 : 140, // Moved up
                    right: 16,
                    child: Column(
                      children: [
                        FloatingActionButton(
                          mini: true,
                          heroTag: "zoom_in",
                          backgroundColor: Colors.white,
                          onPressed: () async {
                            final controller = await _controller.future;
                            controller.animateCamera(CameraUpdate.zoomIn());
                          },
                          child: const Icon(Icons.add, color: Colors.black),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          mini: true,
                          heroTag: "zoom_out",
                          backgroundColor: Colors.white,
                          onPressed: () async {
                            final controller = await _controller.future;
                            controller.animateCamera(CameraUpdate.zoomOut());
                          },
                          child: const Icon(Icons.remove, color: Colors.black),
                        ),
                      ],
                    ),
                  ),

                // My Location Button (only show when navigating) - Moved up to avoid SOS button
                if (_isNavigating)
                  Positioned(
                    bottom: widget.isWalkingTogether ? 100 : 70, // Moved up
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _recalibrateLocation,
                      child: const Icon(Icons.my_location, color: Colors.blue),
                    ),
                  ),

                // SOS Button - Always visible
                const Positioned(
                  bottom: 20,
                  right: 20,
                  child: SmartSosButton(),
                ),

                // Arrival Overlay (show when destination is reached)
                if (!_isNavigating) _buildArrivalOverlay(),
              ],
            ),
    );
  }
}
