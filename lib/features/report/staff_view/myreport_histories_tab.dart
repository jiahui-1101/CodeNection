import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'models/report_model.dart';
import 'report_card.dart';

//maybe this tab can move to another page
class MyReportsTab extends StatefulWidget { //tab/page to display user's own report history with ability to request urgency update
  const MyReportsTab({super.key});

  @override
  State<MyReportsTab> createState() => _MyReportsTabState();
}

class _MyReportsTabState extends State<MyReportsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? 'anonymous_user';
  }

  Future<void> _requestUrgency(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'isUrgent': true,
        'feedback': 'Your request to urge for update has been received. We will address this report within 12 hours. Thank you for your patience.',
        'lastUpdateTimestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request to urge update has been sent."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to urge for update: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Report>>(
      stream: _firestore
          .collection('reports')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('timestamp', descending: true)
          .withConverter<Report>(
            fromFirestore: Report.fromFirestore,
            toFirestore: (report, options) => report.toFirestore(),
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data?.docs.map((doc) => doc.data()).toList() ?? [];

        if (reports.isEmpty) {
          return const Center(
            child: Text(
              "You haven't submitted any reports yet.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return ReportCard(
              report: report,
              onRequestUrgency: _requestUrgency,
            );
          },
        );
      },
    );
  }
}