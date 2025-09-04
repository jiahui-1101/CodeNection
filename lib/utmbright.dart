import 'package:flutter/material.dart';
import 'package:hello_flutter/MainScreen.dart';
//import 'package:audioplayers/audioplayers.dart';
//import 'package:hello_flutter/LocationSelectionPage.dart';
//import 'package:hello_flutter/ReportPage.dart';
//import 'package:hello_flutter/HomePage.dart';
//import 'package:hello_flutter/TopNavBar.dart';
//import 'package:hello_flutter/NewsCarousel.dart';
//import 'package:hello_flutter/NewsCard.dart';
//import 'package:hello_flutter/SmartSosButton.dart';
//import 'package:hello_flutter/AppDrawer.dart';
// ===================================================================
//做map和report的page只要改MapPage和ReportPage的class就可以了，
//不用改MainScreen和其他class，MapPage he ReportPage在main.dart 里面也call好了（我们的main我叫utmbright.dart)

void main() {
  runApp(const MyApp());
}

//App的根组件 (MyApp Widget)

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JustBrightForUTM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade300),
        //scaffoldBackgroundColor: Colors.red[100],
         scaffoldBackgroundColor: const Color(0xFFFFFAE6),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}

// ===================================================================
//XIA MIAN KE YI SHAN WAN LE
//  App的主屏幕 (MainScreen Widget)

/*class MainScreen extends StatefulWidget {
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
        backgroundColor: Color(0xFF8EB9D4),
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
}*/

// 3. 顶部导航栏 (TopNavBar Widget)
// ... [代码保持不变]
/*class TopNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const TopNavBar({super.key, required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.home_filled, 'Home', 0),
          _buildNavItem(context, Icons.map_outlined, 'Map', 1),
          _buildNavItem(context, Icons.edit_note_outlined, 'Report', 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final bool isSelected = selectedIndex == index;
    final Color color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: isSelected ? 24 : 0,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
} */


