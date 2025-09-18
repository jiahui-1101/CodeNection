// 文件名: SosAppBarButton.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hello_flutter/GuardianModeScreen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; // ✅ 1. 添加 geolocator 的 import

class SosAppBarButton extends StatefulWidget {
  const SosAppBarButton({super.key});

  @override
  State<SosAppBarButton> createState() => _SosAppBarButtonState();
}

class _SosAppBarButtonState extends State<SosAppBarButton> {
  final AudioPlayer audioPlayer = AudioPlayer();
  Timer? _longPressTimer;
  int _countdown = 0;

  void _startLongPress(BuildContext context) {
    setState(() {
      _countdown = 3; // 初始化倒计时
    });

    _longPressTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdown == 1) {
        timer.cancel();
        setState(() => _countdown = 0);

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          // ... (用户未登录的逻辑不变)
          return;
        }

        final duressQuery = await FirebaseFirestore.instance
            .collection('alerts')
            .where('userId', isEqualTo: currentUser.uid)
            .where('duress', isEqualTo: true)
            .limit(1)
            .get();

        if (duressQuery.docs.isNotEmpty) {
           // ... (duress 检查逻辑不变)
          return;
        }

        // ✅ 2. 新增：获取当前地理位置
        Position? position;
        try {
          // 在实际项目中需要处理好权限请求
          position = await Geolocator.getCurrentPosition();
        } catch (e) {
          print("Failed to get location: $e");
          // 即使获取位置失败，也继续发送警报，只是没有位置信息
        }

        // ✅ 3. 修改：在创建 alert 时，把位置信息加进去
        final docRef = await FirebaseFirestore.instance.collection('alerts').add({
          'status': 'pending',
          'type': 'security',
          'timestamp': FieldValue.serverTimestamp(),
          'userId': currentUser.uid,
          'title': "SOS Long Press Triggered",
          'latitude': position?.latitude,   // <--- 把纬度加上
          'longitude': position?.longitude, // <--- 把经度加上
        });
        final alertId = docRef.id;

        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GuardianModeScreen(
            initialMessage: "🚨 SOS Long Press Triggered: Guardian Mode Activated!",
            audioPlayer: audioPlayer,
            alertId: alertId,
          ),
        ));
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  void _endLongPress() {
    _longPressTimer?.cancel();
    if (mounted) {
      setState(() => _countdown = 0);
    }
  }

  void _triggerAlarm(BuildContext context) async {
    if (audioPlayer.state == PlayerState.playing) {
      await audioPlayer.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⏹️ Alarm Sound Stopped!"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await audioPlayer.play(AssetSource("music/alarm.mp3"));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🔊 Alarm Sound Activated!"),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _triggerAlarm(context),
      onLongPressStart: (_) => _startLongPress(context),
      onLongPressEnd: (_) => _endLongPress(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: _countdown > 0
              ? Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.sos_rounded,
                  color: Colors.white,
                  size: 32,
                ),
        ),
      ),
    );
  }
}