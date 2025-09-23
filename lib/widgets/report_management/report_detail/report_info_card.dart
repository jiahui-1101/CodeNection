import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/report_model.dart';
import 'attachment_display.dart';

class ReportInfoCard extends StatelessWidget { 
  final Report report;                          //report management page li report detail page li top de report card
  const ReportInfoCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.isUrgent && report.status == ReportStatus.submitted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red.shade700,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "URGENT ATTENTION REQUIRED",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoTile("Complaint Type", report.category),
                _infoTile("Department", report.department),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Title: ",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Expanded(
                        child: Text(report.title, style: const TextStyle(fontSize: 15)),
                      ),
                     
                      if (report.isUrgent && report.status == ReportStatus.submitted)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.local_fire_department, color: Colors.red.shade600, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "URGENT",
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
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
        ],
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