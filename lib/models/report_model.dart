// lib/models/report_model.dart (正确版本)
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. 定义 ReportStatus 枚举
enum ReportStatus {
  submitted,
  inProgress,
  completed,
  rejected,
}

// 2. 定义 ReportStatus 的扩展方法
// ✅ 确保这个扩展是针对 ReportStatus 的
extension ReportStatusExtension on ReportStatus {
  String capitalize() {
    switch (this) {
      case ReportStatus.submitted:
        return 'Submitted';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.completed:
        return 'Completed';
      case ReportStatus.rejected:
        return 'Rejected';
      default:
        // 如果你需要，也可以添加一个处理 ReportStatus.name 的逻辑
        // 但对于这个具体的枚举，switch 语句已经覆盖所有情况
        return name; // Fallback for any unexpected cases
    }
  }
}

// 3. 定义 Report 模型类 (保持不变)
class Report {
  final String id;
  final String title;
  final String description;
  final String category;
  final String department;
  final String contact;
  final DateTime timestamp;
  final String? attachmentUrl;
  final String? attachmentFileName;
  final ReportStatus status;
  final String? feedback;
  final DateTime lastUpdateTimestamp;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.department,
    required this.contact,
    required this.timestamp,
    this.attachmentUrl,
    this.attachmentFileName,
    this.status = ReportStatus.submitted, // 默认状态
    this.feedback,
    required this.lastUpdateTimestamp,
  });

  factory Report.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    return Report(
      id: snapshot.id,
      title: data?['title'] as String,
      description: data?['description'] as String,
      category: data?['category'] as String,
      department: data?['department'] as String,
      contact: data?['contact'] as String,
      timestamp: (data?['timestamp'] as Timestamp).toDate(),
      attachmentUrl: data?['attachmentUrl'] as String?,
      attachmentFileName: data?['attachmentFileName'] as String?,
      status: ReportStatus.values.firstWhere(
            (e) => e.name == data?['status'],
        orElse: () => ReportStatus.submitted,
      ),
      feedback: data?['feedback'] as String?,
      lastUpdateTimestamp: (data?['lastUpdateTimestamp'] as Timestamp? ??
          data?['timestamp'] as Timestamp)
          .toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'department': department,
      'contact': contact,
      'timestamp': timestamp,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (attachmentFileName != null) 'attachmentFileName': attachmentFileName,
      'status': status.name,
      if (feedback != null) 'feedback': feedback,
      'lastUpdateTimestamp': lastUpdateTimestamp,
    };
  }
}