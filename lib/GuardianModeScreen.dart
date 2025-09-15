import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hello_flutter/BlinkingIcon.dart';
import 'package:hello_flutter/AlertDeactivation.dart'; 
import 'package:hello_flutter/GuardianModeSafetyManual.dart'; 


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
  final LatLng _initialGuardLocation = const LatLng(1.5583, 103.6375); // Example: UTM Skudai Campus
  final Set<Marker> _markers = {};

  final pinController = TextEditingController();
  final String safePin = "0000";
  final String duressPin = "1234";

  @override
  void initState() {
    super.initState();
    _markers.add(
      Marker(
        markerId: const MarkerId('guard_location'),
        position: _initialGuardLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Blue marker for guard
        infoWindow: const InfoWindow(title: 'Guard Location (Mock)'),
      ),
    );
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
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
                    const BlinkingIcon(iconSize: 30), // ✅ Changed to use the imported widget
                    const SizedBox(height: 8),
                    const Text(
                      "Recording in progress",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _initialGuardLocation,
                            zoom: 15,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                          markers: _markers,
                          myLocationEnabled: false,
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
                onPressed: () => showDeactivationDialog( // ✅ Changed to use the imported function
                  context,
                  pinController,
                  safePin,
                  duressPin,
                  widget.audioPlayer,
                ),
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

      floatingActionButton: FloatingActionButton(
        onPressed: () => showSafetyManualDialog(context, widget.initialMessage), // ✅ Changed to use the imported function
        backgroundColor: Colors.white,
        foregroundColor: Colors.red.shade900,
        child: const Icon(Icons.menu_book),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}