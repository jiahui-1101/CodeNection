import 'package:flutter/material.dart';

class LocationSelectionPage extends StatefulWidget {
  const LocationSelectionPage({super.key});

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  String? current;
  String? destination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Locations")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Current Location"),
              onChanged: (val) => current = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Destination"),
              onChanged: (val) => destination = val,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'current': current ?? '',
                  'destination': destination ?? '',
                });
              },
              child: const Text("Confirm"),
            ),
          ],
        ),
      ),
    );
  }
}