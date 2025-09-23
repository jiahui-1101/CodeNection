import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hello_flutter/DrawerNews.dart';
import 'package:hello_flutter/HotlinePage.dart';
import 'package:hello_flutter/SettingPage.dart';
import 'package:hello_flutter/EmergencyContactPage.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    if (user != null) {
      try {
        // Storage path: "profile_pictures/{uid}.jpg"
        final ref = FirebaseStorage.instance
            .ref()
            .child("profile_pictures/${user!.uid}.jpg");

        final url = await ref.getDownloadURL();
        setState(() {
          _profileImageUrl = url;
        });
      } catch (e) {
        debugPrint("⚠️ No profile picture found in Firebase Storage: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF0FAFF),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              user?.displayName ?? 'Guest User',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
            accountEmail: Text(
              user?.email ?? 'guest@example.com',
              style: const TextStyle(
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : (user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : const AssetImage('assets/images/profile_placeholder.png')
                          as ImageProvider),
              radius: 30,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0f3460),
            ),
          ),

          // 🔹 News
          ListTile(
            title: const Text('News and Updates'),
            trailing: const Icon(Icons.upcoming),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DrawerNews()),
              );
            },
          ),

          // 🔹 Emergency Contact
          ListTile(
            title: const Text('Emergency Contact'),
            trailing: const Icon(Icons.phone_in_talk),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const EmergencyContactPage()),
              );
            },
          ),

          // 🔹 Hotline
          ListTile(
            title: const Text('Hotline'),
            trailing: const Icon(Icons.support_agent),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HotlinePage()),
              );
            },
          ),

          const Divider(),

          // 🔹 Settings
          ListTile(
            title: const Text('Settings'),
            trailing: const Icon(Icons.settings),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
