import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  // Temporary placeholder for guard's location. In real app, this would come from backend.
  // Using UTM's approximate location as a placeholder.
  final LatLng _initialGuardLocation = const LatLng(1.5583, 103.6375); // Example: UTM Skudai Campus
  final Set<Marker> _markers = {}; // To store the guard's marker

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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: Colors.green,
                    content: Text("✅ Alert genuinely cancelled.")));
              } else if (enteredPin == duressPin) {
                widget.audioPlayer.stop();  
                Navigator.of(context).pop(); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: Colors.orange,
                    content: Text("✅ Alert *appears* cancelled. Security has been notified of duress.")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text("❌ Incorrect PIN.")));
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

//  _BlinkingIcon to accept iconSize
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
    )..repeat(reverse: true); // Repeat the animation indefinitely
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