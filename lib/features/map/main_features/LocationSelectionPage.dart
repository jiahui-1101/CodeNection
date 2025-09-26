// location_selection_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationSelectionPage extends StatefulWidget {
  final String? initialCurrentLocation;

  const LocationSelectionPage({super.key, this.initialCurrentLocation});

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  final TextEditingController _currentLocationController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  late String googleApiKey;
  
  List<dynamic> _currentLocationSuggestions = [];
  List<dynamic> _destinationSuggestions = [];
  bool _isGettingLocation = false;
  bool _showCurrentSuggestions = false;
  bool _showDestinationSuggestions = false;

  @override
  void initState() { 
    super.initState();
    googleApiKey = dotenv.get('GOOGLE_NAVIGATION_API_KEY');
    _currentLocationController.text = widget.initialCurrentLocation ?? '';
  }

  // Function to get current location via GPS
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Check location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location services are disabled")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permissions are denied")),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permissions are permanently denied")),
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates (reverse geocoding)
      final address = await _getAddressFromLatLng(
        position.latitude, position.longitude,
      );

      setState(() {
        _currentLocationController.text = address;
      });

    } catch (e) {
      print('Error getting current location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  // Function to get address from coordinates (reverse geocoding)
  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?'
      'latlng=$lat,$lng&'
      'key=$googleApiKey'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
      return "Current Location";
    } catch (e) {
      print('Reverse geocoding error: $e');
      return "Current Location";
    }
  }

  // Function to get place suggestions
  Future<void> _getPlaceSuggestions(String input, bool isCurrentLocation) async {
    if (input.isEmpty) {
      setState(() {
        if (isCurrentLocation) {
          _currentLocationSuggestions = [];
          _showCurrentSuggestions = false;
        } else {
          _destinationSuggestions = [];
          _showDestinationSuggestions = false;
        }
      });
      return;
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
      'input=${Uri.encodeComponent(input)}&'
      'key=$googleApiKey&'
      'components=country:my' // Restrict to Malaysia
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            if (isCurrentLocation) {
              _currentLocationSuggestions = data['predictions'];
              _showCurrentSuggestions = true;
            } else {
              _destinationSuggestions = data['predictions'];
              _showDestinationSuggestions = true;
            }
          });
        }
      }
    } catch (e) {
      print('Places autocomplete error: $e');
    }
  }

  // Function to get place details from place ID
  Future<String> _getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?'
      'placeid=$placeId&'
      'key=$googleApiKey'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result']['formatted_address'];
        }
      }
      return "";
    } catch (e) {
      print('Place details error: $e');
      return "";
    }
  }

  bool get _isFormValid {
    return _currentLocationController.text.isNotEmpty && 
           _destinationController.text.isNotEmpty;
  }

  void _saveLocations() {
    if (_isFormValid) {
      Navigator.pop(context, {
        'current': _currentLocationController.text,
        'destination': _destinationController.text,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in both locations")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Locations"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Current Location Input with GPS button
                  TextField(
                    controller: _currentLocationController,
                    decoration: InputDecoration(
                      labelText: "Current Location",
                      prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                      suffixIcon: _isGettingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.gps_fixed, color: Colors.blue),
                              onPressed: _getCurrentLocation,
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (value) {
                      _getPlaceSuggestions(value, true);
                    },
                    onTap: () {
                      setState(() {
                        _showCurrentSuggestions = true;
                        _showDestinationSuggestions = false;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Destination Input
                  TextField(
                    controller: _destinationController,
                    decoration: InputDecoration(
                      labelText: "Destination",
                      prefixIcon: const Icon(Icons.flag, color: Colors.red),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (value) {
                      _getPlaceSuggestions(value, false);
                    },
                    onTap: () {
                      setState(() {
                        _showCurrentSuggestions = false;
                        _showDestinationSuggestions = true;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Suggestions List
                  Expanded(
                    child: _showCurrentSuggestions && _currentLocationSuggestions.isNotEmpty
                        ? _buildSuggestionsList(_currentLocationSuggestions, true)
                        : _showDestinationSuggestions && _destinationSuggestions.isNotEmpty
                            ? _buildSuggestionsList(_destinationSuggestions, false)
                            : Container(),
                  ),
                ],
              ),
            ),
          ),
          
          // Confirm Button at bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isFormValid ? _saveLocations : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                "Confirm Locations",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(List<dynamic> suggestions, bool isCurrentLocation) {
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final place = suggestions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Icon(
              isCurrentLocation ? Icons.location_on : Icons.place,
              color: isCurrentLocation ? Colors.blue : Colors.red,
            ),
            title: Text(
              place['description'],
              style: const TextStyle(fontSize: 14),
            ),
            onTap: () async {
              final address = await _getPlaceDetails(place['place_id']);
              setState(() {
                if (isCurrentLocation) {
                  _currentLocationController.text = address;
                  _showCurrentSuggestions = false;
                } else {
                  _destinationController.text = address;
                  _showDestinationSuggestions = false;
                }
              });
            },
          ),
        );
      },
    );
  }
}