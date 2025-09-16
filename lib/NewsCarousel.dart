import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'NewsCard.dart';
import 'NewsDetailPage.dart';

class NewsCarousel extends StatefulWidget {
  const NewsCarousel({super.key});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  List<Map<String, dynamic>> newsData = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('news')
        .where('pinned', isEqualTo: true) // Only fetch pinned news
        .orderBy('createdAt', descending: true)
        .get();

    if (mounted) {
      setState(() {
        newsData = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
      
      if (newsData.isNotEmpty) {
        _startAutoScroll();
      }
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (newsData.isEmpty) return;

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

  void _stopAutoScroll() => _timer?.cancel();

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
          child: Text(
            "News & Updates",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (newsData.isEmpty)
                const Center(
                  child: Text(
                    "No pinned news available",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                PageView.builder(
                  controller: _pageController,
                  itemCount: newsData.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final newsItem = newsData[index];
                    return NewsCard(
                      documentId: newsItem['id'],
                      imageUrl: newsItem['image'] ?? '',
                      title: newsItem['title'] ?? '',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => NewsDetailPage(news: newsItem),
                          ),
                        );
                      },
                    );
                  },
                ),
              if (newsData.isNotEmpty && newsData.length > 1) ...[
                Positioned(
                  left: 0,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: Colors.black.withOpacity(0.7)),
                    onPressed: () {
                      _stopAutoScroll();
                      if (_pageController.hasClients) {
                        _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease);
                      }
                      _startAutoScroll();
                    },
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.arrow_forward_ios,
                        color: Colors.black.withOpacity(0.7)),
                    onPressed: () {
                      _stopAutoScroll();
                      if (_pageController.hasClients) {
                        _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease);
                      }
                      _startAutoScroll();
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}