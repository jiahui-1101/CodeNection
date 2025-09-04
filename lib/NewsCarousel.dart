import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hello_flutter/NewsCard.dart';

class NewsCarousel extends StatefulWidget {           // 4. 新闻轮播 (NewsCarousel Widget)
  const NewsCarousel({super.key});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  final List<Map<String, String>> newsData = [
    {'image': 'https://news.utm.my/wp-content/uploads/2022/05/3D2A3753-1200x800.jpg', 'title': 'Hehehe Campus Security Patrols Increased at Night'},
    {'image': 'https://images.unsplash.com/photo-1517486808906-6ca8b3f04846?q=80&w=1974', 'title': 'New Well-Lit Pathway Opens Near Library'},
    {'image': 'https://images.unsplash.com/photo-1616763355548-1b606f439f86?q=80&w=2070', 'title': 'Reminder: Final Exam Week Shuttle Bus Schedule'},
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
                  return NewsCard(
                      imageUrl: newsData[index]['image']!,
                      title: newsData[index]['title']!);
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