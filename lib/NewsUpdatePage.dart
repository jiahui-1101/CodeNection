import 'package:flutter/material.dart';

class NewsUpdatePage extends StatefulWidget {
  const NewsUpdatePage({super.key});

  @override
  State<NewsUpdatePage> createState() => _NewsUpdatePageState();
}

class _NewsUpdatePageState extends State<NewsUpdatePage> {
  final List<Map<String, dynamic>> newsItems = [
    {
      'title': 'Campus Reopening Announcement',
      'date': 'May 15, 2023',
      'content': 'The campus will fully reopen starting June 1st with new safety protocols in place.',
      'important': true,
    },
    {
      'title': 'New Parking Regulations',
      'date': 'May 10, 2023',
      'content': 'Please be informed that new parking regulations will be enforced starting next week.',
      'important': false,
    },
    {
      'title': 'Library Extended Hours',
      'date': 'May 5, 2023',
      'content': 'The library will now be open until 11 PM during weekdays to accommodate students.',
      'important': false,
    },
    {
      'title': 'Weather Advisory',
      'date': 'May 3, 2023',
      'content': 'Heavy rain expected this weekend. Please take necessary precautions.',
      'important': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest Updates',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: newsItems.length,
                itemBuilder: (context, index) {
                  final news = newsItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: news['important'] ? Colors.orange[50] : null,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            news['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: news['important'] ? Colors.orange[800] : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            news['date'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(news['content']),
                      ),
                      trailing: news['important']
                          ? const Icon(Icons.warning, color: Colors.orange)
                          : const Icon(Icons.info, color: Colors.blue),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}