// 4. 新闻轮播 (NewsCarousel Widget)
// ... [代码保持不变]
/*class NewsCarousel extends StatefulWidget {
  const NewsCarousel({super.key});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  final List<Map<String, String>> newsData = [
    {'image': 'https://news.utm.my/wp-content/uploads/2022/05/3D2A3753-1200x800.jpg', 'title': 'Hehehe Campus Security Patrols Increased at Night'},
    {'image': 'https://images.unsplash.com/photo-1517486808906-6ca8b3f04846?q=80&w=1974', 'title': 'New Well-Lit Pathway Opens Near Library'},
    {'image': 'https://images.unsplash.com/photo-1616763355548-1b606f439f86?q=80&w=2070', 'title': 'Reminder: Final Exam Week Shuttle Bus Schedule'},
  ];

  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < newsData.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeIn,
        );
      }
    });
  }

  void _stopAutoScroll() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 24.0, top: 24.0),
          child: Text("News & Updates", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: newsData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return NewsCard(
                      imageUrl: newsData[index]['image']!,
                      title: newsData[index]['title']!);
                },
              ),
              Positioned(
                left: 0,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: Colors.black.withOpacity(0.7)),
                  onPressed: () {
                    _stopAutoScroll();
                    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                    _startAutoScroll();
                  },
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.black.withOpacity(0.7)),
                  onPressed: () {
                    _stopAutoScroll();
                    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                    _startAutoScroll();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}  

class NewsCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  const NewsCard({super.key, required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}  

// 5. SOS按钮与扇形菜单 (SosButtonWithMenu Widget) 

class SmartSosButton extends StatefulWidget {
  const SmartSosButton({super.key});

  @override
  State<SmartSosButton> createState() => _SmartSosButtonState();
}

class _SmartSosButtonState extends State<SmartSosButton>
    with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  late AnimationController _animationController; 
  Timer? _autoTimer;
  int _countdown = 5;

  final AudioPlayer _audioPlayer = AudioPlayer(); // 音频播放器

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();       // ✅ 销毁播放器
    _animationController.dispose();
    _autoTimer?.cancel();
    super.dispose();
  }

  void _stopAlarm() async {
  await _audioPlayer.stop();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("⏹️ Alarm Stopped"),
      backgroundColor: Colors.green,
    ),
  );
}


  void _handleTap() async {
  if (_isMenuOpen) {
    _toggleMenu();
  } else {
    if (_audioPlayer.state == PlayerState.playing) {
      // 如果正在播放，就停止
      await _audioPlayer.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⏹️ Alarm Sound Stopped!"),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // 否则就播放
      await _audioPlayer.play(AssetSource("music/alarm.mp3"));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔊 Alarm Sound Activated!"),
          duration: Duration(seconds: 3),
        ),
      );
}

    }
  }

  void _toggleMenu() {
    if (!mounted) return;
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });

    if (_isMenuOpen) {
      _startAutoCountdown();
    } else {
      _autoTimer?.cancel();
    }
  }

  void _startAutoCountdown() {
    _countdown = 5;
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown == 0) {
        timer.cancel();
        if (_isMenuOpen) {
          _navigateToGuardian("⚠️ Auto-triggered: Security Threat");
        }
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  void _navigateToGuardian(String message) {
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GuardianModeScreen(
        initialMessage: message,
         audioPlayer: _audioPlayer,  // ✅ 传递 audioPlayer
         ),
    ));
    if (_isMenuOpen) {
      _toggleMenu();
    }
  }

@override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20, //sos button 按钮离屏幕底部的距离。号码越大，它就越往上。
      right: 20,   //sos button 离屏幕右边的距离。号码越大，它就越往左。
      // 这个 Container 只是用来定义整个 widget 的边界和点击范围bulatan punya hu du
      child: SizedBox(
        width: 210,
        height: 210,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            // 1. 【半圆背景层】
            // 这个背景只在菜单打开时出现
            AnimatedOpacity(
              opacity: _isMenuOpen ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_isMenuOpen,
                child: Container(
                  decoration: BoxDecoration(
                    //color: const Color.red.withOpacity(0.5), //半圆弧度punya colour
                    color: Colors.red.withOpacity(0.4),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(220),
                    ),
                  ),
                ),
              ),
            ),
            
            // 2. 【小图标层】
            // 这些小图标也只在菜单打开时出现
            ..._buildFanMenuItems(),
            
            // 3. 【主按钮层】sos button 
            // 这个主按钮永远都在，不受动画影响
            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onLongPress: _toggleMenu,
                onTap: _handleTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 100,  //sos button de size
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isMenuOpen ? Icons.close : Icons.sos,
                          color: Colors.white,
                          size: 40,
                        ),
                        if (_isMenuOpen)
                          Text(
                            "$_countdown",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  List<Widget> _buildFanMenuItems() {
    final List<Map<String, dynamic>> items = [
      {'angle': 0.0, 'color': Colors.blue, 'icon': Icons.local_hospital, 'message': "🚑 Medical Alert Sent"},
      {'angle': 45.0, 'color': Colors.orange, 'icon': Icons.security, 'message': "🛡️ Security Threat Sent"},
      {'angle': 90.0, 'color': Colors.red.shade700, 'icon': Icons.fireplace_rounded, 'message': "🔥 Fire/Hazard Alert Sent"},
    ];

    const double mainButtonRadius = 100 / 2;
    const double iconRadius = 55 / 2;
    const double distance = 95.0;

    return items.map((item) {
      final double angle = item['angle'];
      final double rad = angle * (math.pi / 180.0);

      // 计算图标打开时的位置 (相对于 Stack 的右下角)
      final double openRight = mainButtonRadius - iconRadius + (distance * math.cos(rad));
      final double openBottom = mainButtonRadius - iconRadius + (distance * math.sin(rad));
      
      // 图标关闭时的位置 (藏在主按钮中心)
      final double closedRight = mainButtonRadius - iconRadius;
      final double closedBottom = mainButtonRadius - iconRadius;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        right: _isMenuOpen ? openRight : closedRight,
        bottom: _isMenuOpen ? openBottom : closedBottom,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isMenuOpen ? 1.0 : 0.0,
          child: InkWell(
            onTap: () {
              // 【调试工具2】保留这个 print，确认点击是否触发
             // print("NEW_APPROACH_SUCCESS: Tapped ${item['message']}");
              _navigateToGuardian(item['message']!);
            },
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item['color'],
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)],
              ),
              child: Icon(item['icon'], color: Colors.white),
            ),
          ),
        ),
      );
    }).toList();
  }
}

// === ADDED: 新增守护模式页面
class GuardianModeScreen extends StatelessWidget {
  final String initialMessage;
  final AudioPlayer audioPlayer;   // ✅ 新增

  const GuardianModeScreen({
    super.key, 
    required this.initialMessage,
    required this.audioPlayer,
  });
  
  // “暗号”取消机制的对话框
  void _showDeactivationDialog(BuildContext context) {
    final pinController = TextEditingController();
    const safePin = "0000";    // 真实的安全密码
    const duressPin = "1234"; // 被胁迫时用的危险密码

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Enter Deactivation PIN"),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(hintText: "4-digit PIN"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancel")),
          TextButton(
            child: const Text("Confirm"),
            onPressed: () {
              final enteredPin = pinController.text;
              Navigator.of(dialogContext).pop(); // 关闭PIN输入框
              
              if (enteredPin == safePin) {
                audioPlayer.stop();  // ✅ 停止 alarm

                Navigator.of(context).pop(); // 关闭守护模式页面
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: Colors.green,
                    content: Text("✅ Alert genuinely cancelled.")));
              } else if (enteredPin == duressPin) {
                audioPlayer.stop();  // ✅ 停止 alarm
                Navigator.of(context).pop(); // 关闭守护模式页面
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: Colors.orange,
                    content: Text("✅ Alert *appears* cancelled. Security has been notified of duress.")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text("❌ Incorrect PIN.")));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    initialMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Help is on the way...",
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                ],
              ),
              const Center(
                // TODO: 这里未来可以换成实时地图
                child: Icon(Icons.shield_moon, color: Colors.white24, size: 150),
              ),
              ElevatedButton(
                onPressed: () => _showDeactivationDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade900,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Deactivate with PIN"),
              )
            ],
          ),
        ),
      ),
    );
  }
} */

/*class HomePage extends StatelessWidget {
  // 6. 页面占位符 (Placeholder Pages)
// ... [代码保持不变]
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const NewsCarousel(),
          const SizedBox(height: 24),
          const LiveFeedSection(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
} */

/*class MapPage extends StatelessWidget {  //CLASS mappage move to another file 
  const MapPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Map Page", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
  }
}*/

/*class ReportPage extends StatelessWidget {
  const ReportPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Report Page", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
  }
}*/








