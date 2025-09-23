import 'package:flutter/material.dart';
import '../group/loading_page.dart';
import '../group/pair_result_page.dart';
import 'navigation_page.dart';
import 'LocationSelectionPage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String? currentLocation;
  String? destination;
  bool journeyStarted = false;
  Position? currentPosition;

  GoogleMapController? _mapController;
  LatLng? sourceLatLng;
  LatLng? destinationLatLng;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  // ✅ Use same key as NavigationPage
  final String serverApiKey = "AIzaSyD8v9hGJLHwma7zYUFhpW4WVbNlehYhpGk";
  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Add this line
  }

  // Add this method to get current location
  Future<void> _getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Handle denied permission
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Handle permanently denied permission
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentPosition = position;
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<List<LatLng>> _fetchDirectionsFromApi(
    LatLng origin,
    LatLng destination,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?'
      'origin=${origin.latitude},${origin.longitude}&'
      'destination=${destination.latitude},${destination.longitude}&'
      'key=$serverApiKey',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);
    if (data['status'] != 'OK') {
      throw Exception("Directions API error: ${data['status']}");
    }

    final points = data['routes'][0]['overview_polyline']['points'];
    return _decodePolyline(points);
  }

  Future<void> _getDirections(LatLng origin, LatLng destination) async {
    final routePoints = await _fetchDirectionsFromApi(origin, destination);

    setState(() {
      markers = {
        Marker(markerId: const MarkerId('source'), position: origin),
        Marker(markerId: const MarkerId('destination'), position: destination),
      };
      polylines = {
        Polyline(
          polylineId: const PolylineId("route"),
          color: Colors.blue,
          width: 5,
          points: routePoints,
        ),
      };
    });

    // 👇 Zoom map to fit the route
    if (_mapController != null && routePoints.isNotEmpty) {
      double minLat = routePoints
          .map((p) => p.latitude)
          .reduce((a, b) => a < b ? a : b);
      double maxLat = routePoints
          .map((p) => p.latitude)
          .reduce((a, b) => a > b ? a : b);
      double minLng = routePoints
          .map((p) => p.longitude)
          .reduce((a, b) => a < b ? a : b);
      double maxLng = routePoints
          .map((p) => p.longitude)
          .reduce((a, b) => a > b ? a : b);

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50), // padding 50
      );
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

  Future<LatLng?> _getLatLngFromAddress(String address) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$serverApiKey",
    );
    final response = await http.get(url);
    final data = jsonDecode(response.body);
    if (data['status'] == 'OK') {
      final location = data['results'][0]['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    }
    return null;
  }

  void _startWalkAlone() async {
    if (sourceLatLng != null && destinationLatLng != null) {
      await _getDirections(sourceLatLng!, destinationLatLng!);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationPage(
          currentLocation: currentLocation!, // required
          destination: destination!, // required
          destinationLatLng: destinationLatLng,
          isWalkingTogether: false, // or true depending on mode
          onStartJourney: () {
            // required
            setState(() {
              journeyStarted = true;
            });
          },
          onEndJourney: _resetMapState,
        ),
      ),
    );
  }

  void _resetMapState() {
    setState(() {
      journeyStarted = false;
      markers.clear();
      polylines.clear();
      // Reset any other navigation-related state here
    });
  }

  // ✅ Added: location picker
  void _selectLocations() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationSelectionPage()),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        currentLocation = result['current'];
        destination = result['destination'];
      });

      sourceLatLng = await _getLatLngFromAddress(currentLocation!);
      destinationLatLng = await _getLatLngFromAddress(destination!);

      if (sourceLatLng != null && destinationLatLng != null) {
        await _getDirections(sourceLatLng!, destinationLatLng!);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                sourceLatLng!.latitude <= destinationLatLng!.latitude
                    ? sourceLatLng!.latitude
                    : destinationLatLng!.latitude,
                sourceLatLng!.longitude <= destinationLatLng!.longitude
                    ? sourceLatLng!.longitude
                    : destinationLatLng!.longitude,
              ),
              northeast: LatLng(
                sourceLatLng!.latitude >= destinationLatLng!.latitude
                    ? sourceLatLng!.latitude
                    : destinationLatLng!.latitude,
                sourceLatLng!.longitude >= destinationLatLng!.longitude
                    ? sourceLatLng!.longitude
                    : destinationLatLng!.longitude,
              ),
            ),
            50,
          ),
        );
      }
    }
  }

  // ✅ Added: matching logic
  // ✅ Matching flow: goes to LoadingPage first
  void _startMatching() async {
    if (currentLocation == null || destination == null) return;

    // Ensure we have current position
    if (currentPosition == null) {
      await _getCurrentLocation();
    }

    if (currentPosition == null) {
      // Show error if we still can't get position
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot get current location")),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoadingPage(
          currentLocation: currentLocation!,
          destination: destination!,
          currentPosition: currentPosition!, // Now this should work
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final bool isMatched = result['isMatched'] ?? false;
      final matchedPartners = result['matchedPartners'] ?? [];

      if (!mounted) return;

      // If matched → show PairResultPage
      if (isMatched) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PairResultPage(
              currentLocation: currentLocation!,
              destination: destination!,
              matchedPartners: matchedPartners,
              onStartJourney: () {
                setState(() {
                  journeyStarted = true;
                });
              },
              onEndJourney: _resetMapState, 
            ),
          ),
        );
      } else {
        // If no match → just walk alone
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NavigationPage(
              currentLocation: currentLocation!,
              destination: destination!,
              destinationLatLng: destinationLatLng,
              isWalkingTogether: false,
              onStartJourney: () {
                setState(() {
                  journeyStarted = true;
                });
              },
              onEndJourney: _resetMapState,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(1.5590, 103.6370),
              zoom: 16,
            ),
            markers: markers,
            polylines: polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // Zoom buttons
          Positioned(
            bottom: 160,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: "zoom_in",
                  onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomIn());
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: "zoom_out",
                  onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomOut());
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Search bar
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectLocations,
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              destination == null
                                  ? "Choose your destination"
                                  : "${currentLocation ?? 'Current Location'} ➝ $destination",
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (destination != null)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.blue),
                      onPressed: () {
                        if (sourceLatLng != null && destinationLatLng != null) {
                          _getDirections(sourceLatLng!, destinationLatLng!);
                        }
                      },
                      tooltip: "Recalculate route",
                    ),
                ],
              ),
            ),
          ),

          // Start journey button
          if (destination != null && !journeyStarted)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => _buildJourneyOptions(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    "Start Journey",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJourneyOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: _startWalkAlone,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.green,
            ),
            child: const Text(
              "🚶 Walk Alone (Start Now)",
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _startMatching,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.orange,
            ),
            child: const Text(
              "🤝 Let's WALK Mode",
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
