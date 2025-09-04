import 'package:flutter/material.dart';
import 'package:hello_flutter/SosFloatingButton.dart';  
import 'package:hello_flutter/LiveFeedSection.dart';   //call der LiveFeedItem() is inside LiveFeedSection der class, wo hai mei fen chu lai

class FullFeedPage extends StatefulWidget {  //CLICK MORE AT BOTTOM OF LIVE FEED PAGE WILL ENTER全屏的Live Feed页面 (FullFeedPage Widget)
  const FullFeedPage({super.key});

  @override
  State<FullFeedPage> createState() => _FullFeedPageState();
}

class _FullFeedPageState extends State<FullFeedPage> {
  final TextEditingController _searchController = TextEditingController();

  // 模拟历史数据
  final List<Map<String, dynamic>> historyData = [
    {
      'icon': Icons.lightbulb_outline,
      'color': Colors.orange,
      'text': 'User reported a broken streetlight near Fakulti Komputeran.',
      'time': '5 mins ago'
    },
    {
      'icon': Icons.warning_amber_rounded,
      'color': Colors.red,
      'text': 'Suspicious person spotted near Kolej Tun Razak.',
      'time': '15 mins ago'
    },
    {
      'icon': Icons.pets,
      'color': Colors.brown,
      'text': 'Group of monkeys sighted near the library.',
      'time': '1 hour ago'
    },
    {
      'icon': Icons.announcement,
      'color': Colors.blue,
      'text': 'Official: Main road near mosque closed tonight for event.',
      'time': '3 hours ago'
    },
    {
      'icon': Icons.local_hospital,
      'color': Colors.green,
      'text': 'Medical emergency reported at Kolej Tun Dr. Ismail.',
      'time': '1 day ago'
    },
  ];

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    // 根据搜索过滤
    final filteredData = historyData.where((item) {
      final text = item['text']!.toString().toLowerCase();
      return text.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Community Feed Center",
          style: TextStyle(
            fontSize: 17.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFB3E5FC),
        actions: const [
          SosAppBarButton(),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search feed history...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF0FAFF),
              ),
            ),
          ),

          // 列表
          Expanded(
            child: filteredData.isEmpty
                ? const Center(
                    child: Text(
                      "❌ No results found.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final item = filteredData[index];
                      return LiveFeedItem(
                        icon: item['icon'],
                        color: item['color'],
                        text: item['text'],
                        time: item['time'],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
