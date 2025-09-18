import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/report_model.dart';
import 'attachment_display.dart';

class ReportInfoCard extends StatelessWidget { //card to display detailed information of a report in report detail page for staff view
  final Report report;
  const ReportInfoCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoTile("Complaint Type", report.category),
            _infoTile("Department", report.department),
            _infoTile("Title", report.title),
            _infoTile("Description", report.description),
            _infoTile("Contact", report.contact ?? '-'),
            _infoTile("Submitted At", DateFormat('yyyy-MM-dd HH:mm').format(report.timestamp)),
            _infoTile("Last Update", DateFormat('yyyy-MM-dd HH:mm').format(report.lastUpdateTimestamp)),
            if (report.attachmentUrl != null && report.attachmentFileName != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text('Attachment:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: AttachmentDisplay(
                        attachmentUrl: report.attachmentUrl!,
                        attachmentFileName: report.attachmentFileName!,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}