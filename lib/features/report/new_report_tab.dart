// lib/features/report/new_report_tab.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart'; // ✅ 1. 导入 Firebase Storage
import '../../../models/report_model.dart';

class NewReportTab extends StatefulWidget {
  const NewReportTab({super.key});

  @override
  State<NewReportTab> createState() => _NewReportTabState();
}

class _NewReportTabState extends State<NewReportTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();

  File? _selectedAttachmentFile;
  String? _selectedAttachmentFileName;
  bool _isPickingAttachment = false;
  String? _selectedCategory;
  String? _selectedDepartment;
  bool _isUploading = false; // ✅ 2. 新增状态来跟踪上传进度

  final Map<String, String> _categoryToDepartmentMap = {
    'Damage': 'Maintenance Department',
    'Security Threat': 'Campus Security',
    'Cleanliness': 'Facilities Management',
    'Blocked Pathway': 'Facilities Management',
    'IT Problem': 'IT Support',
    'Academic Related': 'Academic Affairs Office',
    'Student Services': 'Student Affairs Office',
    'Others': 'General Administration',
  };

  List<String> get _categories => _categoryToDepartmentMap.keys.toList();

  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? 'anonymous_user';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    if (_isPickingAttachment) return;
    setState(() => _isPickingAttachment = true);

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (mounted && result != null && result.files.single.path != null) {
        setState(() {
          _selectedAttachmentFile = File(result.files.single.path!);
          _selectedAttachmentFileName = result.files.single.name;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingAttachment = false);
      }
    }
  }

  // ✅ 3. 重构整个 _submitReport 方法
  Future<void> _submitReport() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isUploading) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a complaint category.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      _isUploading = true; // 开始上传，显示加载动画
    });

    try {
      String? attachmentUrl;
      String? attachmentFileName = _selectedAttachmentFileName;

      // 如果用户选择了附件，就上传它
      if (_selectedAttachmentFile != null && attachmentFileName != null) {
        // 创建一个独一无二的文件路径，避免重名
        final String filePath = 'report_attachments/$_currentUserId/${DateTime.now().millisecondsSinceEpoch}_$attachmentFileName';
        final ref = FirebaseStorage.instance.ref().child(filePath);
        final uploadTask = ref.putFile(_selectedAttachmentFile!);
        
        // 等待上传完成
        final snapshot = await uploadTask.whenComplete(() {});
        // 获取下载链接
        attachmentUrl = await snapshot.ref.getDownloadURL();
      }

      _selectedDepartment = _categoryToDepartmentMap[_selectedCategory!];
      final now = DateTime.now();
      
      final newReport = Report(
        id: '',
        userId: _currentUserId,
        title: _titleController.text.trim(),
        category: _selectedCategory!,
        department: _selectedDepartment!,
        description: _descriptionController.text.trim(),
        contact: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
        attachmentUrl: attachmentUrl, // 使用上传后获取到的 URL
        attachmentFileName: attachmentFileName, // 使用原始文件名
        timestamp: now,
        lastUpdateTimestamp: now,
        status: ReportStatus.submitted,
      );

      await FirebaseFirestore.instance.collection('reports').add(newReport.toFirestore());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Thank you! Your report has been submitted."),
        backgroundColor: Colors.green,
      ));

      _formKey.currentState?.reset();
      _titleController.clear();
      _descriptionController.clear();
      _contactController.clear();
      setState(() {
        _selectedAttachmentFile = null;
        _selectedAttachmentFileName = null;
        _selectedCategory = null;
        _selectedDepartment = null;
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to submit report: $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false; // 无论成功或失败，都结束加载状态
        });
      }
    }
  }

  Widget _buildAttachmentPreview(File file, String fileName) {
    final String extension = path.extension(fileName).toLowerCase();
    final bool isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);

    if (isImage) {
      return Image.file(file, fit: BoxFit.cover);
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
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... (其他 TextFormField 保持不变)
            _buildSectionTitle("Report Details"),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title", prefixIcon: Icon(Icons.title), border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Title cannot be empty.' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Complaint Category', prefixIcon: Icon(Icons.category_outlined), border: OutlineInputBorder()),
              hint: const Text('Choose category'),
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() {
                _selectedCategory = val;
                _selectedDepartment = _categoryToDepartmentMap[val];
              }),
              validator: (v) => v == null ? 'Please choose a category.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: ValueKey(_selectedDepartment),
              readOnly: true,
              initialValue: _selectedDepartment ?? 'Choose category first',
              decoration: const InputDecoration(labelText: 'Assigned Department', prefixIcon: Icon(Icons.groups_outlined), border: OutlineInputBorder(), filled: true, fillColor: Color.fromARGB(255, 235, 235, 235)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: "Description", hintText: "Please describe the issue.", border: OutlineInputBorder(), alignLabelWithHint: true),
              validator: (v) => v == null || v.trim().isEmpty ? 'Description cannot be empty.' : null,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle("Contact & Attachments"),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: "Email or Phone No. (Optional)", prefixIcon: Icon(Icons.contact_mail_outlined), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickAttachment,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8), color: Colors.grey.shade100),
                child: _selectedAttachmentFile == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.attachment, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Tap to select an attachment"),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: _buildAttachmentPreview(_selectedAttachmentFile!, _selectedAttachmentFileName!),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // ✅ 4. 更新提交按钮，以反映上传状态
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _submitReport, // 上传时禁用按钮
              icon: _isUploading ? Container() : const Icon(Icons.send), // 上传时不显示图标
              label: _isUploading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    )
                  : const Text("Submit Report", style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8EB9D4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}