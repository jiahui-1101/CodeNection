import 'package:flutter/material.dart';
import 'package:hello_flutter/FullFeedPage.dart';   //LiveFeedPage you call FullFeedPage（ FullFeedPage Widget）

class LiveFeedSection extends StatelessWidget {    //  Live Feed -HOMEPAGE XIA部分 (LiveFeedSection Widget)
  const LiveFeedSection({super.key});

  final List<Map<String, dynamic>> feedData = const [
    {'icon': Icons.lightbulb_outline, 'color': Colors.orange, 'text': 'User reported a broken streetlight near Fakulti Komputeran.', 'time': '5 mins ago'},
    {'icon': Icons.warning_amber_rounded, 'color': Colors.red, 'text': 'Suspicious person reported near Kolej Tun Razak.', 'time': '15 mins ago'},
    {'icon': Icons.pets, 'color': Colors.brown, 'text': 'Group of monkeys spotted near the library.', 'time': '1 hour ago'},
    {'icon': Icons.announcement, 'color': Colors.blue, 'text': 'Official: The main road near the mosque will be closed for an event tonight.', 'time': '3 hours ago'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Community Live Feed", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: feedData.length > 4 ? 4 : feedData.length,
            itemBuilder: (context, index) {
              final item = feedData[index];
              return LiveFeedItem(
                icon: item['icon'],
                color: item['color'],
                text: item['text'],
                time: item['time'],
              );
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FullFeedPage()));
              },
              child: const Text("See All & Search History"),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveFeedItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String time;

  const LiveFeedItem({
    super.key,
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
                  Text(text, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
