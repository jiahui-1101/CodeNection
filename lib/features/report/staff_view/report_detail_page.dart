import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/report_model.dart';
import '../widgets/report_management/report_detail/report_info_card.dart';
import '../widgets/report_management/report_detail/update_action_cards.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status; 
    _feedbackController =
        TextEditingController(text: widget.report.feedback ?? '');
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges(BuildContext context) async {
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update report: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.report.title),
        backgroundColor: const Color(0xFF8EB9D4),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            _firestore.collection('reports').doc(widget.report.id).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final report = Report.fromFirestore(snapshot.data!, null);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReportInfoCard(report: report),
                const SizedBox(height: 20),
                UpdateActionCards(
                  selectedStatus: _selectedStatus,
                  feedbackController: _feedbackController,
                  onStatusChanged: (ReportStatus? newStatus) {
                    if (newStatus != null) {
                      setState(() => _selectedStatus = newStatus);
                    }
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 16),
                  ),
                  onPressed: () => _saveChanges(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8EB9D4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
