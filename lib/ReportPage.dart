import 'dart:io';
// 新增 path 库用于获取文件名和扩展名
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
// image_picker 只能用于图片和视频，如果需要更多文件类型，需要使用 file_picker
import 'package:image_picker/image_picker.dart'; 
// ✅ 导入 file_picker 库
import 'package:file_picker/file_picker.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_storage/firebase_storage.dart';

// Enum for report statuses
enum ReportStatus {
  submitted,
  inProgress,
  completed,
  rejected,
}

// ✅ 新增一个扩展，用于方便地将字符串转换为 ReportStatus Enum
extension ReportStatusExtension on String {
  ReportStatus toReportStatus() {
    return ReportStatus.values.firstWhere(
      (e) => e.toString() == 'ReportStatus.$this',
      orElse: () => ReportStatus.submitted, // Default to submitted if not found
    );
  }
}

// Report Data Model
class Report {
  final String id;
  final String title;
  final String category;
  final String department;
  final String description;
  final String? contact;
  // ✅ 将 imageUrl 改为 attachmentUrl，并可以存储任何文件类型
  final String? attachmentUrl; 
  // ✅ (可选) 增加一个字段来存储附件的文件名，方便展示
  final String? attachmentFileName; 
  ReportStatus status; // Enum 类型
  final DateTime timestamp; // Submission timestamp
  DateTime lastUpdateTimestamp; // Last status update timestamp
  String? feedback;
  bool isUrgent; // New field to track if it's been marked urgent

