import 'package:flutter/material.dart';
import 'package:hello_flutter/DrawerNews.dart';
import 'package:hello_flutter/SettingPage.dart';

class AppDrawer extends StatelessWidget {   // 抽屉菜单 (AppDrawer Widget)
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(   //if NAK DRAWER OPEN FROM LEFT :EndDrawer
      backgroundColor: const Color(0xFFF0FAFF),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Mei Xue', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 2)])),
            accountEmail: const Text('meixue@gmail.com', style: TextStyle(color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 2)])),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: NetworkImage('https://img.soccersuck.com/images/2022/11/18/4c4b01be6415446c9789031ede08a225_315680695_686610763023135_407685450978648229_n.jpg'),
            ),
            decoration: const BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: NetworkImage('https://tse4.mm.bing.net/th/id/OIP.p0n7VCBDrHbIoUCRWk5MEwHaEK?rs=1&pid=ImgDetMain&o=7&rm=3'),
                colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken)
              ),
            ),
          ),
          ListTile(title: const Text('News and Updates'), trailing: const Icon(Icons.upcoming), onTap: () {
            
              Navigator.of(context).pop(); //close drawer xian
              // 然后导航到新的 news and update页面
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const DrawerNews(),
              ));
          }),
          ListTile(title: const Text('Settings'), trailing: const Icon(Icons.settings), onTap: () {
            // 首先关闭抽屉
              Navigator.of(context).pop();
              // 然后导航到新的 SettingsPage 页面
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const SettingsPage(),
                
              ));
            
          }),

           const Divider(),  //ADD DIVIDER BEFORE LOGOUT
          ListTile(
            leading: const Icon(Icons.logout), 
            title: const Text('Logout'),
            onTap: () {},
          ),

        ],
      ),
      
    );
  }
}
