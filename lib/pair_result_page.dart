// pair_result_page.dart
import 'package:flutter/material.dart';

class PairResultPage extends StatefulWidget {
  final String currentLocation;
  final String destination;
  final VoidCallback onStartJourney;

  const PairResultPage({
    super.key,
    required this.currentLocation,
    required this.destination,
    required this.onStartJourney,
  });

  @override
  State<PairResultPage> createState() => _PairResultPageState();
}

class _PairResultPageState extends State<PairResultPage> {
  final List<Map<String, dynamic>> _matchedUsers = [
    {
      'name': 'Sarah Chen',
      'profileImage': '👩',
      'rating': 4.8,
      'walkingSpeed': 'Normal',
      'matchPercentage': 92,
    },
    {
      'name': 'Mike Lim',
      'profileImage': '👨',
      'rating': 4.5,
      'walkingSpeed': 'Fast',
      'matchPercentage': 88,
    }
  ];

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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Route',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(widget.currentLocation)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.flag, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(widget.destination)),
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
                itemCount: _matchedUsers.length,
                itemBuilder: (context, index) {
                  final user = _matchedUsers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Text(
                        user['profileImage'],
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(user['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('⭐ ${user['rating']} Rating'),
                          Text('🚶 ${user['walkingSpeed']} Pace'),
                        ],
                      ),
                      trailing: Chip(
                        label: Text('${user['matchPercentage']}% Match'),
                        backgroundColor: Colors.green.shade100,
                      ),
                      onTap: () {
                        // Show user details or start chat
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
                onPressed: () {
                  widget.onStartJourney();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}