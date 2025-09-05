import 'package:flutter/material.dart';

class NewsDetailPage extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String date;
  final String content;

  const NewsDetailPage({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.date,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("News Details"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. news image
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              // loading n error processing
              loadingBuilder: (context, child, progress) {
                return progress == null ? child : const Center(heightFactor: 5, child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(heightFactor: 5, child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
              },
            ),

            // 2. title, date and content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5, // Adjust line height so can read easily
                    ),
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