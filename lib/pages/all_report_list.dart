// lib/pages/all_reports_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/report_model.dart';
import 'report_detail_page.dart'; // 导入 ReportDetailPage
import '../models/report_list_item.dart';

class AllReportsListPage extends StatelessWidget {
  const AllReportsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Reports"),
        backgroundColor: const Color(0xFF8EB9D4),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Report>>(
        stream: firestore
            .collection('reports')
            .withConverter<Report>(
              fromFirestore: Report.fromFirestore,
              toFirestore: (Report report, _) => report.toFirestore(),
            )
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Error fetching all reports: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports =
              snapshot.data?.docs.map((doc) => doc.data()).toList() ?? [];

          if (reports.isEmpty) {
            return const Center(child: Text('No reports found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return ReportListItem(report: report);
            },
          );
        },
      ),
    );
  }
}

