import 'package:flutter/material.dart';
import '../../../models/report_model.dart';

class UpdateActionCards extends StatelessWidget { //cards to update report status and provide feedback in report detail page for staff view
  final ReportStatus selectedStatus;
  final ValueChanged<ReportStatus?> onStatusChanged;
  final TextEditingController feedbackController;

  const UpdateActionCards({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.feedbackController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Update Status Card
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Update Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<ReportStatus>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: ReportStatus.values.map((s) {
                    return DropdownMenuItem<ReportStatus>(value: s, child: Text(s.capitalize()));
                  }).toList(),
                  onChanged: onStatusChanged,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Feedback Card
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Feedback", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: feedbackController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Enter feedback for the user...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}