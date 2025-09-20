import 'package:flutter/material.dart';
import 'package:hello_flutter/FullFeedPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class LiveFeedSection extends StatelessWidget {
  const LiveFeedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Please log in to see your community feed",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Community Live Feed",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // ✅ Combine reports + alerts + users (latest 4 only)
          StreamBuilder<List<QuerySnapshot>>(
            stream: CombineLatestStream.list([
              FirebaseFirestore.instance
                  .collection('reports')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              FirebaseFirestore.instance
                  .collection('alerts')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              FirebaseFirestore.instance
                  .collection('users')
                  .where('uid', isEqualTo: user.uid)
                  .snapshots(),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                          strokeWidth: 2,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Loading feed...",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Failed to load feed",
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: const Column(
                    children: [
                      Icon(Icons.feed_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        "No recent feed available",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final reportsSnap = snapshot.data![0];
              final alertsSnap = snapshot.data![1];
              final usersSnap = snapshot.data![2];

              final List<Map<String, dynamic>> allData = [];

              // Reports
              for (var doc in reportsSnap.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = data['timestamp'] ?? Timestamp.now();
                final text = data['status'] ?? 'No status';
                final title = data['title'] ?? 'No title';

                allData.add({
                  'icon': Icons.collections_bookmark,
                  'color': Colors.orange,
                  'title': title, // ✅ show title
                  'text': text, // ✅ show status
                  'time': _formatTime(timestamp),
                  'timestamp': timestamp,
                  'type': 'Report',
                });
              }

              // Alerts
              for (var doc in alertsSnap.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = data['timestamp'] ?? Timestamp.now();
                final status = data['status'] ?? 'No status';
                final alertTitle = data['title'] ?? 'No title';

                allData.add({
                  'icon': Icons.notifications_active,
                  'color': Colors.red,
                  'title':
                      alertTitle, // 🔹 This will still be shown as the "section title"
                  'text':
                      "Status: $status", // 🔹 Append status in the text field
                  'time': _formatTime(timestamp),
                  'timestamp': timestamp,
                });
              }

              // Users
              for (var doc in usersSnap.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = data['createdAt'] ?? Timestamp.now();
                final text =
                    'User destination: ${data['destination'] ?? 'Unknown'}';
                allData.add({
                  'title': 'User Activity',
                  'icon': Icons.location_on,
                  'color': Colors.blue,
                  'text': text,
                  'time': _formatTime(timestamp),
                  'timestamp': timestamp,
                });
              }

              // Sort by newest, then take only 4
              allData.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
              final latest4 = allData.take(4).toList();

              if (latest4.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: const Column(
                    children: [
                      Icon(Icons.feed_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        "No recent activity to show",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: latest4.length,
                itemBuilder: (context, index) {
                  final item = latest4[index];
                  return LiveFeedItem(
                    title: item['title'],
                    icon: item['icon'],
                    color: item['color'],
                    text: item['text'],
                    time: item['time'],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const FullFeedPage()));
              },
              child: const Text("See All & Search History"),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ format Firestore timestamp
  static String _formatTime(Timestamp timestamp) {
    final now = DateTime.now();
    final time = timestamp.toDate();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    return "${diff.inDays} days ago";
  }
}

class LiveFeedItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String text;
  final String time;

  const LiveFeedItem({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(text, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
