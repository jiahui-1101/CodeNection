// 文件名: guard_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:hello_flutter/features/sos_alert/guard_view/guard_tracking_page.dart';
import 'package:hello_flutter/features/sos_alert/service/location_service.dart';
import 'alert_record_histories.dart';
class GuardPage extends StatefulWidget {
  final String guardId;
  const GuardPage({super.key, required this.guardId});

  @override
  State<GuardPage> createState() => _GuardPageState();
}

class _GuardPageState extends State<GuardPage> {
  late Stream<List<QueryDocumentSnapshot>> _alertsStream;

  @override
  void initState() {
    super.initState();

    Stream<QuerySnapshot> pendingStream = FirebaseFirestore.instance
        .collection('alerts')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    Stream<QuerySnapshot> myTasksStream = FirebaseFirestore.instance
        .collection('alerts')
        .where('guardId', isEqualTo: widget.guardId)
        .snapshots();

    _alertsStream = CombineLatestStream.combine2(
      pendingStream,
      myTasksStream,
      (QuerySnapshot pending, QuerySnapshot myTasks) {
        final docs1 = pending.docs;
        final docs2 = myTasks.docs;

        final allDocsMap = <String, QueryDocumentSnapshot>{};
        for (var doc in docs1) {
          allDocsMap[doc.id] = doc;
        }
        for (var doc in docs2) {
          allDocsMap[doc.id] = doc;
        }

        final combinedList = allDocsMap.values.toList();

        combinedList.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final timeA = dataA['timestamp'] as Timestamp? ?? Timestamp(0, 0);
          final timeB = dataB['timestamp'] as Timestamp? ?? Timestamp(0, 0);
          return timeB.compareTo(timeA);
        });

        return combinedList;
      },
    );
  }

  Future<void> _acceptAndNavigate(String alertId) async {
    await FirebaseFirestore.instance.collection('alerts').doc(alertId).update({
      'status': 'accepted',
      'guardId': widget.guardId,
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    final locationService = LocationService(widget.guardId, isAlert: false);
    locationService.startSharingLocation();

    _navigateToTracking(alertId);
  }

  void _navigateToTracking(String alertId) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrackingPage(
          alertId: alertId,
          guardId: widget.guardId,
        ),
      ),
    );
  }

  void _navigateToRecordings(String alertId) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordingsPage(alertId: alertId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Alerts Dashboard"),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: _alertsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No relevant alerts."));
          }

          final alerts = snapshot.data!;

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              return _buildAlertListItem(alerts[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildAlertListItem(QueryDocumentSnapshot alert) {
    final data = alert.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'unknown';
    final isDuress = data['duress'] == true;

    IconData statusIcon;
    Color statusColor;
    String statusText = status.toString().toUpperCase();
    Widget actionButton;

    switch (status) {
      case 'pending':
        statusIcon = Icons.notifications_active;
        statusColor = Colors.red;
        actionButton = ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => _acceptAndNavigate(alert.id),
          child: const Text("Accept"),
        );
        break;
      case 'accepted':
        statusIcon = Icons.run_circle_outlined;
        statusColor = Colors.orange;
        actionButton = ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () => _navigateToTracking(alert.id),
          child: const Text("Continue"),
        );
        break;
      default: // completed, cancelled, etc.
        statusIcon = Icons.check_circle;
        statusColor = Colors.grey;
        actionButton = IconButton(
          icon: const Icon(Icons.history, color: Colors.blueGrey),
          onPressed: () => _navigateToRecordings(alert.id),
        );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: status == 'pending'
          ? Colors.red.shade50
          : (status == 'accepted'
              ? Colors.orange.shade50
              : Colors.grey.shade200),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(data['title'] ?? 'Unknown Alert',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(statusText),
        trailing: actionButton,
        onTap: status == 'accepted'
            ? () => _navigateToTracking(alert.id)
            : (status == 'completed'
                ? () => _navigateToRecordings(alert.id)
                : null),
        tileColor: isDuress ? Colors.red.withOpacity(0.3) : null,
      ),
    );
  }
}
