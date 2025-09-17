import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_types.dart'; // Common report types
import '../models/report_model.dart'; // Import Report, ReportStatus, ReportStatusExtension
import '../pages/all_report_list.dart'; // Import the new AllReportsListPage
import '../models/report_list_item.dart'; // Import ReportListItem 

class ReportUpdatePage extends StatefulWidget {
  const ReportUpdatePage({super.key});

  @override
  State<ReportUpdatePage> createState() => _ReportUpdatePageState();
}

class _ReportUpdatePageState extends State<ReportUpdatePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Management"),
        backgroundColor: const Color(0xFF8EB9D4), 
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: kToolbarHeight * 0.8, 
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

             // Recent Reports Header
Padding(
  padding: const EdgeInsets.symmetric(vertical: 4.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Recent Reports',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AllReportsListPage()),
          );
        },
        child: const Text(
          'View All Reports →',
          style: TextStyle(color: Color(0xFF8EB9D4)),
        ),
      ),
    ],
  ),
),

// Recent Reports List
StreamBuilder<QuerySnapshot<Report>>(
  stream: _firestore
      .collection('reports')
      .where('status', isEqualTo: ReportStatus.submitted.name)
      .orderBy('timestamp', descending: true)
      .limit(3)
      .withConverter<Report>(
        fromFirestore: Report.fromFirestore,
        toFirestore: (Report report, _) => report.toFirestore(),
      )
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(child: Text('No recent submitted reports found'));
    }

    final reports =
        snapshot.data!.docs.map((doc) => doc.data()).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        return ReportListItem(report: reports[index]);
      },
    );
  },
),

              // === Report Categories Header ===
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F2FA), // 浅蓝背景
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF8EB9D4)),
                ),
                child: const Text(
                  'Report Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              // ✅ Categories
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), 
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: reportTypes.length,
                itemBuilder: (context, index) {
                  final reportType = reportTypes[index];
                  return Card(
                    color: const Color(0xFFE6F2FA), 
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportCategoryPage(
                              category: reportType['title'],
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(reportType['icon'],
                                size: 30,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(height: 8),
                            Text(
                              reportType['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// === ReportCategoryPage (管理员按类别查看报告) ===
class ReportCategoryPage extends StatelessWidget {
  final String category;
  const ReportCategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    return Scaffold(
      appBar: AppBar(
        title: Text('$category Reports'),
        backgroundColor: const Color(0xFF8EB9D4),
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: kToolbarHeight * 0.8,
      ),
      body: StreamBuilder<QuerySnapshot<Report>>(
        stream: firestore
            .collection('reports')
            .where('category', isEqualTo: category)
            .withConverter<Report>(
              fromFirestore: Report.fromFirestore,
              toFirestore: (Report report, _) => report.toFirestore(),
            )
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading reports'));
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
