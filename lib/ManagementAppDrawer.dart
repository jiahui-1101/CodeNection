import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hello_flutter/DrawerNews.dart';
import 'package:hello_flutter/HotlinePage.dart';
import 'package:hello_flutter/ManagementSettingsPage.dart';
import 'package:hello_flutter/EmergencyContactPage.dart';
import 'package:hello_flutter/LoginPage.dart';
import 'package:hello_flutter/CallManagementPage.dart';

class ManagementAppDrawer extends StatelessWidget {
  const ManagementAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

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
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : const AssetImage('assets/images/profile_placeholder.png')
                      as ImageProvider,
              radius: 30,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0f3460), // solid color background
            ),
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
                MaterialPageRoute(builder: (context) => const ManagementSettingsPage()),
              );
            },
          )
        ],
      ),
    );
  }
}
