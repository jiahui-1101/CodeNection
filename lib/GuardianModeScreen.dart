import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// 导入你项目中的其他文件
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
        .listen((doc) {
      if (!mounted || !doc.exists || doc.data() == null) return;

      final data = doc.data()!;
      final status = data['status'];
      
      // ✅ 监听器现在只负责处理 Guard 完成任务的情况
      if (status == 'completed') {
        // 立即停止服务
        _audioRecorder.stopAndUpload();
        _locationService.stopSharingLocation();

        final navContext = context;
        ScaffoldMessenger.of(navContext).showSnackBar(const SnackBar(
          content: Text("Alert has been resolved by the guard."),
          backgroundColor: Colors.green,
        ));
        
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(navContext).pop();
          }
        });
        return;
      }

      // 更新地图标记
      if (data['latitude'] != null && data['longitude'] != null) {
        final LatLng userLocation = LatLng(data['latitude'], data['longitude']);
        setState(() {
          _markers.clear();
          _markers.add(Marker(
            markerId: const MarkerId('user_location'),
            position: userLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
                title: data['duress'] == true
                    ? "Active DURESS"
                    : "Active Emergency"),
          ));
          _mapController?.animateCamera(CameraUpdate.newLatLng(userLocation));
        });
      }
    });
  }

  // ✅ 核心修改：按钮点击事件现在全权负责处理 PIN 码的退出逻辑
  Future<void> _onDeactivatePressed() async {
    final result = await showDeactivationDialog(
      context,
      pinController,
      safePin,
      duressPin,
      widget.audioPlayer,
      alertId: widget.alertId,
      // onDeactivate 仍然需要，因为 dialog 内部不知道要停止哪个 location service 实例
      onDeactivate: () async => await _locationService.stopSharingLocation(),
    );

    if (!mounted) return;

    if (result == 'safe') {
      // ✅ 用户输入了 safe pin，我们在这里直接处理，不再依赖监听器
      // 1. 停止录音服务
      await _audioRecorder.stopAndUpload();

      // 2. 显示提示
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("✅ Alert genuinely cancelled."),
        backgroundColor: Colors.green,
      ));
      
      // 3. 延迟后退出
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.of(context).pop();
      });

    } else if (result == 'duress') {
      // 胁迫模式是特殊情况，需要立即退出，并保持后台服务运行
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
    pinController.dispose();

    if (!_isDuressExit) {
      _audioRecorder.stopAndUpload();
      _locationService.stopSharingLocation();
    }
    _audioRecorder.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build 方法完全不变
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