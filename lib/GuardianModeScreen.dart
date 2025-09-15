import 'dart:async'; 
import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; 

// Make GuardianModeScreen a StatefulWidget
class GuardianModeScreen extends StatefulWidget {
  final String initialMessage;
  final AudioPlayer audioPlayer;

  const GuardianModeScreen({
    super.key,
    required this.initialMessage,
    required this.audioPlayer,
  });

  @override
  State<GuardianModeScreen> createState() => _GuardianModeScreenState();
}

class _GuardianModeScreenState extends State<GuardianModeScreen> {
  GoogleMapController? _mapController;
  LatLng? _userCurrentLocation;
  LatLng? _guardCurrentLocation;
  final Set<Marker> _markers = {}; // To store both user's and guard's markers

  // Subscriptions for location updates
  StreamSubscription<Position>? _userPositionStreamSubscription;
  Timer? _guardMovementTimer; // Timer for simulating guard movement

  // Existing PIN related fields
  final pinController = TextEditingController();
  final String safePin = "0000";
  final String duressPin = "1234";

  @override
  void initState() {
    super.initState();
    _requestLocationPermissionAndStartTracking(); // Start location tracking
  }

  @override
  void dispose() {
    _userPositionStreamSubscription?.cancel(); // Cancel user location stream
    _guardMovementTimer?.cancel(); // Cancel guard movement timer
    pinController.dispose();
    super.dispose();
  }

