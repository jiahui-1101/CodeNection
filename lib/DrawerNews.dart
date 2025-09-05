import 'package:flutter/material.dart';
import 'package:hello_flutter/NewsCard.dart';
import 'package:hello_flutter/NewsDetailPage.dart';

class DrawerNews extends StatelessWidget {
  const DrawerNews({super.key});

  // sini got a list of news that i cincai take from browser
  final List<Map<String, String>> allNewsData = const [
    {
      'image': 'https://images.unsplash.com/photo-1517486808906-6ca8b3f04846?q=80&w=1974',
      'title': 'Campus Security Patrols Increased at Night',
      'date': '2025/9/6',
      'content': 'To enhance safety and security, the university has increased the frequency of security patrols during nighttime hours. Students and staff are encouraged to remain vigilant and report any suspicious activities.'
    },
    {
      'image': 'https://images.unsplash.com/photo-1616763355548-1b606f439f86?q=80&w=2070',
      'title': 'Reminder: Final Exam Week Shuttle Bus Schedule',
      'date': '2025/9/7',
      'content': 'Please be advised that the shuttle bus service will operate on a special schedule during the final exam week to accommodate students. Check the university website for the detailed timetable.'
    },
    {
      'image': 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?q=80&w=2070',
      'title': 'Student Volunteer Program Now Open for Registration',
      'date': '2025/9/6',
      'content': 'The annual Student Volunteer Program is now accepting registrations. This is a great opportunity for students to contribute to the community and gain valuable experience. Sign up today!'
    },
    {
      'image': 'https://images.unsplash.com/photo-1556742502-ec7c0e9f34b1?q=80&w=1887',
      'title': 'New Cafeteria Payment System to be Launched Next Month',
      'date': '2025/9/5',
      'content': 'A new cashless payment system will be introduced at all campus cafeterias starting next month. The system aims to provide a more convenient and efficient dining experience for everyone.'
    },
    {
      'image': 'https://images.unsplash.com/photo-1606761568499-6d2451b23c66?q=80&w=1974',
      'title': 'Library Will Be Closed for Maintenance This Weekend',
      'date': '2025/9/4',
      'content': 'The main library will be closed this upcoming weekend for scheduled system maintenance. We apologize for any inconvenience caused. All online resources will remain accessible.'
    },
    {
      'image': 'https://images.unsplash.com/photo-1543269865-cbf427effbad?q=80&w=2070',
      'title': 'Join the Annual University Fun Run!',
      'date': '2025/9/3',
      'content': 'Get your running shoes ready for the annual University Fun Run! This event is open to all students and staff. Register now to receive a complimentary event t-shirt.'
    },
    
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
        itemCount: allNewsData.length,
        itemBuilder: (context, index) {
          final newsItem = allNewsData[index];
          // add padding around each NewsCard
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            // reuse sediada punya NewsCard widget
            child: NewsCard(
              imageUrl: newsItem['image']!,
              title: newsItem['title']!,

               onTap: () {
                // Navigate to the detail page when tapped
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NewsDetailPage(
                      // Pass the news item data to the detail page
                      imageUrl: newsItem['image'] ?? '',
                      title: newsItem['title'] ?? 'No Title',
                      date: newsItem['date'] ?? 'No Date',
                      content: newsItem['content'] ?? 'No Content',
                    ),
                  ),
                );
              },
              
            ),
          );
        },
      ),
    );
  }
}