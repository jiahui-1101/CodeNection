import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../user_view/NewsCard.dart';
import '../user_view/NewsDetailPage.dart';

class NewsListPage extends StatelessWidget {
  const NewsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latest News'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('news')
            .orderBy('pinned', descending: true)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final newsDocs = snapshot.data?.docs ?? [];
          if (newsDocs.isEmpty) return const Center(child: Text('No news articles found.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: newsDocs.length,
            itemBuilder: (context, index) {
              final doc = newsDocs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              data['id'] = doc.id;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: NewsCard(
                  documentId: doc.id,
                  imageUrl: data['image'] ?? '',
                  title: data['title'] ?? '',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NewsDetailPage(news: data)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
