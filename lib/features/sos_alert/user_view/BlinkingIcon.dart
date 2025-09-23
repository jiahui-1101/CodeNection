import 'package:flutter/material.dart';

class BlinkingIcon extends StatefulWidget {   //GUARDIAN MODE PUNYA BLINKING MIC ICON
  final double iconSize;

  const BlinkingIcon({super.key, this.iconSize = 40});

  @override
  State<BlinkingIcon> createState() => _BlinkingIconState();
}

class _BlinkingIconState extends State<BlinkingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
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