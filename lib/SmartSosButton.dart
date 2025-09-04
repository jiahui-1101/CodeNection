import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:hello_flutter/GuardianModeScreen.dart';

class SmartSosButton extends StatefulWidget {              //  SOS按钮与扇形菜单 (SmartSosButton Widget) 
  const SmartSosButton({super.key});               

  @override
  State<SmartSosButton> createState() => _SmartSosButtonState();
}

class _SmartSosButtonState extends State<SmartSosButton>
    with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  late AnimationController _animationController; 
  Timer? _autoTimer;
  int _countdown = 5;

  final AudioPlayer _audioPlayer = AudioPlayer(); // 音频播放器

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();       // 销毁播放器
    _animationController.dispose();
    _autoTimer?.cancel();
    super.dispose();
  }

  void _stopAlarm() async {
  await _audioPlayer.stop();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("⏹️ Alarm Stopped"),
      backgroundColor: Colors.green,
    ),
  );
}


  void _handleTap() async {
  if (_isMenuOpen) {
    _toggleMenu();
  } else {
    if (_audioPlayer.state == PlayerState.playing) {
      // 如果正在播放，就停止
      await _audioPlayer.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⏹️ Alarm Sound Stopped!"),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // 否则就播放
      await _audioPlayer.play(AssetSource("music/alarm.mp3"));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔊 Alarm Sound Activated!"),
          duration: Duration(seconds: 3),
        ),
      );
}

    }
  }

  void _toggleMenu() {
    if (!mounted) return;
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });

    if (_isMenuOpen) {
      _startAutoCountdown();
    } else {
      _autoTimer?.cancel();
    }
  }

  void _startAutoCountdown() {
    _countdown = 5;
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown == 0) {
        timer.cancel();
        if (_isMenuOpen) {
          _navigateToGuardian("⚠️ Auto-triggered: Security Threat");
        }
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  void _navigateToGuardian(String message) {
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GuardianModeScreen(
        initialMessage: message,
         audioPlayer: _audioPlayer,  //  pass param audioPlayer
         ),
    ));
    if (_isMenuOpen) {
      _toggleMenu();
    }
  }

@override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20, //sos button 按钮离屏幕底部的距离。号码越大，它就越往上。
      right: 20,   //sos button 离屏幕右边的距离。号码越大，它就越往左。
      // 这个 Container 只是用来define整个 widget 的边界和点击范围bulatan punya hu du
      child: SizedBox(
        width: 210,
        height: 210,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            // 1. 【半圆背景层】
            // 这个背景只在菜单打开时出现
            AnimatedOpacity(
              opacity: _isMenuOpen ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_isMenuOpen,
                child: Container(
                  decoration: BoxDecoration(
                    //color: const Color.red.withOpacity(0.5), //半圆弧度punya colour
                    color: Colors.red.withOpacity(0.4),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(220),
                    ),
                  ),
                ),
              ),
            ),
            
            // 2. 【小图标层】
            // 这些小图标也只在shan xing menu open shi appear
            ..._buildFanMenuItems(),
            
            // 3. 【主按钮层】sos button 
            // always appear, even if the menu is closed
            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onLongPress: _toggleMenu,
                onTap: _handleTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 100,  //sos button de size
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isMenuOpen ? Icons.close : Icons.sos,
                          color: Colors.white,
                          size: 40,
                        ),
                        if (_isMenuOpen)
                          Text(
                            "$_countdown",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  List<Widget> _buildFanMenuItems() {
    final List<Map<String, dynamic>> items = [
      {'angle': 0.0, 'color': Colors.blue, 'icon': Icons.local_hospital, 'message': "🚑 Medical Alert Sent"},
      {'angle': 45.0, 'color': Colors.orange, 'icon': Icons.security, 'message': "🛡️ Security Threat Sent"},
      {'angle': 90.0, 'color': Colors.red.shade700, 'icon': Icons.fireplace_rounded, 'message': "🔥 Fire/Hazard Alert Sent"},
    ];

    const double mainButtonRadius = 100 / 2;
    const double iconRadius = 55 / 2;
    const double distance = 95.0;

    return items.map((item) {
      final double angle = item['angle'];
      final double rad = angle * (math.pi / 180.0);

      // 计算图标打开时的位置 (相对于 Stack 的右下角)
      final double openRight = mainButtonRadius - iconRadius + (distance * math.cos(rad));
      final double openBottom = mainButtonRadius - iconRadius + (distance * math.sin(rad));
      
      // 图标关闭时的位置 (藏在主按钮中心)
      final double closedRight = mainButtonRadius - iconRadius;
      final double closedBottom = mainButtonRadius - iconRadius;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        right: _isMenuOpen ? openRight : closedRight,
        bottom: _isMenuOpen ? openBottom : closedBottom,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isMenuOpen ? 1.0 : 0.0,
          child: InkWell(
            onTap: () {
              // 【调试工具2】保留这个 print，确认点击是否触发
             // print("NEW_APPROACH_SUCCESS: Tapped ${item['message']}");
              _navigateToGuardian(item['message']!);
            },
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item['color'],
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)],
              ),
              child: Icon(item['icon'], color: Colors.white),
            ),
          ),
        ),
      );
    }).toList();
  }
}
