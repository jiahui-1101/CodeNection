// lib/pages/report_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

import '../models/report_model.dart'; // Report, ReportStatus, ReportStatusExtension

class ReportDetailPage extends StatefulWidget {
  final Report report;
  const ReportDetailPage({super.key, required this.report});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  late ReportStatus _selectedStatus;
  late TextEditingController _feedbackController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ 初次同步标记，避免每次 StreamBuilder rebuild 覆盖用户选择
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
    _feedbackController = TextEditingController(text: widget.report.feedback ?? '');
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Widget _buildAttachmentDisplay(String attachmentUrl, String attachmentFileName) {
    final String extension = path.extension(attachmentFileName).toLowerCase();
    final bool isImage =
        ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);
    final bool isVideo =
        ['.mp4', '.mov', '.avi', '.wmv'].contains(extension);

    if (isImage) {
      return Image.network(
        attachmentUrl,
        fit: BoxFit.cover,
        loadingBuilder:
            (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
        ),
      );
    } else if (isVideo) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, size: 50, color: Colors.grey),
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

  Future<void> _saveChanges() async {
    try {
      await _firestore.collection('reports').doc(widget.report.id).update({
        'status': _selectedStatus.name,
        'feedback': _feedbackController.text.trim(),
        'lastUpdateTimestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Report updated successfully!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error updating report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to update report: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Report>>(
      stream: _firestore
          .collection('reports')
          .doc(widget.report.id)
          .withConverter<Report>(
            fromFirestore: Report.fromFirestore,
            toFirestore: (Report report, _) => report.toFirestore(),
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.report.title),
              backgroundColor: const Color(0xFF8EB9D4),
              foregroundColor: Colors.white,
              toolbarHeight: kToolbarHeight * 0.8,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Report Not Found'),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              toolbarHeight: kToolbarHeight * 0.8,
            ),
            body: const Center(child: Text('This report no longer exists.')),
          );
        }

        final currentReport = snapshot.data!.data()!;

        // ✅ 只在第一次加载时初始化状态和反馈
        if (!_initialized) {
          _selectedStatus = currentReport.status;
          _feedbackController.text = currentReport.feedback ?? '';
          _initialized = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(currentReport.title),
            backgroundColor: const Color(0xFF8EB9D4),
            foregroundColor: Colors.white,
            centerTitle: true,
            toolbarHeight: kToolbarHeight * 0.8,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === Report Info Card ===
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoTile("Complaint Type", currentReport.category),
                        _infoTile("Department", currentReport.department),
                        _infoTile("Title", currentReport.title),
                        _infoTile("Description", currentReport.description),
                        _infoTile("Contact", currentReport.contact),
                        _infoTile(
                            "Submitted At",
                            DateFormat('yyyy-MM-dd HH:mm')
                                .format(currentReport.timestamp)),
                        _infoTile(
                            "Last Update",
                            DateFormat('yyyy-MM-dd HH:mm')
                                .format(currentReport.lastUpdateTimestamp)),
                        if (currentReport.attachmentUrl != null &&
                            currentReport.attachmentUrl!.isNotEmpty &&
                            currentReport.attachmentFileName != null &&
                            currentReport.attachmentFileName!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              const Text('Attachment:',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 150,
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: _buildAttachmentDisplay(
                                      currentReport.attachmentUrl!,
                                      currentReport.attachmentFileName!),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // === Update Status Card ===
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Update Status",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ReportStatus>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 10.0),
                            isDense: true,
                          ),
                          items: ReportStatus.values.map((s) {
                            return DropdownMenuItem<ReportStatus>(
                              value: s,
                              child: Text(s.capitalize()),
                            );
                          }).toList(),
                          onChanged: (newStatus) {
                            if (newStatus != null) {
                              setState(() => _selectedStatus = newStatus);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // === Feedback Card ===
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Feedback",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _feedbackController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: "Enter feedback for the user...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // === Save Button ===
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text("Save Changes",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8EB9D4),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoTile(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value?.toString() ?? '-', softWrap: true)),
        ],
      ),
    );
  }
}
