import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hello_flutter/features/sos_alert/user_view/SmartSosButton.dart';
import 'package:hello_flutter/features/map/individual/SafetyCompanionBottomSheet.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NavigationPage extends StatefulWidget {
  final String currentLocation;
  final String destination;
  final bool isWalkingTogether;
  final List<Map<String, dynamic>>? matchedPartners;
  final LatLng? destinationLatLng;
  final VoidCallback onStartJourney;
  final VoidCallback onEndJourney;

  const NavigationPage({
    super.key,
    required this.currentLocation,
    required this.destination,
    required this.onStartJourney,
    this.destinationLatLng,
    this.isWalkingTogether = false,
    this.matchedPartners,
    required this.onEndJourney,
  });

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final Completer<GoogleMapController> _controller = Completer();
  late String serverApiKey;
  double _currentHeading = 0.0;
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _isUpdatingCamera = false;
  bool _shouldAutoRecalibrate = true;
  Timer? _autoRecalibrateTimer;

  LatLng? _currentPosition;
  LatLng? _destinationLatLng;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Timer? _locationTimer;
  Timer? _routeCheckTimer;

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
  final FlutterTts _flutterTts = FlutterTts();

  // Navigation following variables
  double? _userHeading;
  bool _isFollowingUser = true;
  bool _userInteractedWithMap = false;
  List<LatLng> _routeCoordinates = [];
  List<Map<String, dynamic>> _routeSteps = [];
  int _currentStepIndex = 0;
  double _distanceToNextManeuver = 0;

  @override
  void initState() {
    super.initState();
    serverApiKey = dotenv.get('GOOGLE_MAPS_API_KEY');
    _initializeNavigation(); // 初始化导航逻辑
    _startCompassUpdates(); // 开始指南针监听
    _initializeTts(); // 初始化语音
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _routeCheckTimer?.cancel();
    _compassSubscription?.cancel();
    _safetyAudioPlayer.dispose();
    _flutterTts.stop();
    _compassSubscription?.cancel();
    _autoRecalibrateTimer?.cancel();
    super.dispose();
  }

  void _initializeTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      print("TTS initialization error: $e");
    }
  }

  void _speakInstruction(String instruction) async {
    if (_isNavigating) {
      try {
        await _flutterTts.speak(instruction);
      } catch (e) {
        print("TTS error: $e");
      }
    }
  }

  void _toggleSafetyCompanion() {
    if (!widget.isWalkingTogether) {
      setState(() {
        _showSafetyCompanion = !_showSafetyCompanion;
      });
    }
  }

  void _startCompassUpdates() {
    _compassSubscription = FlutterCompass.events?.listen(
      (event) {
        if (event.heading != null) {
          setState(() {
            _currentHeading = event.heading ?? 0.0;
            _userHeading = event.heading;
          });

          // 只有在跟随模式开启时更新地图方向
          if (_isFollowingUser &&
              _controller.isCompleted &&
              _currentPosition != null) {
            _updateCameraPosition();
          }
        }
      },
      onError: (e) {
        print("Compass error: $e");
      },
    );
  }

  Future<void> _updateCameraPosition() async {
    if (_currentPosition == null || _isUpdatingCamera) return;

    _isUpdatingCamera = true;

    try {
      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 18,
            tilt: 30,
            bearing: _currentHeading,
          ),
        ),
      );
    } catch (e) {
      print("Camera update error: $e");
    } finally {
      _isUpdatingCamera = false;
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

        // Update camera to follow user with proper bearing
        if (_isFollowingUser) {
          _updateCameraPosition();
        }

        // Check for route deviation on every location update
        _checkRouteDeviation();

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

    try {
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
        _routeCoordinates = _decodePolyline(points);

        // Extract steps from the route
        final legs = data['routes'][0]['legs'][0];
        _routeSteps = List<Map<String, dynamic>>.from(legs['steps']);

        // Calculate distance to next maneuver
        _distanceToNextManeuver = _routeSteps.isNotEmpty
            ? _routeSteps[0]['distance']['value'] / 1000
            : 0;

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
              points: _routeCoordinates,
              color: Colors.blue,
              width: 6,
            ),
          };

          _distanceRemaining = legs['distance']['value'] / 1000;
          _timeRemaining = legs['duration']['value'] / 60;

          // Get the first instruction
          if (_routeSteps.isNotEmpty) {
            _nextInstruction = _getInstructionFromStep(_routeSteps[0]);
            _currentStepIndex = 0;
            _speakInstruction(_nextInstruction);
          }
        });
      } else {
        throw Exception("Failed to calculate route: ${data['status']}");
      }
    } catch (e) {
      print("Route calculation error: $e");
      setState(() {
        _errorMessage = "Failed to calculate route: ${e.toString()}";
      });
    }
  }

  String _getInstructionFromStep(Map<String, dynamic> step) {
    String instruction = step['html_instructions'].toString().replaceAll(
      RegExp(r'<[^>]*>'),
      '',
    );

    // Add distance information
    double distance = step['distance']['value'] / 1000;
    String distanceText = distance < 1
        ? '${(distance * 1000).round()} meters'
        : '${distance.toStringAsFixed(1)} km';

    return "$instruction in $distanceText";
  }

  void _checkRouteDeviation() {
    if (_currentPosition == null || _routeCoordinates.isEmpty) return;

    double minDistance = double.infinity;

    // Find the closest point on the route to the user's current position
    for (final point in _routeCoordinates) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        point.latitude,
        point.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    // If user is more than 30m away from the route, recalculate
    if (minDistance > 30) {
      _calculateRoute();
    } else {
      // Update the next instruction based on current position
      _updateNextInstruction();
    }
  }

  void _updateNextInstruction() {
    if (_currentPosition == null || _routeSteps.isEmpty) return;

    // If we're close to the destination, show arrival message
    final distanceToDestination = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _destinationLatLng!.latitude,
      _destinationLatLng!.longitude,
    );

    if (distanceToDestination < 50) {
      setState(() {
        _nextInstruction = "You have arrived at your destination!";
        _isNavigating = false;
      });
      _locationTimer?.cancel();
      _routeCheckTimer?.cancel();
      _speakInstruction("You have arrived at your destination");
      return;
    }

    // Find the current step based on user's position
    int closestStepIndex = _currentStepIndex;
    double minDistance = double.infinity;

    for (int i = 0; i < _routeSteps.length; i++) {
      final step = _routeSteps[i];
      final stepLocation = LatLng(
        step['start_location']['lat'],
        step['start_location']['lng'],
      );

      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        stepLocation.latitude,
        stepLocation.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestStepIndex = i;
      }
    }

    // Update current step if we've moved to a new one
    if (closestStepIndex != _currentStepIndex) {
      setState(() {
        _currentStepIndex = closestStepIndex;
        _nextInstruction = _getInstructionFromStep(
          _routeSteps[_currentStepIndex],
        );
        _distanceToNextManeuver =
            _routeSteps[_currentStepIndex]['distance']['value'] / 1000;
      });
      _speakInstruction(_nextInstruction);
    }

    if (_isFollowingUser) {
      _updateCameraPosition();
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
        _routeCheckTimer?.cancel();
        _speakInstruction("You have arrived at your destination");
      }
    });
  }

  // 在位置更新监听器中添加相机跟随逻辑
  void _startLocationUpdates() {
    _locationTimer?.cancel();

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      final newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = newPosition;
        _markers.removeWhere((m) => m.markerId.value == 'current');
        _markers.add(
          Marker(
            markerId: const MarkerId('current'),
            position: newPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
        );
      });

      // 自动重新校准逻辑
      if (_shouldAutoRecalibrate && _isFollowingUser) {
        _updateCameraPosition();
      }

      _checkRouteDeviation();
      _updateNavigationInfo();
    });
  }

  // 修改重新校准位置方法
  void _recalibrateLocation() async {
    try {
      await _getCurrentLocationWithRetry();
      // 强制地图跟随用户位置
      if (_controller.isCompleted && _currentPosition != null) {
        setState(() {
          _isFollowingUser = true;
          _userInteractedWithMap = false;
        });
        _updateCameraPosition();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to recalibrate: $e")));
    }
  }

  // 修改切换跟随模式方法
  void _toggleFollowMode() async {
    setState(() {
      _isFollowingUser = !_isFollowingUser;
      _userInteractedWithMap = false;
    });

    if (_isFollowingUser && _currentPosition != null) {
      // 立即更新相机位置到当前位置
      _updateCameraPosition();

      // 设置定时器，在切换回跟随模式后的一段时间内保持自动重新校准
      _autoRecalibrateTimer?.cancel();
      _autoRecalibrateTimer = Timer(const Duration(seconds: 30), () {
        setState(() {
          _shouldAutoRecalibrate = true;
        });
      });
    } else {
      // 当用户手动关闭跟随时，暂停自动重新校准
      setState(() {
        _shouldAutoRecalibrate = false;
      });
    }
  }

  void _endNavigation() {
    _locationTimer?.cancel();
    _routeCheckTimer?.cancel();
    _flutterTts.stop();

    // Call the callback to reset the MapPage state
    widget.onEndJourney();

    // Then navigate back
    Navigator.pop(context);
  }

  Widget _buildNavigationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.navigation, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.destination,
                    style: const TextStyle(
                      fontSize: 14,
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
            padding: const EdgeInsets.all(12),
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
                const SizedBox(height: 12),

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
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            _getInstructionIcon(_nextInstruction, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _nextInstruction,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getInstructionIcon(String instruction, {double size = 18}) {
    if (instruction.toLowerCase().contains('turn left')) {
      return Icon(Icons.turn_left, color: Colors.blue, size: size);
    } else if (instruction.toLowerCase().contains('turn right')) {
      return Icon(Icons.turn_right, color: Colors.blue, size: size);
    } else if (instruction.toLowerCase().contains('continue') ||
        instruction.toLowerCase().contains('head')) {
      return Icon(Icons.straight, color: Colors.blue, size: size);
    } else if (instruction.toLowerCase().contains('uturn') ||
        instruction.toLowerCase().contains('u-turn')) {
      return Transform.rotate(
        angle: math.pi,
        child: Icon(Icons.u_turn_left, color: Colors.blue, size: size),
      );
    } else if (instruction.toLowerCase().contains('arrived')) {
      return Icon(Icons.flag, color: Colors.green, size: size);
    }

    return Icon(Icons.navigation, color: Colors.blue, size: size);
  }

  Widget _buildMetricItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? const LatLng(0, 0),
                    zoom: 19,
                    tilt: 60,
                    bearing: _userHeading ?? 0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) async {
                    _controller.complete(controller);
                    if (_currentPosition != null) {
                      // 设置初始相机位置，使用当前朝向
                      await controller.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: _currentPosition!,
                            zoom: 19,
                            tilt: 60,
                            bearing: _userHeading ?? 0,
                          ),
                        ),
                      );
                    }
                  },
                  onCameraMoveStarted: () {
                    setState(() {
                      _isFollowingUser = false;
                      _userInteractedWithMap = true;
                      _shouldAutoRecalibrate = false; // 用户交互时暂停自动重新校准
                    });

                    // 用户交互后，设置定时器在一段时间后恢复自动重新校准
                    _autoRecalibrateTimer?.cancel();
                    _autoRecalibrateTimer = Timer(
                      const Duration(seconds: 5),
                      () {
                        if (mounted) {
                          setState(() {
                            _shouldAutoRecalibrate = true;
                            _isFollowingUser = true;
                          });
                          _updateCameraPosition();
                        }
                      },
                    );
                  },
                  onCameraMove: (_) {
                    setState(() {
                      _userInteractedWithMap = true;
                      _isFollowingUser = false;
                      _shouldAutoRecalibrate = false; // 用户交互时暂停自动重新校准
                    });

                    // 每次相机移动时重置定时器
                    _autoRecalibrateTimer?.cancel();
                    _autoRecalibrateTimer = Timer(
                      const Duration(seconds: 5),
                      () {
                        if (mounted) {
                          setState(() {
                            _shouldAutoRecalibrate = true;
                            _isFollowingUser = true;
                          });
                          _updateCameraPosition();
                        }
                      },
                    );
                  },
                ),
                if (_isNavigating)
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _toggleFollowMode,
                      child: Icon(
                        Icons.my_location,
                        color: _isFollowingUser ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),

                // Navigation Card (only show when navigating)
                if (_isNavigating)
                  Positioned(
                    top: 0, // 调整位置，避免与顶部横幅重叠
                    left: 0,
                    right: 0,
                    child: _buildNavigationCard(),
                  ),

                // Walking Together Card (only show when navigating and with partners)
                if (widget.isWalkingTogether && _isNavigating)
                  Positioned(
                    bottom: 120,
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
