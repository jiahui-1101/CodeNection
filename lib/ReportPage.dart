import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Enum for report statuses
enum ReportStatus {
  submitted,
  inProgress,
  completed,
  rejected,
}

// Mock Report Data Model
class MockReport {
  final String id;
  final String title;
  final String category;
  final String department;
  final String description;
  final String? contact;
  final String? imageUrl;
  ReportStatus status;
  final DateTime timestamp; // Submission timestamp
  DateTime lastUpdateTimestamp; // Last status update timestamp
  String? feedback;
  bool isUrgent; // New field to track if it's been marked urgent

  MockReport({
    required this.id,
    required this.title,
    required this.category,
    required this.department,
    required this.description,
    this.contact,
    this.imageUrl,
    this.status = ReportStatus.submitted,
    required this.timestamp,
    required this.lastUpdateTimestamp, // Initialize this
    this.feedback,
    this.isUrgent = false, // Default to false
  });

  // Helper method to create a copy with updated fields
  MockReport copyWith({
    ReportStatus? status,
    DateTime? lastUpdateTimestamp,
    String? feedback,
    bool? isUrgent,
  }) {
    return MockReport(
      id: id,
      title: title,
      category: category,
      department: department,
      description: description,
      contact: contact,
      imageUrl: imageUrl,
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
  File? _selectedImage;
  bool _isPickingImage = false;

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

  final ImagePicker _picker = ImagePicker();

  final List<MockReport> _reportHistory = []; // Initialize empty

  // Counter for generating unique IDs and simulating statuses
  int _reportCounter = 0;

  @override
  void initState() {
    super.initState();
    _initializeMockReports(); // Call to add preset reports on init
  }

  void _initializeMockReports() {
    // Add preset reports, ensure lastUpdateTimestamp is set
    _reportHistory.add(
      MockReport(
        id: 'report_001',
        title: 'Canteen Light Malfunction',
        category: 'Damage',
        department: 'Maintenance',
        description:
            'Several lights in the canteen area are not working, affecting the dining environment.',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        lastUpdateTimestamp: DateTime.now().subtract(const Duration(days: 4, hours: 12)),
        status: ReportStatus.completed,
        feedback:
            'Electricians have been arranged for repair, all lights are now working normally.',
      ),
    );
    _reportHistory.add(
      MockReport(
        id: 'report_002',
        title: 'Unpleasant Odor in Restroom',
        category: 'Cleanliness',
        department: 'General Office',
        description:
            'The male restroom on the second floor has had a persistent unpleasant odor for a long time. Please enhance cleaning efforts.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        lastUpdateTimestamp: DateTime.now().subtract(const Duration(days: 1, hours: 20)),
        status: ReportStatus.inProgress,
        feedback:
            'Cleaning department has received feedback and is arranging deep cleaning and ventilation system check.',
      ),
    );
    _reportHistory.add(
      MockReport(
        id: 'report_003',
        title: 'Excessive Noise in Library',
        category: 'Others',
        department: 'Student Affairs Department',
        description:
            'Some people are being loud in the library study area, disturbing others.',
        timestamp: DateTime.now().subtract(const Duration(hours: 30)), // More than 24 hours ago
        lastUpdateTimestamp: DateTime.now().subtract(const Duration(hours: 30)),
        status: ReportStatus.submitted,
        feedback: null,
      ),
    );

    // Sort the history by submission timestamp (newest first)
    _reportHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _reportCounter = _reportHistory.length;
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    try {
      setState(() {
        _isPickingImage = true;
      });

      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (mounted && pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  void _submitReport() {
    if (_formKey.currentState?.validate() ?? false) {
      // Generate mock report and alternate statuses and feedback
      _reportCounter++;
      ReportStatus simulatedStatus = ReportStatus.submitted;
      String? simulatedFeedback;
      DateTime now = DateTime.now();

      final newReport = MockReport(
        id: 'report_$_reportCounter',
        title: _titleController.text.trim(),
        category: _selectedCategory!,
        department: _selectedDepartment!,
        description: _descriptionController.text.trim(),
        contact: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        imageUrl: _selectedImage?.path, // Store local image path
        timestamp: now,
        lastUpdateTimestamp: now, // Initially same as submission
        status: simulatedStatus,
        feedback: simulatedFeedback,
      );
      setState(() {
        _reportHistory.insert(0, newReport); // Add new report to the top of the list
        _reportHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Re-sort
      });

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
        _selectedImage = null;
        _selectedCategory = null; // Dropdown Button
        _selectedDepartment = null;
      });
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
  void _requestUrgency(String reportId) {
    setState(() {
      final index = _reportHistory.indexWhere((report) => report.id == reportId);
      if (index != -1) {
        _reportHistory[index] = _reportHistory[index].copyWith(
          isUrgent: true,
          feedback: 'Your request to urge for update has been received. We will address this report within 12 hours.Thank you for your patience.',
          lastUpdateTimestamp: DateTime.now(), // Update last update time
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Request Urge Update for Report $reportId has been sent."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });
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
                        _buildSectionTitle("Image Proof"),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade100,
                            ),
                            child: _selectedImage == null
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt_outlined,
                                            size: 40, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text("Tap here to select an image"),
                                      ],
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.file(_selectedImage!,
                                        fit: BoxFit.cover),
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
                _reportHistory.isEmpty
                    ? const Center(
                        child: Text(
                          "You haven't submitted any reports yet.",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _reportHistory.length,
                        itemBuilder: (context, index) {
                          final report = _reportHistory[index];
                          return ReportCard(
                            report: report,
                            onRequestUrgency: _requestUrgency, // Pass the callback
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
  final MockReport report;
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
            if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
              SizedBox(
                height: 150,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    File(report.imageUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image,
                          size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
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