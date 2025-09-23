import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/report_model.dart';
import '../../models/report_list_item.dart';
import '../../pages/all_report_list.dart';

class RecentReportsSection extends StatelessWidget { // A widget of report update page (upper section)to display recent reports title,show 3 latest reports in this section and "view all" button
  const RecentReportsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //Recent Reports Header(bare title and view all button)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 196, 198, 200),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color.fromARGB(255, 129, 131, 133)),
                ),
                child: const Text(
                  'Recent Reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
        const SizedBox(height: 8),

        //Recent Reports List ,display only 3 latest reports with status "submitted"
        StreamBuilder<QuerySnapshot<Report>>(
          stream: FirebaseFirestore.instance
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
              return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No recent submitted reports found'),
                  )
              );
            }

            final reports = snapshot.data!.docs.map((doc) => doc.data()).toList();

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
      ],
    );
  }
}