  Report({
    required this.id,
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
    return Report(
      id: snapshot.id, // Firestore document ID
      title: data?['title'],
      category: data?['category'],
      department: data?['department'],
      description: data?['description'],
      contact: data?['contact'],
      attachmentUrl: data?['attachmentUrl'], // URL from Cloud Storage
      attachmentFileName: data?['attachmentFileName'], // File name
      status: (data?['status'] as String).toReportStatus(), // ✅ 将字符串转为 Enum
      timestamp: (data?['timestamp'] as Timestamp).toDate(), // ✅ 从 Timestamp 转为 DateTime
      lastUpdateTimestamp: (data?['lastUpdateTimestamp'] as Timestamp).toDate(), // ✅ 从 Timestamp 转为 DateTime
      feedback: data?['feedback'],
      isUrgent: data?['isUrgent'] ?? false,
    );
  }

  // ✅ 新增: 将 Report 对象转换为 Firestore 可存储的 Map
  Map<String, dynamic> toFirestore() {
    return {
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
  // ✅ 将 _selectedImage 改为 _selectedAttachmentFile
  File? _selectedAttachmentFile; 
  // ✅ 存储附件的文件名，用于显示
  String? _selectedAttachmentFileName; 
  bool _isPickingAttachment = false; // ✅ 更改状态变量名

  String? _selectedCategory;
  String? _selectedDepartment;

  final List<String> _categories = [
    'Damage',
    'Security Threat',
    'Cleanliness',
    'Blocked Pathway',
    'Others'
  ];
  final List<String> _departments = [
    'Maintenance',
    'Security Department',
    'General Office',
    'Student Affairs Department'
  ];

  // ImagePicker _picker = ImagePicker(); // ❌ 如果要选更多文件类型，ImagePicker 不够
  // ✅ 使用 FilePicker 来选择更多文件类型
  final FilePicker _filePicker = FilePicker.platform; 

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
  }

  // ✅ 附件上传到 Cloud Storage
  Future<String?> _uploadAttachmentToFirebaseStorage(File attachmentFile) async {
    try {
      // 存储路径可以保持 reports/ 文件夹，但文件名要更通用
      final String fileName = 'reports/${DateTime.now().millisecondsSinceEpoch}_${path.basename(attachmentFile.path)}';
      final Reference storageRef = _storage.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(attachmentFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('✅ 附件上传成功: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ 附件上传失败: $e');
      return null;
    }
  }

  // ✅ 修改为选择附件的方法
  Future<void> _pickAttachment() async {
    if (_isPickingAttachment) return;

    try {
      setState(() {
        _isPickingAttachment = true;
      });

      // ✅ 使用 file_picker 允许选择多种文件类型
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

      String? attachmentUrl;
      String? attachmentFileName;

      if (_selectedAttachmentFile != null) {
        // ✅ 上传附件到 Cloud Storage
        attachmentUrl = await _uploadAttachmentToFirebaseStorage(_selectedAttachmentFile!);
        attachmentFileName = _selectedAttachmentFileName; // 使用保存的文件名
        if (attachmentUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to upload attachment. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
          return; // 附件上传失败则不提交报告
        }
      }

      DateTime now = DateTime.now();
      // ✅ 创建 Report 对象，attachmentUrl 和 attachmentFileName 现在存储附件信息
      final newReport = Report(
        id: '', // ID 将由 Firestore 自动生成
        title: _titleController.text.trim(),
        category: _selectedCategory!,
        department: _selectedDepartment!,
        description: _descriptionController.text.trim(),
        contact: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        attachmentUrl: attachmentUrl, // ✅ 使用上传后的附件 URL
        attachmentFileName: attachmentFileName, // ✅ 使用附件文件名
        timestamp: now,
        lastUpdateTimestamp: now,
        status: ReportStatus.submitted,
        feedback: null, // 初始没有 feedback
      );

      try {
        // ✅ 将报告保存到 Firestore
        await _firestore.collection('reports').add(newReport.toFirestore());
        print('✅ 报告已成功提交到 Firestore！');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Thank you! Your report has been submitted. We will follow up ASAP."),
            backgroundColor: Colors.green,
          ),
        );

        // CLEAR ALL FIELD
        _formKey.currentState?.reset();
        _titleController.clear();
        _descriptionController.clear();
        _contactController.clear();
        setState(() {
          _selectedAttachmentFile = null; // ✅ 清除附件
          _selectedAttachmentFileName = null; // ✅ 清除文件名
          _selectedCategory = null; // Dropdown Button
          _selectedDepartment = null;
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
      // IF NOT VALID, SHOW ERROR MESSAGE
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete all required fields."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Callback function to handle urgency request
  void _requestUrgency(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'isUrgent': true,
        'feedback': 'Your request to urge for update has been received. We will address this report within 12 hours.Thank you for your patience.',
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
              // Disable horizontal scrolling for TabBarView
              physics: const NeverScrollableScrollPhysics(),
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
                                    contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
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
                                  value: _selectedCategory,
                                  isExpanded: true, // Crucial for preventing overflow
                                  decoration: const InputDecoration(
                                    labelText: 'Complaint Category',
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Icon(Icons.category_outlined),
                                    ),
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
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
                                    });
                                  },
                                  validator: (value) => value == null
                                      ? 'Choose complaint category.'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedDepartment,
                                  isExpanded: true, // Crucial for preventing overflow
                                  decoration: const InputDecoration(
                                    labelText: 'Department',
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Icon(Icons.groups_outlined),
                                    ),
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                                    isDense: true,
                                  ),
                                  hint: const Text('Choose department'),
                                  items: _departments.map((String department) {
                                    return DropdownMenuItem<String>(
                                      value: department,
                                      child: Text(
                                        department,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedDepartment = newValue;
                                    });
                                  },
                                  validator: (value) => value == null
                                      ? 'Choose related department.'
                                      : null,
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
                                    contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
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
                            contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                            isDense: true,
                          ),
                        ),
                        // ✅ 修改为 "Attachment Proof"
                        _buildSectionTitle("Attachment Proof"), 
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickAttachment, // ✅ 调用新的附件选择方法
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // ✅ 更通用附件图标
                                        Icon(Icons.attachment, 
                                            size: 40, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text("Tap here to select an attachment"), // ✅ 修改文本
                                      ],
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: _buildAttachmentPreview(
                                        _selectedAttachmentFile!, _selectedAttachmentFileName!), // ✅ 附件预览
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

                // ====== Second Tab: My Reports History ======
                StreamBuilder<QuerySnapshot<Report>>(
                  stream: _firestore.collection('reports')
                      .withConverter<Report>(
                        fromFirestore: Report.fromFirestore,
                        toFirestore: (Report report, options) => report.toFirestore(),
                      )
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final reports = snapshot.data?.docs.map((doc) => doc.data()).toList() ?? [];

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

  // ✅ 新增附件预览 widget
  Widget _buildAttachmentPreview(File file, String fileName) {
    // 检查文件扩展名，以判断是否为图片
    final String extension = path.extension(fileName).toLowerCase();
    final bool isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);

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
            const Icon(Icons.insert_drive_file, size: 50, color: Colors.grey), // 通用文件图标
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

// ReportCard Widget to display a single report history entry
class ReportCard extends StatelessWidget {
  final Report report;
  final Function(String)? onRequestUrgency; // Callback for urgency

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

  // ✅ 新增附件显示逻辑 (根据文件类型展示)
  Widget _buildAttachmentDisplay(String attachmentUrl, String attachmentFileName) {
    final String extension = path.extension(attachmentFileName).toLowerCase();
    final bool isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);
    final bool isVideo = ['.mp4', '.mov', '.avi', '.wmv'].contains(extension); // 假设也支持视频

    if (isImage) {
      return Image.network(
        attachmentUrl,
        fit: BoxFit.cover,
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
        ),
      );
    } else if (isVideo) {
      // 视频文件通常需要一个视频播放器，这里只是显示一个视频图标和文件名
      // 实际播放需要集成如 video_player 这样的库
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
      // 其他文件类型，例如 PDF, DOCX 等
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file, size: 50, color: Colors.grey), // 通用文件图标
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
            Text(
              "Submitted: ${report.timestamp.toLocal().toIso8601String().split('T')[0]} ${report.timestamp.toLocal().toIso8601String().split('T')[1].substring(0, 5)}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              "Last Update: ${report.lastUpdateTimestamp.toLocal().toIso8601String().split('T')[0]} ${report.lastUpdateTimestamp.toLocal().toIso8601String().split('T')[1].substring(0, 5)}",
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
            // ✅ 修改 ReportCard 中的附件显示逻辑
            if (report.attachmentUrl != null && report.attachmentUrl!.isNotEmpty && report.attachmentFileName != null)
              SizedBox(
                height: 150,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: _buildAttachmentDisplay(report.attachmentUrl!, report.attachmentFileName!),
                ),
              ),
            if (report.attachmentUrl != null && report.attachmentUrl!.isNotEmpty && report.attachmentFileName != null)
              const SizedBox(height: 12),

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
                  color: _getFeedbackBackgroundColor(report.status), // Dynamic background color
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(report.status).withOpacity(0.3)), // Subtle border
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
                  label: const Text("Urge for Update", style: TextStyle(color: Colors.white)),
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