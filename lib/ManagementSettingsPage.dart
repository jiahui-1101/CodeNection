import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'LoginPage.dart';

class ManagementSettingsPage extends StatefulWidget {
  const ManagementSettingsPage({super.key});

  @override
  State<ManagementSettingsPage> createState() => _ManagementSettingsPageState();
}

class _ManagementSettingsPageState extends State<ManagementSettingsPage> {
  bool _notificationsEnabled = true;
  String _username = 'User';
  String _email = 'user@example.com';
  String? _profileImageUrl;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadSettings();
  }

  // Load saved settings
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications') ?? true;
        _profileImageUrl = prefs.getString('profileImageUrl');

        if (_currentUser != null) {
          _username = _currentUser!.displayName ?? 'User';
          _email = _currentUser!.email ?? 'user@example.com';
          // Use Firebase photoURL if available
          _profileImageUrl = _currentUser!.photoURL ?? _profileImageUrl;
        } else {
          _username = prefs.getString('username') ?? 'User';
          _email = prefs.getString('email') ?? 'user@example.com';
        }
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _notificationsEnabled = true;
        _username = 'User';
        _email = 'user@example.com';
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e) {
      print('Error saving setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save settings. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      setState(() {
        _notificationsEnabled = true;
        _username = 'User';
        _email = 'user@example.com';
        _profileImageUrl = null;
      });
    } catch (e) {
      print('Error clearing settings: $e');
    }
  }

  Future<void> _updateFirebaseProfile(String displayName, String? photoURL) async {
    try {
      if (_currentUser != null) {
        await _currentUser!.updateDisplayName(displayName);
        if (photoURL != null) {
          await _currentUser!.updatePhotoURL(photoURL);
        }
        await _currentUser!.reload();
        _currentUser = _auth.currentUser;
      }
    } catch (e) {
      print('Error updating Firebase profile: $e');
      rethrow;
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      
      if (pickedFile != null) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        // Upload image to Firebase Storage
        final File imageFile = File(pickedFile.path);
        final Reference storageRef = _storage
            .ref()
            .child('profilePictures')
            .child('${_currentUser!.uid}.jpg');
        
        final UploadTask uploadTask = storageRef.putFile(imageFile);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        // Update user profile with new image URL
        await _updateFirebaseProfile(_username, downloadUrl);
        
        // Update local state
        setState(() {
          _profileImageUrl = downloadUrl;
        });
        
        // Save to shared preferences
        await _saveSetting('profileImageUrl', downloadUrl);
        
        // Hide loading indicator
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator if it's still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile picture: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show dialog for image source selection
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium;
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.grey.shade600,
    );
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      backgroundColor: theme.colorScheme.surface,
      body: ListView(
        children: [
          // User profile
          // User profile section
Container(
  color: theme.colorScheme.surface,
  padding: const EdgeInsets.all(16),
  child: Row(
    children: [
      Stack(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.primary,
            backgroundImage: _profileImageUrl != null
                ? NetworkImage(_profileImageUrl!)
                : null,
            child: _profileImageUrl == null
                ? Text(
                    (_username.isNotEmpty ? _username[0].toUpperCase() : "?"),
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 24, // Smaller container
              height: 24, // Smaller container
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: IconButton(
                padding: EdgeInsets.zero, // Remove padding
                icon: const Icon(Icons.camera_alt, size: 12), // Smaller icon
                color: Colors.white,
                onPressed: _showImageSourceDialog,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_username, style: theme.textTheme.titleLarge),
            Row(
              children: [
                Expanded(
                  child: Text(_email, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
),
          const SizedBox(height: 16),

          // General
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: Text('General', style: headerStyle),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: Text('Notification', style: titleStyle),
                  subtitle: Text('Enable push notifications', style: subtitleStyle),
                  value: _notificationsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _saveSetting('notifications', value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Account
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: Text('Account', style: headerStyle),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text('Edit Profile', style: titleStyle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showEditProfileDialog();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: Text('About', style: headerStyle),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text('About Us', style: titleStyle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text('Terms of Service', style: titleStyle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to terms of service
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: Text('Privacy Policy', style: titleStyle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to privacy policy
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                _showLogoutDialog(context);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: Colors.red.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    TextEditingController nameController = TextEditingController(
      text: _username,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (_currentUser != null) {
                    await _updateFirebaseProfile(nameController.text, _profileImageUrl);
                  }
                  setState(() {
                    _username = nameController.text;
                  });
                  _saveSetting('username', _username);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update profile: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About Us'),
          content: const Text(
            'JustBrightForUTM makes campus safety smarter and faster. '
            'With real-time, accessible features, students can reach help instantly— '
            'building trust, confidence, and peace of mind for everyone on campus.\n\n'
            'Version: 1.0.0',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _signOut();
                  _clearAllSettings();
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully')),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to log out: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Log Out', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}