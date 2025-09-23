import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../models/report_list_item.dart';

class AllReportsListPage extends StatefulWidget { //page to display all reports with search and filter functionality for staff
  const AllReportsListPage({super.key});

  @override
  State<AllReportsListPage> createState() => _AllReportsListPageState();
}

class _AllReportsListPageState extends State<AllReportsListPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = "";

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); 
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Reports"),
        backgroundColor: const Color(0xFF8EB9D4),
        foregroundColor: Colors.white,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, 
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Submitted"),
            Tab(text: "In Progress"),
            Tab(text: "Completed"),
            Tab(text: "Rejected"),
          ],
        ),
      ),
      body: Column(
        children: [
        
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search reports...",
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

          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const PageScrollPhysics(), 
              children: [
                _buildReportList(null), // All
                _buildReportList(ReportStatus.submitted),
                _buildReportList(ReportStatus.inProgress),
                _buildReportList(ReportStatus.completed),
                _buildReportList(ReportStatus.rejected),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList(ReportStatus? status) {
    return StreamBuilder<QuerySnapshot<Report>>(
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

        final allReports =
            snapshot.data?.docs.map((doc) => doc.data()).toList() ?? [];

        final filteredByStatus = status == null
            ? allReports
            : allReports.where((report) => report.status == status).toList();

        final filteredReports = _searchKeyword.isEmpty
            ? filteredByStatus
            : filteredByStatus.where((report) {
                final titleMatch =
                    report.title.toLowerCase().contains(_searchKeyword);
                final descMatch =
                    report.description.toLowerCase().contains(_searchKeyword) ??
                        false;
                return titleMatch || descMatch;
              }).toList();

        if (filteredReports.isEmpty) {
          return const Center(child: Text('No reports match your search'));
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
    );
  }
}
