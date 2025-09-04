import 'package:flutter/material.dart';
import 'dart:async'; // 用于 Timer
import 'package:hello_flutter/GuardianModeScreen.dart'; // GuardianModeScreen 在这里
import 'package:audioplayers/audioplayers.dart';

//floating sos button when enter full live feed page ,always dekat right top section
class SosAppBarButton extends StatefulWidget {
  const SosAppBarButton({super.key});

  @override
  State<SosAppBarButton> createState() => _SosAppBarButtonState();
}

class _SosAppBarButtonState extends State<SosAppBarButton> {
  final AudioPlayer audioPlayer = AudioPlayer();
  Timer? _longPressTimer;
  int _countdown = 0; // 倒计时显示

  void _startLongPress(BuildContext context) {
    setState(() {
      _countdown = 3; // 初始化倒计时
    });

    _longPressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 1) {
        timer.cancel();
        setState(() => _countdown = 0);

        

        // 跳转 GuardianModeScreen
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GuardianModeScreen(
            initialMessage: "🚨 SOS Long Press Triggered: Guardian Mode Activated!",
          audioPlayer: audioPlayer,
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
    setState(() => _countdown = 0);
  }

  void _triggerAlarm(BuildContext context) async {
    if (audioPlayer.state == PlayerState.playing) {
      // 如果正在播放，就停止
      await audioPlayer.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⏹️ Alarm Sound Stopped!"),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // 否则就播放
      await audioPlayer.play(AssetSource("music/alarm.mp3"));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔊 Alarm Sound Activated!"),
          duration: Duration(seconds: 3),
        ),
      );
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
      onTap: () => _triggerAlarm(context), // 单击触发警报
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
