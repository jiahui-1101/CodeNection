// lib/pages/report_category_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../models/report_list_item.dart';

class ReportCategoryPage extends StatelessWidget {
  final String category;
  const ReportCategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$category Reports'),
        backgroundColor: const Color(0xFF8EB9D4),
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: kToolbarHeight * 0.8,
      ),
      body: StreamBuilder<QuerySnapshot<Report>>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('category', isEqualTo: category)
            .orderBy('timestamp', descending: true)
            .withConverter<Report>(
              fromFirestore: Report.fromFirestore,
              toFirestore: (Report report, _) => report.toFirestore(),
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading reports'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data?.docs.map((doc) => doc.data()).toList() ?? [];
          if (reports.isEmpty) {
            return Center(child: Text('No reports found in "$category" category'));
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