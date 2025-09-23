import 'package:flutter/material.dart';
import '../features/report/new_report_tab.dart';
import '../features/report/myreport_histories_tab.dart';

class ReportPage extends StatelessWidget {  //user view punya report page,can create new report and view my report history
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF8EB9D4),
          foregroundColor: Colors.white,
    
          title: const TabBar(
            tabs: [
              Tab(text: "Create New Report", icon: Icon(Icons.note_add_outlined)),
              Tab(text: "My Reports", icon: Icon(Icons.history)),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3.0,
          ),
        ),
        body: const TabBarView(
          children: [
            // first tab - new report tab
            NewReportTab(),
            // second tab - my reports tab
            MyReportsTab(),
          ],
        ),
      ),
    );
  }
}