// pair_result_page.dart
import 'package:flutter/material.dart';
import 'navigation_page.dart'; // Import the navigation page
import 'chat_page.dart';

class PairResultPage extends StatefulWidget {
  final String currentLocation;
  final String destination;
  final List<Map<String, dynamic>> matchedPartners;
  final VoidCallback onStartJourney;

  const PairResultPage({
    super.key,
    required this.currentLocation,
    required this.destination,
    required this.matchedPartners,
    required this.onStartJourney,
    
  });

  @override
  State<PairResultPage> createState() => _PairResultPageState();
}

class _PairResultPageState extends State<PairResultPage> {
  // Generate mock data to display instead of null values
  List<Map<String, dynamic>> get displayPartners {
    if (widget.matchedPartners.isEmpty ||
        widget.matchedPartners.any((partner) => partner['name'] == null)) {
      return [
        {
          'name': 'Sarah Johnson',
          'rating': 4.8,
          'walkingSpeed': 'Moderate',
          'matchPercentage': 92,
          'profileImage': '👩',
          'distance': '0.2 miles away',
          'interests': ['Music', 'Reading', 'Coffee'],
        },
        {
          'name': 'Michael Chen',
          'rating': 4.5,
          'walkingSpeed': 'Brisk',
          'matchPercentage': 85,
          'profileImage': '👨',
          'distance': '0.5 miles away',
          'interests': ['Technology', 'Hiking', 'Photography'],
        },
        {
          'name': 'Emma Williams',
          'rating': 4.9,
          'walkingSpeed': 'Leisurely',
          'matchPercentage': 78,
          'profileImage': '👩',
          'distance': '0.3 miles away',
          'interests': ['Art', 'Yoga', 'Travel'],
        },
      ];
    }
    return widget.matchedPartners;
  }

  String get displayCurrentLocation {
    return widget.currentLocation.isEmpty
        ? '123 Main Street, Downtown'
        : widget.currentLocation;
  }

  String get displayDestination {
    return widget.destination.isEmpty
        ? 'Central Park, West Side'
        : widget.destination;
  }

  void _startNavigation() {
    // Call the original callback if needed
    widget.onStartJourney();

    // Navigate to NavigationPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationPage(
          currentLocation: widget.currentLocation,
          destination: widget.destination,
          destinationLatLng: null, // or pass real LatLng if available
          isWalkingTogether: true,
          onStartJourney: () {
            // Optional: handle when journey starts
            debugPrint("Journey started from PairResultPage ✅");
          },
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
                        Expanded(child: Text(displayCurrentLocation)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.flag, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(displayDestination)),
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
              child: ListView.builder(
                itemCount: displayPartners.length,
                itemBuilder: (context, index) {
                  final user = displayPartners[index];
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
                          user['profileImage'] ?? '👤',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      title: Text(
                        user['name'] ?? 'Walking Partner',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text('${user['rating'] ?? '4.5'} Rating'),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_walk,
                                color: Colors.blue,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${user['walkingSpeed'] ?? 'Moderate'} Pace',
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_pin,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(user['distance'] ?? 'Nearby'),
                            ],
                          ),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          '${user['matchPercentage'] ?? '85'}% Match',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                      ),
                      onTap: () {
                        _showUserDetails(context, user);
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
                onPressed:
                    _startNavigation, // Use the corrected navigation method
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

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
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
                  child: Text(
                    user['profileImage'] ?? '👤',
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user['name'] ?? 'Walking Partner',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDetailChip(
                    '⭐ ${user['rating'] ?? '4.5'}',
                    Colors.amber,
                  ),
                  _buildDetailChip(
                    '🚶 ${user['walkingSpeed'] ?? 'Moderate'}',
                    Colors.blue,
                  ),
                  _buildDetailChip(
                    '${user['matchPercentage'] ?? '85'}% Match',
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Interests:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    (user['interests'] as List<String>? ??
                            ['Walking', 'Nature', 'Conversation'])
                        .map(
                          (interest) => Chip(
                            label: Text(interest),
                            backgroundColor: Colors.grey.shade200,
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to ChatPage instead of popping
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatPage()),
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

  Widget _buildDetailChip(String label, Color color) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}
