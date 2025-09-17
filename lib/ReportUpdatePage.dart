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
        backgroundColor: const Color(0xFF8EB9D4), // Consistent AppBar color
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: kToolbarHeight * 0.8, // Make AppBar a bit smaller
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === All Recent Reports (占大部分空间) ===
            Row(
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
                      MaterialPageRoute(
                        builder: (_) => const AllReportsListPage(), // 跳转到所有报告列表页
                      ),
                    );
                  },
                  child: const Text(
                    'View All Reports →',
                    style: TextStyle(color: Color(0xFF8EB9D4)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              flex: 3, // 占大部分空间
              child: StreamBuilder<QuerySnapshot<Report>>(
                stream: _firestore
                    .collection('reports')
                    .withConverter<Report>(
                      fromFirestore: Report.fromFirestore,
                      toFirestore: (Report report, _) => report.toFirestore(),
                    )
                    .orderBy('timestamp', descending: true)
                    .limit(5) // 只显示最近的5个报告
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('Error fetching recent reports: ${snapshot.error}');
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final reports =
                      snapshot.data?.docs.map((doc) => doc.data()).toList() ??
                          [];

                  if (reports.isEmpty) {
                    return const Center(child: Text('No recent reports found'));
                  }

                  return ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return ReportListItem(report: report); // Re-using ReportListItem
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 24), // 分隔符

            // === Report Categories (占小部分空间) ===
            const Text(
              'Report Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // 标题小一点
            ),
            const SizedBox(height: 10),

            Expanded(
              flex: 1, // 占小部分空间
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 分类改为3列，使每个卡片更小巧
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9, // 调整纵横比
                ),
                itemCount: reportTypes.length,
                itemBuilder: (context, index) {
                  final reportType = reportTypes[index];
                  return Card(
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
                                size: 30, // 图标小一点
                                color: Theme.of(context).primaryColor),
                            const SizedBox(height: 8), // 间距小一点
                            Text(
                              reportType['title'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13), // 字体小一点
                              textAlign: TextAlign.center,
                            ),
                            // description 可以省略或字体更小，以节省空间
                            // const SizedBox(height: 4),
                            // Text(
                            //   reportType['description'],
                            //   style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            //   textAlign: TextAlign.center,
                            // ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
        backgroundColor: const Color(0xFF8EB9D4), // Consistent AppBar color
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: kToolbarHeight * 0.8, // Make AppBar a bit smaller
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
            print('Error fetching category reports: ${snapshot.error}');
            return Center(child: Text('Error loading reports'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports =
              snapshot.data?.docs.map((doc) => doc.data()).toList() ?? [];

          if (reports.isEmpty) {
            return Center(child: Text('No reports found in "$category" category'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return ReportListItem(report: report); // Re-using ReportListItem
            },
          );
        },
      ),
    );
  }
}

