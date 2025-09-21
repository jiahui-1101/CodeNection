import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  String _username = 'User';
  String _email = 'user@example.com';
  String? _profileImageUrl;
  String _realEmergencyPassword = '0000'; // Default real emergency password
  String _duressEmergencyPassword = '1234'; // Default duress emergency password

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadSettings();
    _loadEmergencyPasswords(); // Load emergency passwords
  }

  // Load saved settings from shared preferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications') ?? true;
        _profileImageUrl = prefs.getString('profileImageUrl');

        // Use Firebase user data if available, otherwise use saved data
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
      // Fallback to default values if loading fails
      setState(() {
        _notificationsEnabled = true;
        _username = 'User';
        _email = 'user@example.com';
      });
    }
  }

  // Refresh email from Firebase
  Future<void> _refreshEmail() async {
    try {
      await _currentUser?.reload();
      _currentUser = _auth.currentUser;
      setState(() {
        _email = _currentUser?.email ?? _email;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email refreshed successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error refreshing email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh email: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Load emergency passwords from Firestore
  Future<void> _loadEmergencyPasswords() async {
    if (_currentUser == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _realEmergencyPassword =
              doc.data()?['realEmergencyPassword'] ?? '0000';
          _duressEmergencyPassword =
              doc.data()?['duressEmergencyPassword'] ?? '1234';
        });
      }
    } catch (e) {
      print('Error loading emergency passwords: $e');
    }
  }

  // Save emergency passwords to Firestore
  Future<void> _saveEmergencyPasswords(
    String realPassword,
    String duressPassword,
  ) async {
    if (_currentUser == null) return;

    try {
      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'realEmergencyPassword': realPassword,
        'duressEmergencyPassword': duressPassword,
      }, SetOptions(merge: true));

      setState(() {
        _realEmergencyPassword = realPassword;
        _duressEmergencyPassword = duressPassword;
      });
    } catch (e) {
      print('Error saving emergency passwords: $e');
      rethrow;
    }
  }

  // Save a setting value to shared preferences
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
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save settings. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Clear all settings (for logout or reset)
  Future<void> _clearAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // Reset to default values
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

  // Update user profile in Firebase
  Future<void> _updateFirebaseProfile(
    String displayName,
    String? photoURL,
  ) async {
    try {
      if (_currentUser != null) {
        await _currentUser!.updateDisplayName(displayName);
        if (photoURL != null) {
          await _currentUser!.updatePhotoURL(photoURL);
        }
        // Reload user to get updated information
        await _currentUser!.reload();
        _currentUser = _auth.currentUser;
      }
    } catch (e) {
      print('Error updating Firebase profile: $e');
      rethrow;
    }
  }

  // Update password in Firebase
  Future<void> _updateFirebasePassword(String newPassword) async {
    try {
      if (_currentUser != null) {
        await _currentUser!.updatePassword(newPassword);
      }
    } catch (e) {
      print('Error updating Firebase password: $e');
      rethrow;
    }
  }

  // Reauthenticate user (required for sensitive operations like email/password change)
  Future<void> _reauthenticate(String password) async {
    try {
      if (_currentUser != null && _currentUser!.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: _currentUser!.email!,
          password: password,
        );
        await _currentUser!.reauthenticateWithCredential(credential);
      }
    } catch (e) {
      print('Error reauthenticating: $e');
      rethrow;
    }
  }

  // Sign out from Firebase
  Future<void> _logout(BuildContext navContext) async {
    showDialog(
      context: navContext,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _auth.signOut();
      await _clearAllSettings();
      if (navContext.mounted) {
        Navigator.of(navContext).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (navContext.mounted) {
        Navigator.of(navContext, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          navContext,
        ).showSnackBar(SnackBar(content: Text("Logout failed: $e")));
      }
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
            return const Center(child: CircularProgressIndicator());
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
          // User profile section
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
                              (_username.isNotEmpty
                                  ? _username[0].toUpperCase()
                                  : "?"),
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
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
                          icon: const Icon(
                            Icons.camera_alt,
                            size: 12,
                          ), // Smaller icon
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
                            child: Text(
                              _email,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            onPressed: _refreshEmail,
                            tooltip: 'Refresh email',
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

          // --- General Settings ---
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
                  subtitle: Text(
                    'Enable push notifications',
                    style: subtitleStyle,
                  ),
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

          // --- Account Settings ---
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
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text('Update Password', style: titleStyle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showUpdatePasswordDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.emergency_outlined,
                  ), // New icon for emergency password
                  title: Text('Emergency Password', style: titleStyle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showUpdateEmergencyPasswordDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text('Change Email', style: titleStyle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showChangeEmailDialog();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- About Section ---
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
                    _showTermsOfServiceDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: Text('Privacy Policy', style: titleStyle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showPrivacyPolicyDialog(context);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Logout button
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

  void _showUpdateEmergencyPasswordDialog() {
    TextEditingController realController = TextEditingController(
      text: _realEmergencyPassword,
    );
    TextEditingController duressController = TextEditingController(
      text: _duressEmergencyPassword,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Emergency Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Set your emergency passwords (4 digits each):'),
              const SizedBox(height: 16),
              TextField(
                controller: realController,
                decoration: const InputDecoration(
                  labelText: 'Real Emergency Password',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: duressController,
                decoration: const InputDecoration(
                  labelText: 'Duress Emergency Password',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
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
                if (realController.text.length != 4 ||
                    duressController.text.length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Both passwords must be 4 digits'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (realController.text == duressController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Real and duress passwords must be different',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _saveEmergencyPasswords(
                    realController.text,
                    duressController.text,
                  );
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Emergency passwords updated successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to update emergency passwords: ${e.toString()}',
                      ),
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
                  // Update Firebase profile
                  if (_currentUser != null) {
                    await _updateFirebaseProfile(
                      nameController.text,
                      _profileImageUrl,
                    );
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
                      content: Text(
                        'Failed to update profile: ${e.toString()}',
                      ),
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

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, // fixed height so it becomes scrollable
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Privacy Policy for UTMBright\n",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "UTMBright is committed to protecting your privacy. This Privacy Policy explains how we collect, use, store, and share your personal information when you use our safety and navigation mobile application. By using the App, you agree to the terms of this Privacy Policy.\n\n",
                  ),

                  Text(
                    "1. Information We Collect\n",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "a) Personal Information\n• Name, profile picture, email address, phone number.\n• Emergency contact details you add.\n• Duress PIN and Safe PIN (stored securely).\n\n",
                  ),
                  Text(
                    "b) Location Data\n• Real-time GPS location (navigation, route selection, alerts).\n• Historical route data (temporarily stored).\n\n",
                  ),
                  Text(
                    "c) Device & Usage Information\n• Device model, OS, app version.\n• Error logs, crash reports, usage data.\n\n",
                  ),
                  Text(
                    "d) Incident Reports\n• Hazard/suspicious activity reports.\n• Uploaded text, location, photos (optional).\n\n",
                  ),

                  Text(
                    "2. How We Use Your Information\n",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "• Provide safe navigation & route recommendations.\n• Enable community walking groups (“Let’s Walk”).\n• Trigger SOS alerts with real-time data.\n• Operate Live Guardian Mode (audio streaming).\n• Support incident reporting.\n• Maintain Resources Hub.\n• Improve app performance.\n\n",
                  ),

                  Text(
                    "3. Sharing of Information\n",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "• Campus Security / Guard House (location, emergency type, duress alerts, audio stream).\n• Service Providers (Firebase, hosting, analytics).\n• Legal Authorities (when required by law).\n• Authorized Users in “Let’s Walk” (name, profile picture).\n\n",
                  ),

                  Text(
                    "4. Data Storage & Security\n",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "• Encrypted storage of GPS, PINs, contacts.\n• Emergency alerts retained only as needed.\n• Data sent via secure transmission (HTTPS/SSL).\n\n",
                  ),

                  Text(
                    "5. Your Rights\n",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "• Access/update profile & emergency info.\n• Request deletion of personal info.\n• Withdraw location/audio permissions.\n• Disable notifications.\n\n",
                  ),

                  Text(
                    "6. Children’s Privacy\n",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Designed for UTM students/staff. Not intended for children under 13.\n\n",
                  ),

                  Text(
                    "7. International Data Transfers\n",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "If used outside Malaysia, data may be transferred abroad with safeguards.\n\n",
                  ),

                  Text(
                    "8. Changes to This Policy\n",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "We may update from time to time. Updates will be posted in the App.\n\n",
                  ),

                  Text(
                    "9. Third-Party Services\n",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "• Firebase (authentication, storage, analytics).\n• Google Maps API (navigation & safe routes).\n• Google Sign-In (secure login).\n• Flutter framework (app foundation).\n\nSee their privacy policies:\nFirebase: https://firebase.google.com/support/privacy\nGoogle Maps: https://policies.google.com/privacy\nGoogle Sign-In: https://policies.google.com/privacy\n\n",
                  ),

                  Text(
                    "10. App Permissions\n",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "• Location (required for navigation & alerts).\n• Microphone (Live Guardian Mode).\n• Camera & Storage (optional for reports).\n• Contacts (optional emergency contacts).\n• Notifications (alerts & updates).\n\n",
                  ),

                  Text(
                    "11. Contact Us\n",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("📧 Email: utmbright@gmail.com\n"),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdatePasswordDialog() {
    TextEditingController currentController = TextEditingController();
    TextEditingController newController = TextEditingController();
    TextEditingController confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
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
                // Validate passwords
                if (newController.text != confirmController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New passwords do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Reauthenticate user
                  await _reauthenticate(currentController.text);

                  // Update password in Firebase
                  await _updateFirebasePassword(newController.text);

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to update password: ${e.toString()}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showChangeEmailDialog() {
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'New Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
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
                  // Reauthenticate user
                  await _reauthenticate(passwordController.text);

                  // Send verification to new email
                  if (_currentUser != null) {
                    await _currentUser!.verifyBeforeUpdateEmail(
                      emailController.text,
                    );

                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Verification email sent to ${emailController.text}. '
                          'Please confirm to complete email change.',
                        ),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update email: ${e.toString()}'),
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
            'JustBrightForUTM makes campus safety smarter and faster. With real-time, accessible features, students can reach help instantly— '
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

  void _showTermsOfServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Terms of Service"),
          content: SizedBox(
            height: 400, // 限制高度，避免超出屏幕
            child: SingleChildScrollView(
              child: const Text(
                "Welcome to UTM Bright!\n\n"
                "By using this app, you agree to the following Terms of Service:\n\n"
                "1. Usage\n"
                "- You agree to use this app responsibly and for lawful purposes only.\n\n"
                "2. Account\n"
                "- You are responsible for maintaining the confidentiality of your account.\n"
                "- Any activity under your account is your responsibility.\n\n"
                "3. Data & Privacy\n"
                "- Your data will be stored securely and only used to provide app functionality.\n"
                "- For details, please refer to our Privacy Policy.\n\n"
                "4. Limitations\n"
                "- We are not responsible for damages resulting from misuse of this app.\n"
                "- The service may change, be suspended, or stopped at any time.\n\n"
                "5. Acceptance\n"
                "- By continuing to use this app, you acknowledge that you have read and agree to these Terms.\n\n"
                "---\n"
                "If you have any questions, contact us at utmbright@gmail.com",
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final buildContext = context;
                Navigator.of(dialogContext).pop();
                _logout(buildContext);
              },
              child: const Text('Log Out', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
