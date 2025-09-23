import 'package:flutter/material.dart';
import 'package:hello_flutter/NewsCarousel.dart';
import 'package:hello_flutter/LiveFeedSection.dart';

class HomePage extends StatelessWidget {        // Placeholder Pages--HomePage
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const NewsCarousel(),
          const SizedBox(height: 24),
          const LiveFeedSection(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

