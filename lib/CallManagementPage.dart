import 'package:flutter/material.dart';
import 'package:hello_flutter/ManagementTopBar.dart';
import 'package:hello_flutter/title.dart';
import 'package:hello_flutter/ManagementAppDrawer.dart';
import 'EmergencyPage.dart';
import 'NewsUpdatePage.dart';
import '../pages/report_management_page.dart';

class CallManagementPage extends StatefulWidget {             // App (MainScreen Widget , staff view)
  const CallManagementPage({super.key});

  @override
  State<CallManagementPage> createState() => _CallManagementPageState();
}

class _CallManagementPageState extends State<CallManagementPage> {
  int _selectedTopIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static final List<Widget> _pages = <Widget>[
    EmergencyPage(),
    NewsUpdatePage(),
    ReportManagementPage(),
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
      drawer: const ManagementAppDrawer(),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              ManagementTopBar(
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
        ],
      ),
    );
  }
} 