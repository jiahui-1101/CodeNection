import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hello_flutter/features/sos_alert/guard_view/guard_page.dart';
import 'package:hello_flutter/features/sos_alert/guard_view/guard_tracking_page.dart';
import 'package:hello_flutter/features/sos_alert/service/location_service.dart' as location_service;

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final String guardId = "guard_001";
  late Stream<QuerySnapshot> _pendingAlertsStream;

  @override
  void initState() {
    super.initState();
    _pendingAlertsStream = FirebaseFirestore.instance
        .collection('alerts')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> _acceptAndNavigate(String alertId) async {
    await FirebaseFirestore.instance.collection('alerts').doc(alertId).update({
      'status': 'accepted',
      'guardId': guardId,
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    final locationService = location_service.LocationService(guardId, isAlert: false);
    locationService.startSharingLocation();

    _navigateToTracking(alertId);
  }

  void _navigateToTracking(String alertId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrackingPage(
          alertId: alertId,
          guardId: guardId,
        ),
      ),
    );
  }

  void _navigateToGuardPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuardPage(guardId: guardId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Emergency Response Dashboard",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Pending alerts section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _pendingAlertsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          "No pending emergencies",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "All emergencies have been responded to",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final alerts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    return _buildAlertListItem(alerts[index]);
                  },
                );
              },
            ),
          ),
          
          // History button at the bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.history, size: 24),
              label: const Text(
                "VIEW EMERGENCY HISTORY",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _navigateToGuardPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertListItem(QueryDocumentSnapshot alert) {
    final data = alert.data() as Map<String, dynamic>;
    final isDuress = data['duress'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.red.shade50,
      child: ListTile(
        leading: const Icon(Icons.notifications_active, color: Colors.red),
        title: Text(
          data['title'] ?? 'Unknown Alert',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text("PENDING"),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => _acceptAndNavigate(alert.id),
          child: const Text("Accept"),
        ),
        tileColor: isDuress ? Colors.red.withOpacity(0.3) : null,
      ),
    );
  }
}