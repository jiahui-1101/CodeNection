import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'AlertDeactivation.dart';
import 'features/sos_alert/service/location_service.dart';
import 'features/sos_alert/service/audio_recorder_service.dart';
import 'BlinkingIcon.dart';
import 'GuardianModeSafetyManual.dart';

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
  late LocationService _locationService;
  late AudioRecorderService _audioRecorder;
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

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _locationService = LocationService(widget.alertId, isAlert: true);
    _locationService.startSharingLocation();

    _audioRecorder = AudioRecorderService(widget.alertId, isAlert: true);
    _audioRecorder.initRecorder().then((_) => _audioRecorder.startRecording());

    _alertStatusSubscription = FirebaseFirestore.instance
        .collection('alerts')
        .doc(widget.alertId)
        .snapshots()
        .listen((doc) async {
      if (!mounted || !doc.exists || doc.data() == null) return;

      final data = doc.data()!;
      final status = data['status'];

      if (status == 'completed' || status == 'cancelled') {
        _alertStatusSubscription?.cancel();
        _alertStatusSubscription = null;

        await _audioRecorder.stopAndUpload();
        await _locationService.stopSharingLocation();

        if (!mounted) return;

        final navContext = context;
        ScaffoldMessenger.of(navContext).showSnackBar(SnackBar(
          content: Text(status == 'completed'
              ? "Alert has been resolved by the guard."
              : "Alert has been cancelled."),
          backgroundColor: Colors.green,
        ));

        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.of(navContext).pop();
        }
        return;
      }

      if (data['latitude'] != null && data['longitude'] != null) {
        final newUserPosition = LatLng(data['latitude'], data['longitude']);
        if (newUserPosition != _userPosition) {
          setState(() {
            _userPosition = newUserPosition;
            _updateMarkers();
          });
        }
      }

      final guardId = data['guardId'] as String?;
      if (guardId != null && _guardIdOnAlert != guardId) {
        _guardIdOnAlert = guardId;
        _listenToGuardLocation();
      }
    });
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
          final newGuardPosition =
              LatLng(data['latitude'], data['longitude']);
          if (newGuardPosition != _guardPosition) {
            setState(() {
              _guardPosition = newGuardPosition;
              _updateMarkers();
            });
          }
        }
      }
    });
  }

  void _updateMarkers() {
    _markers.clear();
    if (_userPosition != null) {
      _markers.add(Marker(
        markerId: const MarkerId('user_location'),
        position: _userPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "Your Location"),
      ));
    }
    if (_guardPosition != null) {
      _markers.add(Marker(
        markerId: const MarkerId('guard_location'),
        position: _guardPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: "Guard's Location"),
      ));
    }
    _updateCameraBounds();
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
      onDeactivate: () async => await _locationService.stopSharingLocation(),
    );

    if (!mounted) return;

    if (result == 'safe') {
    } else if (result == 'duress') {
      setState(() {
        _isDuressExit = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.orange,
        content: Text("✅ Alert appears cancelled. Security notified of duress."),
      ));
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _alertStatusSubscription?.cancel();
    _guardLocationSubscription?.cancel();
    pinController.dispose();

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
                    Text(widget.initialMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text("Help is on the way...",
                        style:
                            TextStyle(fontSize: 18, color: Colors.white70)),
                  ],
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const BlinkingIcon(iconSize: 30),
                      const SizedBox(height: 8),
                      const Text("Recording in progress",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontStyle: FontStyle.italic)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: GoogleMap(
                            initialCameraPosition: const CameraPosition(
                                target: LatLng(1.5583, 103.6375), zoom: 15),
                            onMapCreated: (c) {
                              if (!_mapControllerCompleter.isCompleted) {
                                _mapControllerCompleter.complete(c);
                              }
                            },
                            markers: _markers,
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
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              showSafetyManualDialog(context, widget.initialMessage),
          backgroundColor: Colors.white,
          foregroundColor: Colors.red.shade900,
          child: const Icon(Icons.menu_book),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}