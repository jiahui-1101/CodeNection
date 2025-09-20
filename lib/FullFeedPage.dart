import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hello_flutter/SosFloatingButton.dart';

class FullFeedPage extends StatefulWidget {
  const FullFeedPage({super.key});

  @override
  State<FullFeedPage> createState() => _FullFeedPageState();
}

class _FullFeedPageState extends State<FullFeedPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Pick icon & color
  Map<String, dynamic> _getIconAndColor(
    String type,
    String? status,
    String? text,
  ) {
    if (type == 'alert') {
      return {'icon': Icons.warning_amber_rounded, 'color': Colors.red};
    } else if (type == 'report') {
      return {'icon': Icons.report_problem, 'color': Colors.orange};
    } else if (type == 'user') {
      if (text?.toLowerCase().contains('closed') ?? false) {
        return {'icon': Icons.announcement, 'color': Colors.blue};
      } else if (text?.toLowerCase().contains('medical') ?? false) {
        return {'icon': Icons.local_hospital, 'color': Colors.green};
      }
    }
    return {'icon': Icons.info, 'color': Colors.grey};
  }

  String _formatTime(Timestamp timestamp) {
    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return "Just now";
    if (difference.inMinutes < 60) return '${difference.inMinutes} mins ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Community Feed Center",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          const SosAppBarButton(),
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await _auth.signOut();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
      body: user == null
          ? Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 50, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      "Authentication Required",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Please log in to view the community feed",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Go Back"),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[50],
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search feed history...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = "");
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                // Results count
                if (_searchQuery.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.grey[50],
                    width: double.infinity,
                    child: Text(
                      "Search results for '$_searchQuery'",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                // Feed Stream (by user.uid)
                Expanded(
                  child: StreamBuilder<List<QuerySnapshot>>(
                    stream: CombineLatestStream.list([
                      _firestore
                          .collection('reports')
                          .where('uid', isEqualTo: user.uid)
                          .snapshots(),
                      _firestore
                          .collection('alerts')
                          .where('userId', isEqualTo: user.uid)
                          .snapshots(),
                      _firestore
                          .collection('users')
                          .where('uid', isEqualTo: user.uid)
                          .snapshots(),
                    ]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
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
                        allData.add({
                          'icon': Icons.collections_bookmark,
                          'color': Colors.orange,
                          'text': text,
                          'time': _formatTime(timestamp),
                          'timestamp': timestamp,
                          'type': 'Report', // ✅ Add this
                        });
                      }

                      // Alerts
                      for (var doc in alertsSnap.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final timestamp = data['timestamp'] ?? Timestamp.now();
                        final text = data['status'] ?? 'No status';
                        allData.add({
                          'icon': Icons.notifications_active,
                          'color': Colors.red,
                          'text': text,
                          'time': _formatTime(timestamp),
                          'timestamp': timestamp,
                          'type': 'Alert', // ✅ Add this
                        });
                      }

                      // Users
                      for (var doc in usersSnap.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final timestamp = data['createdAt'] ?? Timestamp.now();
                        final text =
                            'User destination: ${data['destination'] ?? 'Unknown'}';
                        allData.add({
                          'icon': Icons.location_on,
                          'color': Colors.blue,
                          'text': text,
                          'time': _formatTime(timestamp),
                          'timestamp': timestamp,
                          'type': 'User Activity', // ✅ Add this
                        });
                      }

                      // Sort newest first
                      allData.sort(
                        (a, b) => b['timestamp'].compareTo(a['timestamp']),
                      );

                      // Search filter
                      final filteredData = allData.where((item) {
                        return item['text'].toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        );
                      }).toList();

                      if (filteredData.isEmpty) {
                        return const Center(
                          child: Text(
                            "No feed items found",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      // ✅ LiveFeedSection style UI
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredData.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filteredData[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    item['icon'],
                                    color: item['color'],
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ✅ Title (Report / Alert / User)
                                        Text(
                                          item['type'], // <-- use the type here
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),

                                        // ✅ Main text
                                        Text(
                                          item['text'],
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),

                                        // ✅ Time
                                        Text(
                                          item['time'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
