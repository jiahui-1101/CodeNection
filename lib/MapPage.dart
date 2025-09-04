import 'dart:async';
import 'package:flutter/material.dart';
import 'LocationSelectionPage.dart'; // 引入另一个页面


class MapPage extends StatefulWidget {               //PLACEHOLDER PAGE---MAPPAGE
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String? currentLocation;
  String? destination;
  bool journeyStarted = false;
  bool matchingMode = false;
  int countdown = 60;
  Timer? matchTimer;

  @override
  void dispose() {
    matchTimer?.cancel();
    super.dispose();
  }

  void _startMatching() {
    setState(() {
      matchingMode = true;
      countdown = 60;
    });

    matchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown == 0) {
        timer.cancel();
        _startWalkAlone();
      } else {
        setState(() {
          countdown--;
        });
      }
    });
  }

  void _startWalkAlone() {
    setState(() {
      matchingMode = false;
      journeyStarted = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🚶 Starting journey alone...")),
    );
  }

  void _selectLocations() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationSelectionPage(),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        currentLocation = result['current'];
        destination = result['destination'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _selectLocations,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    destination == null
                        ? "Search destination..."
                        : "$currentLocation → $destination",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.grey.shade300,
            child: const Center(child: Text("🗺️ Fake Map Placeholder")),
          ),
        ),
        if (destination != null && !journeyStarted && !matchingMode)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => _buildJourneyOptions(),
                );
              },
              child: const Text("Start Journey"),
            ),
          ),
        if (matchingMode)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "Matching teammates... $countdown s",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildJourneyOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: _startWalkAlone,
            child: const Text("🚶 Walk Alone (Start Now)"),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _startMatching,
            child: const Text("🤝 Let's WA Mode"),
          ),
        ],
      ),
    );
  }
}