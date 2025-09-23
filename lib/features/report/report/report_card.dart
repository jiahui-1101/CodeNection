import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../staff_view/models/report_model.dart';

class ReportCard extends StatelessWidget { //cards to display individual report details with status, progress, attachment, feedback, and urgency request,can implement in my repost history page(user) and all reports list page(staff view)
  final Report report;
  final Function(String) onRequestUrgency;

  const ReportCard({
    super.key,
    required this.report,
    required this.onRequestUrgency,
  });

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

  Color _getFeedbackBackgroundColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.completed:
        return Colors.green.shade50;
      case ReportStatus.inProgress:
        return Colors.orange.shade50;
      case ReportStatus.rejected:
        return Colors.red.shade50;
      case ReportStatus.submitted:
      default:
        return Colors.blue.shade50;
    }
  }

  double _getProgressValue(ReportStatus status) {
    switch (status) {
      case ReportStatus.submitted:
        return 0.33;
      case ReportStatus.inProgress:
        return 0.66;
      case ReportStatus.completed:
      case ReportStatus.rejected:
        return 1.0;
    }
  }

  Widget _buildAttachmentDisplay(String attachmentUrl, String attachmentFileName) {
    final String extension = path.extension(attachmentFileName).toLowerCase();
    final bool isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);
    
    if (isImage) {
      return Image.network(
        attachmentUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file, size: 50, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              attachmentFileName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const double runnerIconSize = 24.0;
    final bool canRequestUrgency = report.status == ReportStatus.submitted &&
        !report.isUrgent &&
        DateTime.now().difference(report.timestamp).inHours >= 24;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.status.capitalize(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Category: ${report.category}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              "Submitted: ${DateFormat('yyyy-MM-dd HH:mm').format(report.timestamp)}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
              Text(
              "Last Update: ${DateFormat('yyyy-MM-dd HH:mm').format(report.lastUpdateTimestamp)}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final progressTrackWidth = constraints.maxWidth;
                double runnerPosition = (progressTrackWidth - runnerIconSize) * _getProgressValue(report.status);
                
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    LinearProgressIndicator(
                      value: _getProgressValue(report.status),
                      backgroundColor: Colors.grey.shade300,
                      color: _getStatusColor(report.status),
                      minHeight: runnerIconSize,
                      borderRadius: BorderRadius.circular(runnerIconSize / 2),
                    ),
                    Positioned(
                      left: runnerPosition,
                      child: const Icon(Icons.directions_run, color: Colors.white, size: runnerIconSize),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            if (report.attachmentUrl != null && report.attachmentFileName != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Attachment:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: _buildAttachmentDisplay(report.attachmentUrl!, report.attachmentFileName!),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            Text(
              report.description,
              style: const TextStyle(fontSize: 15),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (report.feedback != null && report.feedback!.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getFeedbackBackgroundColor(report.status),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(report.status).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Staff Feedback:",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.feedback!,
                      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            if (canRequestUrgency)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: ElevatedButton.icon(
                  onPressed: () => onRequestUrgency(report.id),
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  label: const Text("Urge for Update", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            if (report.isUrgent)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Urgent request sent!',
                  style: TextStyle(color: Colors.red.shade700, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }
}