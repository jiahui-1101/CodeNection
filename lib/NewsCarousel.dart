import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hello_flutter/NewsCard.dart';
import 'package:hello_flutter/NewsDetailPage.dart';

class NewsCarousel extends StatefulWidget {           //  新闻轮播 (NewsCarousel Widget)
  const NewsCarousel({super.key});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  final List<Map<String, String>> newsData = [
    {'image': 'https://news.utm.my/wp-content/uploads/2022/05/3D2A3753-1200x800.jpg', 
    'title': 'oh wow fantastic Campus Security Patrols Increased at Night',
    'date': '2025/9/5',
      'content': 'Inspection of the campus security patrols at night has been increased.\n\nThis is to ensure the safety of all students and staff on campus. Please report any suspicious activities to the campus security immediately.\n\nThank you for your cooperation.'
      },
    {'image': 'https://images.unsplash.com/photo-1517486808906-6ca8b3f04846?q=80&w=1974', 
    'title': 'New Well-Lit Pathway Opens Near Library',
    'date': '2025/9/6',
    'content': 'A new well-lit pathway has been opened near the library to enhance safety for students walking at night. This initiative is part of the university\'s ongoing efforts to improve campus safety and accessibility.\n\nWe encourage all students to utilize this new pathway and report any safety concerns to campus security.'
    },
    {'image': 'https://images.unsplash.com/photo-1616763355548-1b606f439f86?q=80&w=2070',
    'title': 'Reminder: Final Exam Week Shuttle Bus Schedule',
    'date': '2025/9/7',
    'content': 'During the final exam week, the shuttle bus service will operate on a modified schedule. Please check the university website for the latest updates and plan your travel accordingly.\n\nGood luck to all students taking their exams!'
    },
  ];

  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < newsData.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeIn,
        );
      }
    });
  }

  void _stopAutoScroll() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 24.0, top: 24.0),
          child: Text("News & Updates", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: newsData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  // 获取当前这条新闻的所有数据
                  final newsItem = newsData[index];

                  // 返回一个可点击的新闻卡片
                  return NewsCard(
                    imageUrl: newsItem['image']!,
                    title: newsItem['title']!,
                    onTap: () {
                      // 点击时，导航到新闻详情页
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NewsDetailPage(
                            imageUrl: newsItem['image'] ?? 'https://via.placeholder.com/400x250',
                            title: newsItem['title'] ?? 'Untitled',
                            date: newsItem['date'] ?? 'Unknown Date',
                            content: newsItem['content'] ?? 'No content available.',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              Positioned(
                left: 0,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: Colors.black.withOpacity(0.7)),
                  onPressed: () {
                    _stopAutoScroll();
                    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                    _startAutoScroll();
                  },
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.black.withOpacity(0.7)),
                  onPressed: () {
                    _stopAutoScroll();
                    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                    _startAutoScroll();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}