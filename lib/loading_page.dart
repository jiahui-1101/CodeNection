// loading_page.dart
import 'package:flutter/material.dart';
import 'dart:async';

class LoadingPage extends StatefulWidget {
  final String currentLocation;
  final String destination;

  const LoadingPage({
    super.key,
    required this.currentLocation,
    required this.destination,
  });

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  bool _isMatching = true;
  int _progress = 0;
  final List<String> _searchingMessages = [
    "Searching nearby users...",
    "Analyzing walking routes...",
    "Matching similar destinations...",
    "Finding compatible walking partners...",
    "Almost there..."
  ];
  int _currentMessageIndex = 0;
  
  // 添加 Timer 变量
  Timer? _progressTimer;
  Timer? _messageTimer;
  Timer? _matchingTimer;

  @override
  void initState() {
    super.initState();
    _startMatching();
    _startProgressAnimation();
    _startMessageRotation();
  }

  void _startProgressAnimation() {
    const duration = Duration(milliseconds: 50);
    _progressTimer = Timer.periodic(duration, (timer) {
      if (_progress < 100) {
        setState(() {
          _progress += 2;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startMessageRotation() {
    const duration = Duration(seconds: 2);
    _messageTimer = Timer.periodic(duration, (timer) {
      if (_isMatching && mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _searchingMessages.length;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _startMatching() async {
    // 使用 Timer 而不是 Future.delayed 以便可以取消
    _matchingTimer = Timer(const Duration(seconds: 5), () async {
      if (!mounted) return;
      
      // Simulate matching result (50% chance of match)
      final bool isMatched = DateTime.now().millisecond % 2 == 0;

      if (mounted) {
        setState(() {
          _isMatching = false;
          _progress = 100;
        });
      }

      // Wait a bit before returning result
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pop(isMatched);
      }
    });
  }

  @override
  void dispose() {
    // 取消所有 Timer
    _progressTimer?.cancel();
    _messageTimer?.cancel();
    _matchingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated walking icon
                _buildWalkingAnimation(),
                
                const SizedBox(height: 40),
                
                // Progress indicator
                _buildProgressIndicator(),
                
                const SizedBox(height: 30),
                
                // Searching message
                _buildSearchingMessage(),
                
                const SizedBox(height: 20),
                
                // Route info
                _buildRouteInfo(),
                
                const SizedBox(height: 30),
                
                // Cancel button
                if (_isMatching) _buildCancelButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalkingAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade100,
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_walk,
            size: 50,
            color: Colors.blue,
          ),
        ),
        if (_isMatching)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Text(
          '$_progress%',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: _progress / 100,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
          borderRadius: BorderRadius.circular(10),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          _isMatching ? 'Searching...' : 'Complete!',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchingMessage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        _searchingMessages[_currentMessageIndex],
        key: ValueKey(_currentMessageIndex),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLocationRow(Icons.location_on, Colors.blue, widget.currentLocation),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildLocationRow(Icons.flag, Colors.red, widget.destination),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: () {
        // 取消所有 Timer
        _progressTimer?.cancel();
        _messageTimer?.cancel();
        _matchingTimer?.cancel();
        Navigator.pop(context, false);
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey,
      ),
      child: const Text(
        'Cancel Search',
        style: TextStyle(fontSize: 14),
      ),
    );
  }
}