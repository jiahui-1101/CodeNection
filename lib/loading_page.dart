// loading_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LoadingPage extends StatefulWidget {
  final String currentLocation;
  final String destination;
  final Position currentPosition;

  const LoadingPage({
    super.key,
    required this.currentLocation,
    required this.destination,
    required this.currentPosition,
  });

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  bool _isMatching = true;
  bool _matchSuccess = false;
  double _progress = 0;
  final List<String> _searchingMessages = [
    "Searching nearby users...",
    "Analyzing walking routes...",
    "Matching similar destinations...",
    "Finding compatible walking partners...",
    "Almost there...",
  ];
  int _currentMessageIndex = 0;
  String? _errorMessage;

  Timer? _progressTimer;
  Timer? _messageTimer;
  Timer? _matchingTimer;

  late AnimationController _animationController;
  late Animation<double> _walkingAnimation;

  String? _currentUserDocId;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track start time for accurate progress calculation
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _walkingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeMatchingProcess();
  }

  Future<void> _initializeMatchingProcess() async {
    try {
      await _saveUserToFirestore();
      _startMatching();
      _startProgressAnimation();
      _startMessageRotation();
      _animationController.repeat(reverse: true);
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to start matching process: $e";
        _isMatching = false;
        _matchSuccess = false;
      });
      _animationController.stop();
    }
  }

  /// 🔹 Save current user search info into Firestore with status field
  Future<void> _saveUserToFirestore() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception("No user logged in");
      }

      final docRef = await _firestore.collection('users').add({
        "uid": user.uid,
        "email": user.email,
        "destination": widget.destination,
        "currentLocation": widget.currentLocation,
        "latitude": widget.currentPosition.latitude,
        "longitude": widget.currentPosition.longitude,
        "status": "searching", // Add status field
        "createdAt": FieldValue.serverTimestamp(),
      });

      _currentUserDocId = docRef.id;
      debugPrint("✅ User saved with id ${docRef.id}");
    } catch (e) {
      debugPrint("❌ Error saving user: $e");
      rethrow;
    }
  }

  void _startProgressAnimation() {
    _startTime = DateTime.now();
    const duration = Duration(milliseconds: 100);
    _progressTimer = Timer.periodic(duration, (timer) {
      if (_isMatching && _startTime != null) {
        final elapsed = DateTime.now().difference(_startTime!).inMilliseconds;
        final progressPercent = (elapsed / 5000 * 100).clamp(0, 100).toDouble();

        setState(() {
          _progress = progressPercent;
        });
        if (progressPercent >= 100) {
          timer.cancel();
        }
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
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _searchingMessages.length;
        });
      } else {
        timer.cancel();
      }
    });
  }

  // Calculate distance between two coordinates in meters
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // 在 _startMatching 方法中修改时间窗口和匹配逻辑
  Future<void> _startMatching() async {
    _matchingTimer = Timer(const Duration(seconds: 5), () async {
      if (!mounted) return;

      bool isMatched = false;
      List<Map<String, dynamic>> matchedPartners = [];

      try {
        final currentUser = _auth.currentUser;
        if (currentUser == null) return;

        // 扩展时间窗口到10分钟，增加匹配机会
        final tenMinutesAgo = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 10)),
        );

        // 添加更宽松的查询条件
        final snapshot = await _firestore
            .collection('users')
            .where('destination', isEqualTo: widget.destination)
            .where('createdAt', isGreaterThan: tenMinutesAgo)
            .where('uid', isNotEqualTo: currentUser.uid)
            .get();

        // 首先检查状态为searching的用户
        List<QueryDocumentSnapshot> searchingUsers = [];
        List<QueryDocumentSnapshot> otherUsers = [];

        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data['status'] == 'searching') {
            searchingUsers.add(doc);
          } else {
            otherUsers.add(doc);
          }
        }

        // 优先匹配状态为searching的用户
        if (searchingUsers.isNotEmpty) {
          for (var doc in searchingUsers) {
            final data = doc.data() as Map<String, dynamic>;
            final partnerLat = (data['latitude'] as num?)?.toDouble();
            final partnerLon = (data['longitude'] as num?)?.toDouble();

            if (partnerLat != null && partnerLon != null) {
              final distance = _calculateDistance(
                widget.currentPosition.latitude,
                widget.currentPosition.longitude,
                partnerLat,
                partnerLon,
              );

              if (distance <= 1000) {
                isMatched = true;
                matchedPartners.add({
                  'uid': data['uid'] ?? '',
                  'email': data['email'] ?? '',
                  'destination': data['destination'] ?? '',
                  'currentLocation': data['currentLocation'] ?? '',
                  'distance': distance.round(),
                  'docId': doc.id, // 保存文档ID以便后续更新
                });
                break; // 找到一个匹配就退出循环
              }
            }
          }
        }

        // 如果没有找到searching状态的用户，检查其他状态的用户
        if (!isMatched && otherUsers.isNotEmpty) {
          for (var doc in otherUsers) {
            final data = doc.data() as Map<String, dynamic>;
            // 只考虑状态不是cancelled或completed的用户
            if (data['status'] != 'cancelled' &&
                data['status'] != 'completed') {
              final partnerLat = (data['latitude'] as num?)?.toDouble();
              final partnerLon = (data['longitude'] as num?)?.toDouble();

              if (partnerLat != null && partnerLon != null) {
                final distance = _calculateDistance(
                  widget.currentPosition.latitude,
                  widget.currentPosition.longitude,
                  partnerLat,
                  partnerLon,
                );

                if (distance <= 1000) {
                  isMatched = true;
                  matchedPartners.add({
                    'uid': data['uid'] ?? '',
                    'email': data['email'] ?? '',
                    'destination': data['destination'] ?? '',
                    'currentLocation': data['currentLocation'] ?? '',
                    'distance': distance.round(),
                    'docId': doc.id,
                  });
                  break;
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint("❌ Error fetching partners: $e");
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to find matches: $e";
          });
        }
      }

      if (mounted) {
        setState(() {
          _isMatching = false;
          _matchSuccess = isMatched;
          _progress = 100;
        });
        _animationController.stop();
      }

      // 如果匹配成功，更新双方状态为matched
      if (isMatched && matchedPartners.isNotEmpty) {
        try {
          // 更新当前用户状态
          if (_currentUserDocId != null) {
            await _firestore.collection('users').doc(_currentUserDocId).update({
              'status': 'matched',
              'matchedWith': matchedPartners[0]['uid'],
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          // 更新匹配到的用户状态
          if (matchedPartners[0]['docId'] != null) {
            await _firestore
                .collection('users')
                .doc(matchedPartners[0]['docId'])
                .update({
                  'status': 'matched',
                  'matchedWith': _auth.currentUser?.uid,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
          }
        } catch (e) {
          debugPrint("❌ Error updating matched status: $e");
        }

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pop({
            'isMatched': isMatched,
            'matchedPartners': matchedPartners,
            'error': _errorMessage,
          });
        }
      }
    });
  }

  Future<void> _updateUserStatus(String status) async {
    if (_currentUserDocId != null) {
      try {
        await _firestore.collection('users').doc(_currentUserDocId).update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint("✅ User status updated to $status");
      } catch (e) {
        debugPrint("❌ Error updating user status: $e");
      }
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _messageTimer?.cancel();
    _matchingTimer?.cancel();
    _animationController.dispose();
    _updateUserStatus('cancelled');
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
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isMatching) _buildWalkingAnimation(),
                if (!_isMatching && _matchSuccess) _buildSuccessUI(),
                if (!_isMatching && !_matchSuccess) _buildFailureUI(),
                const SizedBox(height: 40),
                if (_isMatching) _buildProgressIndicator(),
                const SizedBox(height: 30),
                if (_isMatching) _buildSearchingMessage(),
                const SizedBox(height: 20),
                if (_isMatching) _buildRouteInfo(),
                const SizedBox(height: 30),
                if (_isMatching) _buildCancelButton(),
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
          '${_progress.round()}%',
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
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
          _buildLocationRow(
            Icons.location_on,
            Colors.blue,
            widget.currentLocation,
          ),
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: () {
        _progressTimer?.cancel();
        _messageTimer?.cancel();
        _matchingTimer?.cancel();
        _animationController.stop();

        _updateUserStatus('cancelled');

        Navigator.pop(context, {'isMatched': false, 'matchedPartners': []});
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text('Cancel Search', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildSuccessUI() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade100,
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.check_circle,
            size: 50,
            color: Colors.green.shade600,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Match Found!",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildFailureUI() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_walk,
              size: 50,
              color: Colors.orange.shade600,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'No Partners Available',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            _errorMessage ??
                'No one else is heading to your destination right now. You\'ll need to walk alone this time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: _errorMessage != null ? Colors.red : Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),

          // Single action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _updateUserStatus('completed');
                Navigator.of(
                  context,
                ).pop({'isMatched': false, 'matchedPartners': []});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: const Text(
                'Continue Alone',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
