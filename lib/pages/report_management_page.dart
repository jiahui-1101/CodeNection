import 'package:flutter/material.dart';
import '../widgets/report_management/recent_reports_section.dart';
import '../widgets/report_management/report_categories_grid.dart';

class ReportManagementPage extends StatelessWidget { //staff view punya report management page,can view all reports and edit status
  const ReportManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Management Dashboard"),
        backgroundColor: const Color(0xFF8EB9D4),
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: kToolbarHeight * 0.8,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // upper section show recent reports
              RecentReportsSection(),
              SizedBox(height: 16),
              // lower section show report categories
              ReportCategoriesGrid(),
            ],
          ),
        ),
      ),
    );
  }
}
