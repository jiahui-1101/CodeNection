import 'package:flutter/material.dart';

class ReportUpdatePage extends StatefulWidget {
  const ReportUpdatePage({super.key});

  @override
  State<ReportUpdatePage> createState() => _ReportUpdatePageState();
}

class _ReportUpdatePageState extends State<ReportUpdatePage> {
  final List<Map<String, dynamic>> reportTypes = [
    {
      'title': 'Facility Issue',
      'icon': Icons.home_repair_service,
      'description': 'Report problems with campus facilities',
    },
    {
      'title': 'Safety Concern',
      'icon': Icons.security,
      'description': 'Report safety or security issues',
    },
    {
      'title': 'IT Problem',
      'icon': Icons.computer,
      'description': 'Report technology or network issues',
    },
    {
      'title': 'Maintenance Request',
      'icon': Icons.construction,
      'description': 'Request maintenance services',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submit a Report',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: reportTypes.length,
                itemBuilder: (context, index) {
                  final reportType = reportTypes[index];
                  return Card(
                    child: InkWell(
                      onTap: () {
                        // Navigate to report form
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(reportType['icon'], size: 40, color: Theme.of(context).primaryColor),
                            const SizedBox(height: 12),
                            Text(
                              reportType['title'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              reportType['description'],
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recent Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.report, color: Colors.blue),
                    title: Text('Broken Chair in Library - Submitted 2 days ago'),
                    subtitle: Text('Status: In Progress'),
                  ),
                  ListTile(
                    leading: Icon(Icons.report, color: Colors.green),
                    title: Text('WiFi Issue in Dormitory - Submitted 5 days ago'),
                    subtitle: Text('Status: Resolved'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}