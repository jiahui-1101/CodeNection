import 'package:flutter/material.dart';
import 'package:hello_flutter/DrawerNews.dart';
import 'package:hello_flutter/HotlinePage.dart';
import 'package:hello_flutter/SettingPage.dart';
import 'package:hello_flutter/EmergencyContactPage.dart';  // ✅ 记得加这个

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF0FAFF),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text(
              'next level utm',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
            accountEmail: const Text(
              'next_level_utm@gmail.com',
              style: TextStyle(
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/bg.jpg'),
              radius: 30,
            ),
            decoration: const BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage('assets/images/wallpaper.jpg'),
                colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
              ),
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

          // 🔹 Emergency Contact
          ListTile(
            title: const Text('Emergency Contact'),
            trailing: const Icon(Icons.phone_in_talk),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EmergencyContactPage()),
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

          const Divider(),

          // 🔹 Logout
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              // TODO: 实现登出逻辑
            },
          ),
        ],
      ),
    );
  }
}
