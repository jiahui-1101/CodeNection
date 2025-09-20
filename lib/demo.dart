import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'LoginPage.dart';   
import 'MainScreen.dart';
import 'CallManagementPage.dart';
import 'features/sos_alert/service/firebase_api.dart';

Future<void> main() async {   
  WidgetsFlutterBinding.ensureInitialized();
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