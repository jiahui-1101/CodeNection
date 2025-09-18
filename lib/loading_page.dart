// loading_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
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

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  bool _isMatching = true;
  bool _matchSuccess = false;
  int _progress = 0;
  final List<String> _searchingMessages = [
    "Searching nearby users...",
    "Analyzing walking routes...",
    "Matching similar destinations...",
    "Finding compatible walking partners...",
    "Almost there..."
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

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _walkingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
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
        _errorMessage = "Failed to start matching process";
        _isMatching = false;
        _matchSuccess = false;
      });
      _animationController.stop();
    }
  }

  /// 🔹 Save current user search info into Firestore
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
    // Adjust timing to match 5-second matching process
    const duration = Duration(milliseconds: 50);
    _progressTimer = Timer.periodic(duration, (timer) {
      if (_progress < 100) {
        setState(() {
          _progress += 1; // Reduced increment to match 5-second timeframe
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
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _searchingMessages.length;
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
        final currentUser = _auth.currentUser;
        if (currentUser == null) return;

        final snapshot = await _firestore
            .collection('users')
            .where('destination', isEqualTo: widget.destination)
            .get();

        // Filter out the current user locally
        final filteredDocs = snapshot.docs.where((doc) => 
            doc['uid'] != currentUser.uid).toList();

        if (filteredDocs.isNotEmpty) {
          isMatched = true;
          matchedPartners = filteredDocs.map((doc) {
            final data = doc.data();
            return {
              'uid': data['uid'] ?? '',
              'email': data['email'] ?? '',
              'destination': data['destination'] ?? '',
              'currentLocation': data['currentLocation'] ?? '',
            };
          }).toList();
        }
      } catch (e) {
        debugPrint("❌ Error fetching partners: $e");
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to find matches";
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

      // If matched, navigate immediately
      if (isMatched) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pop({
            'isMatched': isMatched,
            'matchedPartners': matchedPartners,
            'error': _errorMessage,
          });
        }
      }
      // If not matched, we'll show the failure UI and let the user decide next steps
    });
  }

  Future<void> _cleanupUserDocument() async {
    if (_currentUserDocId != null) {
      try {
        await _firestore.collection('users').doc(_currentUserDocId).delete();
        debugPrint("✅ User document cleaned up");
      } catch (e) {
        debugPrint("❌ Error cleaning up user document: $e");
      }
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _messageTimer?.cancel();
    _matchingTimer?.cancel();
    _animationController.dispose();
    _cleanupUserDocument();
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
        _progressTimer?.cancel();
        _messageTimer?.cancel();
        _matchingTimer?.cancel();
        _animationController.stop();

        if (_currentUserDocId != null) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserDocId)
              .delete();
        }

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
            'No one else is heading to your destination right now. You\'ll need to walk alone this time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          
          // Single action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'isMatched': false,
                  'matchedPartners': [],
                });
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

//demo

// demo_loading_page.dart
// import 'package:flutter/material.dart';
// import 'pair_result_page.dart';

// class LoadingPage extends StatefulWidget {
//   final String currentLocation;
//   final String destination;

//   const LoadingPage({
//     super.key,
//     required this.currentLocation,
//     required this.destination,
//   });

//   @override
//   State<LoadingPage> createState() => _LoadingPageState();
// }

// class _LoadingPageState extends State<LoadingPage> {
//   int _selectedScenario = 0;
//   final List<String> _scenarios = [
//     "No matches found",
//     "Single match found",
//     "Multiple matches found",
//     "Error scenario"
//   ];

//   final List<Map<String, dynamic>> _demoPartners = [
//     {
//       'uid': 'demo_uid_1',
//       'email': 'jane.smith@example.com',
//       'destination': 'Central Park',
//       'currentLocation': 'Times Square',
//     },
//     {
//       'uid': 'demo_uid_2',
//       'email': 'john.doe@example.com',
//       'destination': 'Central Park',
//       'currentLocation': 'Empire State Building',
//     },
//     {
//       'uid': 'demo_uid_3',
//       'email': 'sarah.williams@example.com',
//       'destination': 'Central Park',
//       'currentLocation': 'Rockefeller Center',
//     }
//   ];

//   void _navigateToResult() {
//     List<Map<String, dynamic>> matchedPartners = [];

//     switch (_selectedScenario) {
//       case 0: // No matches
//         matchedPartners = [];
//         break;
//       case 1: // Single match
//         matchedPartners = [_demoPartners[0]];
//         break;
//       case 2: // Multiple matches
//         matchedPartners = _demoPartners;
//         break;
//       case 3: // Error - use invalid data
//         matchedPartners = [
//           {'email': 'error@example.com'} // Minimal data to cause potential issues
//         ];
//         break;
//     }

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => PairResultPage(
//           currentLocation: widget.currentLocation,
//           destination: widget.destination,
//           matchedPartners: matchedPartners,
//           onStartJourney: () {
//             debugPrint("Demo journey started");
//           },
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Demo Mode - Test Scenarios'),
//         backgroundColor: Colors.purple,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Route info
//             Card(
//               elevation: 4,
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Your Route',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     _buildLocationRow(Icons.location_on, Colors.blue, widget.currentLocation),
//                     const SizedBox(height: 8),
//                     const Divider(height: 1),
//                     const SizedBox(height: 8),
//                     _buildLocationRow(Icons.flag, Colors.red, widget.destination),
//                   ],
//                 ),
//               ),
//             ),
            
//             const SizedBox(height: 30),
            
//             // Scenario selection
//             const Text(
//               'Select Test Scenario:',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 15),
            
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _scenarios.length,
//                 itemBuilder: (context, index) {
//                   return Card(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     color: _selectedScenario == index 
//                         ? Colors.purple.withOpacity(0.1) 
//                         : null,
//                     child: ListTile(
//                       title: Text(_scenarios[index]),
//                       leading: Radio<int>(
//                         value: index,
//                         groupValue: _selectedScenario,
//                         onChanged: (value) {
//                           setState(() {
//                             _selectedScenario = value!;
//                           });
//                         },
//                       ),
//                       onTap: () {
//                         setState(() {
//                           _selectedScenario = index;
//                         });
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
            
//             // Action button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _navigateToResult,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.purple,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   'Test This Scenario',
//                   style: TextStyle(fontSize: 16, color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLocationRow(IconData icon, Color color, String text) {
//     return Row(
//       children: [
//         Icon(icon, color: color, size: 20),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Text(
//             text,
//             style: const TextStyle(fontSize: 16),
//           ),
//         ),
//       ],
//     );
//   }
// }