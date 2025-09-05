import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReportPage extends StatefulWidget {             //PLACEHOLDER PLACE---REPORTPAGE
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _formKey = GlobalKey<FormState>(); //key to identify the form
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController(); 
  File? _selectedImage;
   bool _isPickingImage = false;

  String? _selectedCategory; //variable that save the category chosen by user
  String? _selectedDepartment;

  final List<String> _categories = ['Kerosakan', 'Ancaman Keselamatan'];  //list of categories
  final List<String> _departments = ['Penyelenggaraan', 'Bahagian Keselamatan'];

  final ImagePicker _picker = ImagePicker();

Future<void> _pickImage() async {
    // check sama ade dlm process ,if yes return, prevent double click hhh
    if (_isPickingImage) return;

    try {
      //set state as processing, lock the operation
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
      // whatever happen(success,fail,cancel), unlock the operation eventually
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

 void _submitReport() {
    // ensure all field are valid
    if (_formKey.currentState?.validate() ?? false) {
      // demo submit action, in real app u can send to server or save to db
      print("Title: ${_titleController.text.trim()}");
      print("Category: $_selectedCategory");
      print("Department: $_selectedDepartment");
      print("Description: ${_descriptionController.text.trim()}");
      print("Contact: ${_contactController.text.trim()}"); 
      print("Image: ${_selectedImage?.path ?? 'No image selected'}");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Thank you! Your report has been submitted. We will follow up ASAP."),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Make a Report Here ", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF8EB9D4),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
      
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Report Details"), 
                      const SizedBox(height: 16),
                      TextFormField(   //VALIDATION
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: "Title",
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(),
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
                        decoration: const InputDecoration(
                          labelText: 'Complaint Category',
                          prefixIcon: Icon(Icons.category_outlined),
                          border: OutlineInputBorder(),
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
                        validator: (value) => value == null ? 'Choose complaint category.' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.groups_outlined),
                          border: OutlineInputBorder(),
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
                        validator: (value) => value == null ? 'Choose related department.' : null, 
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
                          labelText: "Email or Phone No. (Optional)", // "Email or Phone No. (Optional)"
                          prefixIcon: Icon(Icons.contact_mail_outlined),
                          border: OutlineInputBorder(),
                        ),
                        // no need validator since it's optional
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
                     ? const Center(child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey), 
                           SizedBox(height: 8),
                           Text("Tap here to select an image"),
                         ],
                       ))
                       : ClipRRect(
                           borderRadius: BorderRadius.circular(8.0),
                           child: Image.file(_selectedImage!, fit: BoxFit.cover),
                         ),
                ),
              ),
              const SizedBox(height: 24),

              // SUBMIT BUTTON
              ElevatedButton.icon(
                onPressed: _submitReport,
                icon: const Icon(Icons.send),
                label: const Text("Submit Report", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8EB9D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
    );
  }
}