// lib/pages/all_reports_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../models/report_list_item.dart';
import 'report_detail_page.dart';

class AllReportsListPage extends StatefulWidget {
  const AllReportsListPage({super.key});

  @override
  State<AllReportsListPage> createState() => _AllReportsListPageState();
}

class _AllReportsListPageState extends State<AllReportsListPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Reports"),
        backgroundColor: const Color(0xFF8EB9D4),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search reports by title or description...",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchKeyword = value.trim().toLowerCase();
                });
              },
            ),
          ),

          // 报告列表
          Expanded(
            child: StreamBuilder<QuerySnapshot<Report>>(
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
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 获取所有报告
                final allReports =
                    snapshot.data?.docs.map((doc) => doc.data()).toList() ?? [];

                // 过滤匹配的报告（title 或 description）
                final filteredReports = _searchKeyword.isEmpty
                    ? allReports
                    : allReports.where((report) {
                        final titleMatch =
                            report.title.toLowerCase().contains(_searchKeyword);
                        final descMatch = report.description
                                ?.toLowerCase()
                                .contains(_searchKeyword) ??
                            false;
                        return titleMatch || descMatch;
                      }).toList();

                if (filteredReports.isEmpty) {
                  return const Center(
                      child: Text('No reports match your search'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = filteredReports[index];
                    return ReportListItem(report: report);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

