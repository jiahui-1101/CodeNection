import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // ✅ ImagePicker 不再直接使用
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // 注释掉 Firebase Storage 导入
import 'package:intl/intl.dart'; 
import 'package:firebase_auth/firebase_auth.dart';

// Enum for report statuses  ,zheg ge hai yao he report_model.dart compare yixia
enum ReportStatus {
  submitted,
  inProgress,
  completed,
  rejected,
}

// ✅ 新增一个扩展，用于方便地将字符串转换为 ReportStatus Enum
extension ReportStatusExtension on String {
  ReportStatus toReportStatus() {
    // 确保处理 'submitted' 这样的字符串
    // 转换为 'ReportStatus.submitted' 才能匹配 Enum value
    final String enumString = 'ReportStatus.${this[0].toLowerCase()}${substring(1)}'; // 转换为小驼峰
    return ReportStatus.values.firstWhere(
      (e) => e.toString() == enumString,
      orElse: () => ReportStatus.submitted, // Default to submitted if not found
    );
  }
}

// Report Data Model
class Report {
  final String id;
  final String userId; // ✅ 新增：记录提交报告的用户ID
  final String title;
  final String category; // E.g., "Facility Issue", "Safety Concern"
  final String department; // E.g., "Maintenance", "Security Department"
  final String description;
  final String? contact;
  final String? attachmentUrl; // Cloud Storage URL for attachment
  final String? attachmentFileName; // File name for display
  ReportStatus status; // Enum 类型
  final DateTime timestamp; // Submission timestamp
  DateTime lastUpdateTimestamp; // Last status update timestamp
  String? feedback;
  bool isUrgent; // New field to track if it's been marked urgent

  Report({
    required this.id,
    required this.userId, // ✅ 构造函数中也需要
    required this.title,
    required this.category,
    required this.department,
    required this.description,
    this.contact,
    this.attachmentUrl, // Cloud Storage URL for attachment
    this.attachmentFileName, // File name for display
    this.status = ReportStatus.submitted,
    required this.timestamp,
    required this.lastUpdateTimestamp,
    this.feedback,
    this.isUrgent = false,
  });

