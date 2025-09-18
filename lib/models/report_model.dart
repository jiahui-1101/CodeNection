import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus {
  submitted,
  inProgress,
  completed,
  rejected,
}

extension ReportStatusExtension on ReportStatus {
  String capitalize() {
    switch (this) {
      case ReportStatus.inProgress:
        return 'In Progress';
      default:
        final name = this.name;
        return name[0].toUpperCase() + name.substring(1);
    }
  }

  static ReportStatus fromString(String statusStr) {
    return ReportStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == statusStr.toLowerCase(),
      orElse: () => ReportStatus.submitted,
    );
  }
}
class Report {
  final String id;
  final String userId; 
  final String title;
  final String category;
  final String department;
  final String description;
  final String? contact;
  final String? attachmentUrl;
  final String? attachmentFileName;
  final ReportStatus status;
  final DateTime timestamp;
  final DateTime lastUpdateTimestamp;
  final String? feedback;
  final bool isUrgent; 

  Report({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.department,
    required this.description,
    this.contact,
    this.attachmentUrl,
    this.attachmentFileName,
    required this.status,
    required this.timestamp,
    required this.lastUpdateTimestamp,
    this.feedback,
    this.isUrgent = false, 
  });

  factory Report.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for Report ID: ${snapshot.id}');
    }
    
    return Report(
      id: snapshot.id,
      userId: data['userId'] as String? ?? 'unknown_user',
      title: data['title'] as String? ?? '',
      category: data['category'] as String? ?? '',
      department: data['department'] as String? ?? '',
      description: data['description'] as String? ?? '',
      contact: data['contact'] as String?,
      attachmentUrl: data['attachmentUrl'] as String?,
      attachmentFileName: data['attachmentFileName'] as String?,
      status: ReportStatusExtension.fromString(data['status'] as String? ?? 'submitted'),
      timestamp: (data['timestamp'] as Timestamp? ?? Timestamp.now()).toDate(),
      lastUpdateTimestamp: (data['lastUpdateTimestamp'] as Timestamp? ?? data['timestamp'] as Timestamp? ?? Timestamp.now()).toDate(),
      feedback: data['feedback'] as String?,
      isUrgent: data['isUrgent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'department': department,
      'description': description,
      'contact': contact,
      'attachmentUrl': attachmentUrl,
      'attachmentFileName': attachmentFileName,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'lastUpdateTimestamp': Timestamp.fromDate(lastUpdateTimestamp),
      'feedback': feedback,
      'isUrgent': isUrgent,
    };
  }
}