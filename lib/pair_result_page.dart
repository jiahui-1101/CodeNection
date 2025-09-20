// pair_result_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'navigation_page.dart';
import 'chat_page.dart';

class PairResultPage extends StatefulWidget {
  final String currentLocation;
  final String destination;
  final List<Map<String, dynamic>> matchedPartners;
  final VoidCallback onStartJourney;
  final VoidCallback onEndJourney;

  const PairResultPage({
    super.key,
    required this.currentLocation,
    required this.destination,
    required this.matchedPartners,
    required this.onStartJourney,
    required this.onEndJourney,
  });

  @override
  State<PairResultPage> createState() => _PairResultPageState();
}

class _PairResultPageState extends State<PairResultPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
  }

  /// ✅ Generate a consistent chatId for two users
  String _generateChatId(String partnerId) {
    final currentId = _currentUserId ?? '';
    final ids = [currentId, partnerId]..sort();
    return ids.join('_');
  }

  String _getAvatarEmoji(String email) {
    // Simple emoji based on email hash for consistency
    final hash = email.hashCode;
    final emojis = ['👤', '👨', '👩', '🧑', '👨‍💼', '👩‍💼', '🧑‍💼'];
    return emojis[hash.abs() % emojis.length];
  }

  String _getDisplayName(String email) {
    // Extract name from email (part before @)
    final namePart = email.split('@').first;
    // Capitalize first letter of each word
    return namePart
        .split('.')
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1);
        })
        .join(' ');
  }

  void _startNavigation() {
    widget.onStartJourney();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationPage(
          currentLocation: widget.currentLocation,
          destination: widget.destination,
          destinationLatLng: null,
          isWalkingTogether: true,
          onStartJourney: () {
            debugPrint("Journey started from PairResultPage ✅");
          },
          onEndJourney: widget.onEndJourney,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walking Partners Found'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Info
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Route',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.currentLocation.isEmpty
                                ? 'Current Location'
                                : widget.currentLocation,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.flag, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.destination.isEmpty
                                ? 'Destination'
                                : widget.destination,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Matched Users
            const Text(
              'Matched Partners',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: widget.matchedPartners.isEmpty
                  ? const Center(
                      child: Text(
                        'No partners found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.matchedPartners.length,
                      itemBuilder: (context, index) {
                        final partner = widget.matchedPartners[index];
                        final email = partner['email'] ?? 'Unknown';
                        final displayName = _getDisplayName(email);
                        final avatar = _getAvatarEmoji(email);

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              radius: 24,
                              child: Text(
                                avatar,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            title: Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(email),
                                const SizedBox(height: 4),
                                Text(
                                  'Going to: ${partner['destination'] ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              _showUserDetails(context, partner);
                            },
                          ),
                        );
                      },
                    ),
            ),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startNavigation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Walking Together',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> partner) {
    final email = (partner['email'] as String?) ?? 'Unknown';
    final displayName = _getDisplayName(email);
    final avatar = _getAvatarEmoji(email);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  radius: 40,
                  child: Text(avatar, style: const TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  email,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Route Information:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      partner['currentLocation'] ?? 'Unknown location',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.flag, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      partner['destination'] ?? 'Unknown destination',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final partnerId = (partner['uid'] as String?) ?? 'unknown';

                    // Generate chat ID exactly like in ChatPage
                    final List<String> userIds = [
                      FirebaseAuth.instance.currentUser!.uid,
                      partnerId,
                    ];
                    userIds.sort();
                    final chatId = 'chat_${userIds.join("_")}';

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatPage(partner: partner, chatId: chatId),
                      ),
                    );
                  },
                  child: const Text('Start Chat'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
