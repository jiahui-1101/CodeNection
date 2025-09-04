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
// ============================THIS IS MAIN CLASS()=================================
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 145, 203, 250)),
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









