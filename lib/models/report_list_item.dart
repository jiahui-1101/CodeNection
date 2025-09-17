// lib/widgets/report_list_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/report_model.dart'; // ✅ 确保这里导入了 ReportStatusExtension 和 Report
import '../pages/report_detail_page.dart'; // 导入 ReportDetailPage

class ReportListItem extends StatelessWidget {
  final Report report;
  const ReportListItem({super.key, required this.report});

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.submitted:
        return Colors.blue.shade700;
      case ReportStatus.inProgress:
        return Colors.orange.shade700;
      case ReportStatus.completed:
        return Colors.green.shade700;
      case ReportStatus.rejected:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportDetailPage(report: report), // ✅ 直接传递 Report 对象
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(report.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      report.status.capitalize(), // 使用 capitalize() 方法
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Category: ${report.category} | Dept: ${report.department}",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                "Submitted: ${DateFormat('yyyy-MM-dd HH:mm').format(report.timestamp)}",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}