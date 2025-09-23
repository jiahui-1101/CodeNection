import 'package:flutter/material.dart';
import 'package:hello_flutter/pages/user/navigation_ui_components/title.dart';
import 'package:hello_flutter/pages/user/TopNavBar.dart';
import 'package:hello_flutter/features/sos_alert/user_view/SmartSosButton.dart';
import 'package:hello_flutter/pages/user/HomePage.dart';
import 'package:hello_flutter/features/map/main_features/MapPage.dart';
import '../../../features/report/user_view/ReportPage.dart';
import 'package:hello_flutter/pages/user/navigation_ui_components/AppDrawer/AppDrawer.dart';

class MainScreen extends StatefulWidget {             // App(MainScreen Widget) user view
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTopIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static final List<Widget> _pages = <Widget>[
    HomePage(),
    MapPage(),
    ReportPage(),
  ];

  void _onTopNavTapped(int index) {
    setState(() {
      _selectedTopIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
          toolbarHeight: 100, // ⬅️ 提高 AppBar 高度
        //title: const Text('JustBrightForUTM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        title:const Center(child: UtmBrightTitle()), //import title
        backgroundColor: Color.fromARGB(255, 198, 228, 247),
       //backgroundColor: Color(0xFF6AA9FE),

        foregroundColor: Colors.black87,
        elevation: 1.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, size: 30),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              TopNavBar(
                selectedIndex: _selectedTopIndex,
                onItemTapped: _onTopNavTapped,
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedTopIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
          const SmartSosButton(),
        ],
      ),
    );
  }
} 