import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/register/LoginPage.dart';
import 'package:hello_flutter/pages/user/navigation_ui_components/MainScreen.dart';
import 'pages/staff/CallManagementPage.dart';
import 'features/sos_alert/service/firebase_api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 根据是否调试模式选择环境文件
  if (kDebugMode) {
    // 调试模式：开发环境
    await dotenv.load(fileName: ".env.development");
  } else {
    // 发布模式：生产环境
    await dotenv.load(fileName: ".env");
  }

  await Firebase.initializeApp();
  await FirebaseApi().initNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Firebase Auth Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      //home: const LoginPage(),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  final List<String> callManagementUsers = const [
    'utmbright@gmail.com',
    'nextlevel@gmail.com',
    'crayonshincan531@gmail.com',
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          final email = user.email ?? '';

          if (callManagementUsers.contains(email)) {
            FirebaseApi().subscribeToAlerts();
            return const CallManagementPage();
          } else {
            return const MainScreen();
          }
        }
        return const LoginPage();
      },
    );
  }
}