  // Request location permission and start tracking
  Future<void> _requestLocationPermissionAndStartTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable them.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied. Cannot show your live location.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied. Please enable them from settings.')),
        );
      }
      return;
    }

    // Start user location tracking
    _startUserLocationStream();
  }
  void _startUserLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _userPositionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _userCurrentLocation = LatLng(position.latitude, position.longitude);
          _updateMarkersAndCamera(); // Update map with new user location
          if (_guardCurrentLocation == null) {
            // If guard hasn't started moving, initialize guard near user
            // Start Guard slightly away from the user's initial location
            _guardCurrentLocation = LatLng(
                position.latitude + 0.005, position.longitude + 0.005); // Start Guard approx 700m away
            _startGuardMovementSimulation(); // Start guard simulation once user location is known
          }
        });
      }
    }, onError: (e) {
      print("Error in user location stream: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting your location: $e')),
        );
      }
    });
  }

  void _startGuardMovementSimulation() {
    _guardMovementTimer?.cancel(); // Cancel any existing timer
    _guardMovementTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _userCurrentLocation == null || _guardCurrentLocation == null) {
        timer.cancel(); // Stop timer if widget is unmounted or locations are not available
        return;
      }

      // Calculate the direction vector from guard to user
      double latDiff = _userCurrentLocation!.latitude - _guardCurrentLocation!.latitude;
      double lonDiff = _userCurrentLocation!.longitude - _guardCurrentLocation!.longitude;

      // Calculate distance to stop simulation if guard is very close
      double distance = Geolocator.distanceBetween(
        _userCurrentLocation!.latitude, _userCurrentLocation!.longitude,
        _guardCurrentLocation!.latitude, _guardCurrentLocation!.longitude,
      );

      if (distance < 50) { // If guard is within 50 meters, stop moving
        timer.cancel();
        setState(() {
          _guardCurrentLocation = _userCurrentLocation; // Guard reached user
          _updateMarkersAndCamera();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guard is very close!'), backgroundColor: Colors.blue),
          );
        }
        return;
      }

      // Move the guard a small step towards the user
      const double step = 0.0001; // Smaller step for smoother animation, roughly 11 meters
      double angle = atan2(lonDiff, latDiff); // Angle from guard to user

      setState(() {
        _guardCurrentLocation = LatLng(
          _guardCurrentLocation!.latitude + step * cos(angle),
          _guardCurrentLocation!.longitude + step * sin(angle),
        );
        _updateMarkersAndCamera(); // Update map with new guard location
      });
    });
  }


  void _updateMarkersAndCamera() {
    _markers.clear();
    if (_userCurrentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userCurrentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // Red for user
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }
    if (_guardCurrentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('guard_location'),
          position: _guardCurrentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Blue for guard
          infoWindow: const InfoWindow(title: 'Guard Location'),
        ),
      );
    }

    // Center camera to include both user and guard
    if (_mapController != null && _userCurrentLocation != null && _guardCurrentLocation != null) {
      LatLngBounds bounds = _boundsFromMarkers(_markers);
      // Ensure the bounds are valid before animating camera
      if (bounds.northeast.latitude != bounds.southwest.latitude ||
          bounds.northeast.longitude != bounds.southwest.longitude) {
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100)); // Padding 100
      } else {
        // If only one point, just zoom to that point
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_userCurrentLocation!, 15));
      }
    } else if (_mapController != null && _userCurrentLocation != null) {
      // Only user location available
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_userCurrentLocation!, 15));
    }
  }

  LatLngBounds _boundsFromMarkers(Set<Marker> markers) {
    double? x0, x1, y0, y1;
    for (Marker marker in markers) {
      if (x0 == null || marker.position.latitude < x0) x0 = marker.position.latitude;
      if (x1 == null || marker.position.latitude > x1) x1 = marker.position.latitude;
      if (y0 == null || marker.position.longitude < y0) y0 = marker.position.longitude;
      if (y1 == null || marker.position.longitude > y1) y1 = marker.position.longitude;
    }
    // Return a default bound if no markers, or ensure valid bounds
    if (x0 == null || x1 == null || y0 == null || y1 == null) {
      return LatLngBounds(
        northeast: const LatLng(0, 0),
        southwest: const LatLng(0, 0),
      );
    }
    return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
  }


  // secret code to deactivate alert not genuinely (Moved from StatelessWidget to StatefulWidget's State)
  void _showDeactivationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Enter Deactivation PIN"),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(hintText: "4-digit PIN"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancel")),
          TextButton(
            child: const Text("Confirm"),
            onPressed: () {
              final enteredPin = pinController.text;
              Navigator.of(dialogContext).pop();

              if (enteredPin == safePin) {
                widget.audioPlayer.stop();

                Navigator.of(context).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      backgroundColor: Colors.green,
                      content: Text("✅ Alert genuinely cancelled.")));
                }
              } else if (enteredPin == duressPin) {
                widget.audioPlayer.stop();
                Navigator.of(context).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      backgroundColor: Colors.orange,
                      content: Text("✅ Alert *appears* cancelled. Security has been notified of duress.")));
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text("❌ Incorrect PIN.")));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    widget.initialMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
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
                  
                    _BlinkingIcon(iconSize: 30),
                    const SizedBox(height: 8),
                    const Text(
                      "Recording in progress",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _userCurrentLocation == null
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(color: Colors.white),
                                    SizedBox(height: 10),
                                    Text(
                                      "Getting your location...",
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                              )
                            : GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: _userCurrentLocation!, 
                                  zoom: 15,
                                ),
                                onMapCreated: (GoogleMapController controller) {
                                  _mapController = controller;
                                  _updateMarkersAndCamera(); 
                                },
                                markers: _markers, 
                                myLocationEnabled: true, 
                                zoomControlsEnabled: true,
                                scrollGesturesEnabled: true,
                                compassEnabled: true,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _showDeactivationDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade900,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Deactivate with PIN"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// _BlinkingIcon remains the same as before, no further changes
class _BlinkingIcon extends StatefulWidget {
  final double iconSize;

  const _BlinkingIcon({super.key, this.iconSize = 40});

  @override
  State<_BlinkingIcon> createState() => _BlinkingIconState();
}

class _BlinkingIconState extends State<_BlinkingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Icon(Icons.mic, color: Colors.white, size: widget.iconSize),
    );
  }
}