  // ✅ 新增: 从 Firestore DocumentSnapshot 创建 Report 对象
  factory Report.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for Report document with ID: ${snapshot.id}');
    }
    return Report(
      id: snapshot.id, // Firestore document ID
      userId: data['userId'] as String? ?? 'unknown_user', // ✅ 从 Firestore 获取用户ID
      title: data['title'] as String? ?? '', // 提供默认值以防万一
      category: data['category'] as String? ?? '',
      department: data['department'] as String? ?? '',
      description: data['description'] as String? ?? '',
      contact: data['contact'] as String?,
      attachmentUrl: data['attachmentUrl'] as String?, // URL from Cloud Storage
      attachmentFileName: data['attachmentFileName'] as String?, // File name
      status: (data['status'] as String? ?? 'submitted').toReportStatus(), // ✅ 将字符串转为 Enum
      timestamp: (data['timestamp'] as Timestamp? ?? Timestamp.now()).toDate(), // ✅ 从 Timestamp 转为 DateTime
      lastUpdateTimestamp: (data['lastUpdateTimestamp'] as Timestamp? ?? Timestamp.now()).toDate(), // ✅ 从 Timestamp 转为 DateTime
      feedback: data['feedback'] as String?,
      isUrgent: data['isUrgent'] as bool? ?? false,
    );
  }

  // ✅ 新增: 将 Report 对象转换为 Firestore 可存储的 Map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId, // ✅ 保存用户ID
      'title': title,
      'category': category,
      'department': department,
      'description': description,
      'contact': contact,
      'attachmentUrl': attachmentUrl, // URL
      'attachmentFileName': attachmentFileName, // File name
      'status': status.name, // ✅ 将 Enum 转为字符串存储
      'timestamp': Timestamp.fromDate(timestamp), // ✅ 将 DateTime 转为 Timestamp 存储
      'lastUpdateTimestamp': Timestamp.fromDate(lastUpdateTimestamp), // ✅ 将 DateTime 转为 Timestamp 存储
      'feedback': feedback,
      'isUrgent': isUrgent,
    };
  }

  // Helper method to create a copy with updated fields
  Report copyWith({
    ReportStatus? status,
    DateTime? lastUpdateTimestamp,
    String? feedback,
    bool? isUrgent,
    String? attachmentUrl, // ✅ 更新为 attachmentUrl
    String? attachmentFileName, // ✅ 更新为 attachmentFileName
  }) {
    return Report(
      id: id,
      userId: userId, // ✅ 复制时也保留用户ID
      title: title,
      category: category,
      department: department,
      description: description,
      contact: contact,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl, // ✅ 使用新的 attachmentUrl
      attachmentFileName: attachmentFileName ?? this.attachmentFileName, // ✅ 使用新的 attachmentFileName
      status: status ?? this.status,
      timestamp: timestamp,
      lastUpdateTimestamp: lastUpdateTimestamp ?? this.lastUpdateTimestamp,
      feedback: feedback ?? this.feedback,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();

  File? _selectedAttachmentFile;
  String? _selectedAttachmentFileName;
  bool _isPickingAttachment = false;

  String? _selectedCategory;
  String? _selectedDepartment; // 此字段现在将自动设置，用户不再直接选择

  // ✅ 修正和扩展投诉类别与部门的映射
  final Map<String, String> _categoryToDepartmentMap = {
    'Damage': 'Maintenance Department',
    'Security Threat': 'Campus Security',
    'Cleanliness': 'Facilities Management', // 假设清洁也属于设施管理
    'Blocked Pathway': 'Facilities Management',
    'IT Problem': 'IT Support', // 新增IT问题类别
    'Academic Related': 'Academic Affairs Office', // 新增学术相关
    'Student Services': 'Student Affairs Office', // 新增学生服务
    'Others': 'General Administration', // 其他问题
  };

  // 确保 _categories 列表包含所有映射的键
  List<String> get _categories => _categoryToDepartmentMap.keys.toList();

  final FilePicker _filePicker = FilePicker.platform;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ 占位符用户ID。在实际应用中，这应该从 Firebase Auth 或其他认证系统获取。
  // 例如：String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_user';
  // 这里暂时用一个固定的ID，方便测试。
  //final String _currentUserId = 'user_abc_123'; // 替换为真实的当前用户ID
String get _currentUserId {
  final user = FirebaseAuth.instance.currentUser;
  return user?.uid ?? 'anonymous_user'; // 如果没登录，就给一个默认值
}


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  // ✅ 修改为选择附件的方法 (保持你的原始逻辑，但已明确不上传)
  Future<void> _pickAttachment() async {
    if (_isPickingAttachment) return;

    try {
      setState(() {
        _isPickingAttachment = true;
      });

      final result = await _filePicker.pickFiles(
        type: FileType.any, // 允许任何文件类型
        allowMultiple: false, // 暂时只允许选择一个附件
      );

      if (mounted && result != null && result.files.single.path != null) {
        setState(() {
          _selectedAttachmentFile = File(result.files.single.path!);
          _selectedAttachmentFileName = result.files.single.name; // 保存文件名
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingAttachment = false;
        });
      }
    }
  }

  void _submitReport() async {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Submitting report..."),
          backgroundColor: Colors.blueAccent,
        ),
      );

      // 根据选择的类别自动设置部门
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a complaint category.')),
        );
        return;
      }
      _selectedDepartment = _categoryToDepartmentMap[_selectedCategory!];

      String? attachmentUrl; // 附件 URL 始终为 null，因为不上传
      String? attachmentFileName = _selectedAttachmentFileName; // 仍保留文件名

      if (_selectedAttachmentFile != null) {
        // 提示用户附件不会被上传
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Attachment selected, but not uploaded to Storage (feature disabled)."),
            backgroundColor: Colors.orange,
          ),
        );
      }

      DateTime now = DateTime.now();
      final newReport = Report(
        id: '', // ID 将由 Firestore 自动生成
        userId: _currentUserId, // ✅ 关联当前用户ID
        title: _titleController.text.trim(),
        category: _selectedCategory!,
        department: _selectedDepartment!, // ✅ 使用自动分配的部门
        description: _descriptionController.text.trim(),
        contact: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        attachmentUrl: attachmentUrl, // 现在总是为 null
        attachmentFileName: attachmentFileName,
        timestamp: now,
        lastUpdateTimestamp: now,
        status: ReportStatus.submitted,
        feedback: null,
      );

      try {
        await _firestore.collection('reports').add(newReport.toFirestore());
        print('✅ 报告已成功提交到 Firestore！');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Thank you! Your report has been submitted. We will follow up ASAP."),
            backgroundColor: Colors.green,
          ),
        );

        // CLEAR ALL FIELD
        _formKey.currentState?.reset();
        _titleController.clear();
        _descriptionController.clear();
        _contactController.clear();
        setState(() {
          _selectedAttachmentFile = null;
          _selectedAttachmentFileName = null;
          _selectedCategory = null;
          _selectedDepartment = null; // 重置部门显示
        });
      } catch (e) {
        print('❌ 提交报告到 Firestore 失败: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit report: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete all required fields."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _requestUrgency(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'isUrgent': true,
        'feedback':
            'Your request to urge for update has been received. We will address this report within 12 hours.Thank you for your patience.',
        'lastUpdateTimestamp': FieldValue.serverTimestamp(), // ✅ 使用服务器时间戳
      });
      print('✅ 报告 $reportId 的紧急状态已在 Firestore 更新！');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Request Urge Update for Report $reportId has been sent."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      print('❌ 更新报告 $reportId 紧急状态失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to urge for update: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two Tabs: Submit Report and Report History
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF8EB9D4),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight * 0.75),
            child: const TabBar(
              tabs: [
                Tab(
                  text: "New Report",
                  icon: Icon(Icons.note_add_outlined),
                  iconMargin: EdgeInsets.only(bottom: 2.0),
                ),
                Tab(
                  text: "My Reports",
                  icon: Icon(Icons.history),
                  iconMargin: EdgeInsets.only(bottom: 2.0),
                ),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
            ),
          ),
          toolbarHeight: kToolbarHeight * 0.75,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0), // Overall outer padding
          child: Card(
            elevation: 6,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(), // Disable horizontal scrolling
              children: [
                // ====== First Tab: Submit New Report Form ======
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle("Report Details"),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: "Title",
                                    prefixIcon: Icon(Icons.title),
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 12.0, horizontal: 10.0),
                                    isDense: true,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Title cannot be empty.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedCategory,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Complaint Category',
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Icon(Icons.category_outlined),
                                    ),
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 12.0, horizontal: 10.0),
                                    isDense: true,
                                  ),
                                  hint: const Text('Choose category'),
                                  items: _categories.map((String category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(
                                        category,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedCategory = newValue;
                                      // 自动设置部门
                                      _selectedDepartment =
                                          _categoryToDepartmentMap[newValue];
                                    });
                                  },
                                  validator: (value) => value == null
                                      ? 'Choose complaint category.'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                // ✅ 将部门选择器改为只读文本字段，显示自动分配的部门
                                TextFormField(
                                  readOnly: true,
                                  controller: TextEditingController(
                                      text: _selectedDepartment ??
                                          'Select a category first'), // 显示自动分配的部门
                                  decoration: const InputDecoration(
                                    labelText: 'Assigned Department',
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Icon(Icons.groups_outlined),
                                    ),
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 12.0, horizontal: 10.0),
                                    isDense: true,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 5,
                                  decoration: const InputDecoration(
                                    labelText: "Description",
                                    hintText: "Please describe the issue.",
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 12.0, horizontal: 10.0),
                                    isDense: true,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Description cannot be empty';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _contactController,
                          decoration: const InputDecoration(
                            labelText: "Email or Phone No. (Optional)",
                            prefixIcon: Icon(Icons.contact_mail_outlined),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 10.0),
                            isDense: true,
                          ),
                        ),
                        _buildSectionTitle("Attachment Proof (Not Uploaded)"), // ✅ 修改提示文本
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickAttachment,
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade100,
                            ),
                            child: _selectedAttachmentFile == null
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.attachment,
                                            size: 40, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text("Tap here to select an attachment (for local preview only)"), // ✅ 修改文本
                                      ],
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: _buildAttachmentPreview(
                                        _selectedAttachmentFile!,
                                        _selectedAttachmentFileName!),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _submitReport,
                          icon: const Icon(Icons.send),
                          label: const Text("Submit Report",
                              style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8EB9D4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ====== Second Tab: My Reports History (只显示当前用户的报告) ======
                StreamBuilder<QuerySnapshot<Report>>(
                  stream: _firestore
                      .collection('reports')
                      .where('userId', isEqualTo: _currentUserId) // ✅ 关键：按用户ID过滤
                      .withConverter<Report>(
                        fromFirestore: Report.fromFirestore,
                        toFirestore: (Report report, options) =>
                            report.toFirestore(),
                      )
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      print('Error fetching user reports: ${snapshot.error}'); // 打印错误以便调试
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final reports =
                        snapshot.data?.docs.map((doc) => doc.data()).toList() ??
                            [];

                    if (reports.isEmpty) {
                      return const Center(
                        child: Text(
                          "You haven't submitted any reports yet.",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        return ReportCard(
                          report: report,
                          onRequestUrgency: _requestUrgency,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ 附件预览 widget (保持你的原始逻辑)
  Widget _buildAttachmentPreview(File file, String fileName) {
    final String extension = path.extension(fileName).toLowerCase();
    final bool isImage =
        ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);

    if (isImage) {
      return Image.file(
        file,
        fit: BoxFit.cover,
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file, size: 50, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              fileName,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }
}

// ReportCard Widget to display a single report history entry (保持你的原始逻辑，除了我修复了const的问题)
class ReportCard extends StatelessWidget {
  final Report report;
  final Function(String)? onRequestUrgency; // Callback for urgency

  // ✅ 修正：移除 const 关键字，因为 report 是运行时创建的非const对象
  const ReportCard({
    super.key,
    required this.report,
    this.onRequestUrgency,
  });

  // Get color based on status
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

  // Get color for feedback background
  Color _getFeedbackBackgroundColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.completed:
        return Colors.green.shade50; // Lighter green for completed
      case ReportStatus.inProgress:
        return Colors.orange.shade50; // Lighter orange for in progress
      case ReportStatus.rejected:
        return Colors.red.shade50; // Lighter red for rejected
      case ReportStatus.submitted:
      default:
        return Colors.blue.shade50; // Default for submitted or other states
    }
  }

  // Get progress value based on status (0.0 - 1.0)
  double _getProgressValue(ReportStatus status) {
    switch (status) {
      case ReportStatus.submitted:
        return 0.33;
      case ReportStatus.inProgress:
        return 0.66;
      case ReportStatus.completed:
        return 1.0;
      case ReportStatus.rejected:
        return 1.0;
    }
  }

  // Get status text
  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.submitted:
        return 'Submitted';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.completed:
        return 'Completed';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  // ✅ 附件显示逻辑 (根据文件类型展示) - 保持你的原始逻辑
  Widget _buildAttachmentDisplay(
      String attachmentUrl, String attachmentFileName) {
    final String extension = path.extension(attachmentFileName).toLowerCase();
    final bool isImage =
        ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);
    final bool isVideo =
        ['.mp4', '.mov', '.avi', '.wmv'].contains(extension); // 假设也支持视频

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

  @override
  Widget build(BuildContext context) {
    const double runnerIconSize = 24.0;
    final bool canRequestUrgency = report.status == ReportStatus.submitted &&
        !report.isUrgent && // Only if not already marked urgent
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
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
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
                    _getStatusText(report.status),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Category: ${report.category} | Department: ${report.department}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            // 使用 intl 包来格式化日期，使其更易读
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
                double movableWidth = progressTrackWidth - runnerIconSize;
                if (movableWidth < 0) movableWidth = 0;

                double runnerPosition = movableWidth * _getProgressValue(report.status);
                
                if (runnerPosition > movableWidth) {
                  runnerPosition = movableWidth;
                }
                if (runnerPosition < 0) {
                  runnerPosition = 0;
                }

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
                      child: Icon(
                        Icons.directions_run,
                        color: Colors.white,
                        size: runnerIconSize,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            // 只有当 attachmentUrl 和 attachmentFileName 都存在时才显示附件
            if (report.attachmentUrl != null &&
                report.attachmentUrl!.isNotEmpty &&
                report.attachmentFileName != null && report.attachmentFileName!.isNotEmpty)
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
                      child: _buildAttachmentDisplay(
                          report.attachmentUrl!, report.attachmentFileName!),
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
            // Display feedback if available and not null/empty, regardless of 'completed' status
            if (report.feedback != null && report.feedback!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      _getFeedbackBackgroundColor(report.status), // Dynamic background color
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _getStatusColor(report.status).withOpacity(0.3)), // Subtle border
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Staff Feedback:",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.feedback!,
                      style: const TextStyle(
                          fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            if (canRequestUrgency && onRequestUrgency != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: ElevatedButton.icon(
                  onPressed: () => onRequestUrgency!(report.id),
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  label: const Text("Urge for Update",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            if (report.isUrgent)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Urgent request sent!',
                  style: TextStyle(
                      color: Colors.red.shade700, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }
}