import 'package:flutter/material.dart';
import 'package:hello_flutter/DrawerNews.dart';
import 'package:hello_flutter/EmergencyContactPage.dart';
import 'package:hello_flutter/SettingPage.dart';
import 'package:hello_flutter/LoginPage.dart';

class AppDrawer extends StatelessWidget {
  // 抽屉菜单 (AppDrawer Widget)
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      //if NAK DRAWER OPEN FROM LEFT :EndDrawer
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
              radius: 30, // adjust size
            ),
            decoration: const BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage('assets/images/wallpaper.jpg'),
                colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
              ),
            ),
          ),
          ListTile(
            title: const Text('News and Updates'),
            trailing: const Icon(Icons.upcoming),
            onTap: () {
              Navigator.of(context).pop(); //close drawer xian
              // 然后导航到新的 news and update页面
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DrawerNews()),
              );
            },
          ),
          ListTile(
            title: const Text('Emergency Contact'),
            trailing: const Icon(Icons.phone_in_talk),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EmergencyContactPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Settings'),
            trailing: const Icon(Icons.settings),
            onTap: () {
              // 首先关闭抽屉
              Navigator.of(context).pop();
              // 然后导航到新的 SettingsPage 页面
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),

          const Divider(), //ADD DIVIDER BEFORE LOGOUT
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginPage()),
                (Route<dynamic> route) => false, // Remove all previous routes
              );
            },
          ),
        ],
      ),
    );
  }
}
