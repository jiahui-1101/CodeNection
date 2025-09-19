// 文件名: GuardianModeScreen.dart (完整修正版)

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  final pinController = TextEditingController();
  final String safePin = "0000";
  final String duressPin = "1234";

  // late String guardId; // 不再需要，因为服务不再依赖它
  bool _isDuressExit = false;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    // --- 核心修改在这里 ---

    // 1. 位置共享服务现在更新的是 alert 文档，而不是 guard 文档
    _locationService = LocationService(widget.alertId, isAlert: true); // 👈 传递 alertId
    _locationService.startSharingLocation();

    // 2. 录音服务现在把录音上传到 alert 的子集合里
    _audioRecorder = AudioRecorderService(widget.alertId, isAlert: true); // 👈 传递 alertId
    _audioRecorder.initRecorder().then((_) => _audioRecorder.startRecording());

    // 3. 不再需要监听 guard 文档，因为地图上只需要用户的位置
    //    如果需要同时显示 guard 位置，需要另外的 LocationService 实例来更新 guard 文档
    
    // 监听用户位置（现在由 LocationService 实时更新）
    FirebaseFirestore.instance
        .collection('alerts')
        .doc(widget.alertId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['latitude'] != null && data['longitude'] != null) {
          final LatLng userLocation = LatLng(data['latitude'], data['longitude']);
          if (mounted) {
            setState(() {
              _markers.clear(); // 每次都清理标记，避免重复
              _markers.add(Marker(
                markerId: const MarkerId('user_location'),
                position: userLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(
                    title: data['status'] == 'pending' || data['duress'] == true
                        ? "Active Emergency"
                        : "Ended"),
              ));
              _mapController?.animateCamera(CameraUpdate.newLatLng(userLocation));
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    pinController.dispose();
    
    if (!_isDuressExit) {
      _audioRecorder.stopAndUpload();
      _audioRecorder.dispose();
      _locationService.stopSharingLocation();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build 方法没有变化，所以省略...
    // 你可以保留你原来的 build 方法
    return Scaffold(
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
                          fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text("Help is on the way...",
                      style: TextStyle(fontSize: 18, color: Colors.white70)),
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
                          onMapCreated: (c) => _mapController = c,
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
                onPressed: () async {
                  final result = await showDeactivationDialog(
                    context,
                    pinController,
                    safePin,
                    duressPin,
                    widget.audioPlayer,
                    alertId: widget.alertId,
                    onDeactivate: () async =>
                        await _locationService.stopSharingLocation(),
                  );

                  if (result == 'safe') {
                    if (mounted) Navigator.of(context).pop();
                  } else if (result == 'duress') {
                    setState(() {
                      _isDuressExit = true;
                    });
                    if (mounted) Navigator.of(context).pop();
                  }
                },
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
        onPressed: () => showSafetyManualDialog(context, widget.initialMessage),
        backgroundColor: Colors.white,
        foregroundColor: Colors.red.shade900,
        child: const Icon(Icons.menu_book),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}