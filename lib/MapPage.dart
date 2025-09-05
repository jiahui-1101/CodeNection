import 'package:flutter/material.dart';
import 'loading_page.dart';
import 'pair_result_page.dart';
import 'navigation_page.dart'; // Add this import
import 'LocationSelectionPage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String? currentLocation;
  String? destination;
  bool journeyStarted = false;

  // For map and route
  GoogleMapController? _mapController;
  LatLng? sourceLatLng;
  LatLng? destinationLatLng;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  final String googleApiKey = "AIzaSyALfVigfIlFFmcVIEy-5OGos42GViiQe-M";

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _calculateRoute() async {
    if (sourceLatLng == null || destinationLatLng == null) return;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?'
      'origin=${sourceLatLng!.latitude},${sourceLatLng!.longitude}&'
      'destination=${destinationLatLng!.latitude},${destinationLatLng!.longitude}&'
      'key=$googleApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final points = data['routes'][0]['overview_polyline']['points'];
          final List<LatLng> routeCoordinates = _decodePolyline(points);

          setState(() {
            markers = {
              Marker(
                markerId: const MarkerId('source'),
                position: sourceLatLng!,
                infoWindow: InfoWindow(
                  title: currentLocation ?? 'Current Location',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
              ),
              Marker(
                markerId: const MarkerId('destination'),
                position: destinationLatLng!,
                infoWindow: InfoWindow(title: destination ?? 'Destination'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            };

            polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: routeCoordinates,
                color: Colors.blue,
                width: 5,
              ),
            };
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(
              _boundsFromLatLngList([sourceLatLng!, destinationLatLng!]),
              100,
            ),
          );
        }
      }
    } catch (e) {
      print('Route calculation error: $e');
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> points) {
    double? west, north, east, south;
    for (LatLng point in points) {
      west = west != null
          ? (west < point.longitude ? west : point.longitude)
          : point.longitude;
      north = north != null
          ? (north > point.latitude ? north : point.latitude)
          : point.latitude;
      east = east != null
          ? (east > point.longitude ? east : point.longitude)
          : point.longitude;
      south = south != null
          ? (south < point.latitude ? south : point.latitude)
          : point.latitude;
    }
    return LatLngBounds(
      southwest: LatLng(south!, west!),
      northeast: LatLng(north!, east!),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
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

  void _startWalkAlone() {
    // Navigate directly to NavigationPage for walking alone
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationPage(
          currentLocation: currentLocation!,
          destination: destination!,
          isWalkingTogether: false,
        ),
      ),
    );
  }

  void _startMatching() async {
    // Navigate to loading page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoadingPage(
          currentLocation: currentLocation!,
          destination: destination!,
        ),
      ),
    );

    // Handle result from matching
    if (result != null && result is Map<String, dynamic>) {
      if (result['isMatched']) {
        // Matched - navigate to pair result page
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PairResultPage(
              currentLocation: currentLocation!,
              destination: destination!,
              matchedPartners: result['matchedPartners'],
              onStartJourney: () {
                // Navigate to NavigationPage with matched partners
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NavigationPage(
                      currentLocation: currentLocation!,
                      destination: destination!,
                      isWalkingTogether: true,
                      matchedPartners: result['matchedPartners'],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        // Not matched - start walking alone
        _startWalkAlone();
      }
    }
  }

  void _selectLocations() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LocationSelectionPage(initialCurrentLocation: currentLocation),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        if (result['current'] != null) {
          currentLocation = result['current'];
        }
        destination = result['destination'];
      });

      final sourceCoords = currentLocation != null
          ? await _getLatLngFromAddress(currentLocation!)
          : sourceLatLng;
      final destCoords = await _getLatLngFromAddress(destination!);

      if (sourceCoords != null && destCoords != null) {
        setState(() {
          sourceLatLng = sourceCoords;
          destinationLatLng = destCoords;
        });
        await _calculateRoute();
      }
    }
  }

  Future<LatLng?> _getLatLngFromAddress(String address) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$googleApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
      return null;
    } catch (e) {
      print('Geocoding error: $e');
      return null;
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
              zoom: 12,
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

          Positioned(
            bottom:
                160, // 👈 place above bottom widgets (like Start Journey button or SOS)
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
                      onPressed: _calculateRoute,
                      tooltip: "Recalculate route",
                    ),
                ],
              ),
            ),
          ),

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
            onPressed:
                _startWalkAlone, // Updated to call _startWalkAlone directly
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
            onPressed:
                _startMatching, // Updated to call _startMatching directly
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
