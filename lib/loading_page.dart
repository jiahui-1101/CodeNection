// loading_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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

class _LoadingPageState extends State<LoadingPage> with SingleTickerProviderStateMixin {
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
  
  // Timer variables
  Timer? _progressTimer;
  Timer? _messageTimer;
  Timer? _matchingTimer;
  
  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _walkingAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    // Create walking animation
    _walkingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animations and timers
    _startMatching();
    _startProgressAnimation();
    _startMessageRotation();
    _animationController.repeat(reverse: true);
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
  _matchingTimer = Timer(const Duration(seconds: 5), () async {
    if (!mounted) return;

    bool isMatched = false;
    List<Map<String, dynamic>> matchedPartners = [];

    try {
      // 🔹 Example: query Firestore for users near the same destination
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('destination', isEqualTo: widget.destination)
          .get();

      if (snapshot.docs.isNotEmpty) {
        isMatched = true;
        matchedPartners = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'name': data['name'] ?? 'Unknown',
            'profileImage': data['profileImage'] ?? '👤',
            'rating': data['rating'] ?? 0,
            'walkingSpeed': data['walkingSpeed'] ?? 'Unknown',
            'matchPercentage': data['matchPercentage'] ?? 0,
            'distance': data['distance'] ?? 'N/A',
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching partners: $e");
    }

    if (mounted) {
      setState(() {
        _isMatching = false;
        _progress = 100;
      });
      _animationController.stop();
    }

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.of(context).pop({
        'isMatched': isMatched,
        'matchedPartners': matchedPartners,
      });
    }
  });
}


  @override
  void dispose() {
    // Cancel all timers
    _progressTimer?.cancel();
    _messageTimer?.cancel();
    _matchingTimer?.cancel();
    
    // Dispose animation controller
    _animationController.dispose();
    
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
                
                // Result indicator (when matching is complete)
                if (!_isMatching) _buildResultIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalkingAnimation() {
    return AnimatedBuilder(
      animation: _walkingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_walkingAnimation.value * 10),
          child: Container(
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.directions_walk,
                  size: 50,
                  color: _isMatching ? Colors.blue : Colors.green,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Text(
          '$_progress%',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _isMatching ? Colors.blue : Colors.green,
          ),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: _progress / 100,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation(
            _isMatching ? Colors.blue.shade400 : Colors.green,
          ),
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
        _isMatching 
          ? _searchingMessages[_currentMessageIndex]
          : "Match found! Preparing your route...",
        key: ValueKey(_currentMessageIndex + (_isMatching ? 0 : 1000)),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _isMatching ? Colors.black87 : Colors.green.shade700,
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
        // Cancel all timers and animations
        _progressTimer?.cancel();
        _messageTimer?.cancel();
        _matchingTimer?.cancel();
        _animationController.stop();
        
        // Return to previous screen with no match
        Navigator.pop(context, {
          'isMatched': false,
          'matchedPartners': [],
        });
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text(
        'Cancel Search',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildResultIndicator() {
    return const Column(
      children: [
        SizedBox(height: 10),
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Colors.green),
          strokeWidth: 2,
        ),
      ],
    );
  }
}