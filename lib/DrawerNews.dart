import 'package:flutter/material.dart';
import 'package:hello_flutter/NewsCard.dart';

class DrawerNews extends StatelessWidget {
  const DrawerNews({super.key});

  // sini got a list of news that i cincai take from browser
  final List<Map<String, String>> allNewsData = const [
    {'image': 'https://images.unsplash.com/photo-1517486808906-6ca8b3f04846?q=80&w=1974', 'title': 'Campus Security Patrols Increased at Night'},
    {'image': 'https://images.unsplash.com/photo-1616763355548-1b606f439f86?q=80&w=2070', 'title': 'Reminder: Final Exam Week Shuttle Bus Schedule'},
    {'image': 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?q=80&w=2070', 'title': 'Student Volunteer Program Now Open for Registration'},
    {'image': 'https://images.unsplash.com/photo-1556742502-ec7c0e9f34b1?q=80&w=1887', 'title': 'New Cafeteria Payment System to be Launched Next Month'},
    {'image': 'https://images.unsplash.com/photo-1606761568499-6d2451b23c66?q=80&w=1974', 'title': 'Library Will Be Closed for Maintenance This Weekend'},
    {'image': 'https://images.unsplash.com/photo-1543269865-cbf427effbad?q=80&w=2070', 'title': 'Join the Annual University Fun Run!'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News and Updates'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),

      backgroundColor: const Color(0xFFE0F7FA),

      body: ListView.builder(
        // 使用 itemCount 来告诉 ListView 有多少个条目
        itemCount: allNewsData.length,
        // 使用 itemBuilder 来构建每个新闻卡片
        itemBuilder: (context, index) {
          final newsItem = allNewsData[index];
          // 在每个卡片周围添加一些边距
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            // 复用您已经创建的 NewsCard Widget
            child: NewsCard(
              imageUrl: newsItem['image']!,
              title: newsItem['title']!,
            ),
          );
        },
      ),
    );
  }
}