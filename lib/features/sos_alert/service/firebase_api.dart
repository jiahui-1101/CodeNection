import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
// ⚠️ 记得检查这个 import 路径对不对
import '../guard_view/guard_tracking_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  // 这个方法完全不变
  void _handleMessage(RemoteMessage message) {
    final String? alertId = message.data['alertId'];
    final String? guardId = message.data['guardId'];

    if (alertId != null && guardId != null) {
      print("Notification tapped, navigating to alertId: $alertId");

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => TrackingPage(
            alertId: alertId,
            guardId: guardId,
          ),
        ),
      );
    }
  }

  // 这个方法完全不变
  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  Future<void> initNotifications() async {
    // iOs
    await _firebaseMessaging.requestPermission();

    final fcmToken = await _firebaseMessaging.getToken();
    print("FCM Token: $fcmToken");

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    setupInteractedMessage();
    
    // ✅ 核心修改：只改动下面这个 listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Got a message whilst in the foreground!");
      
      // 检查 message 和 notification 是不是空的
      if (message.notification != null) {
        final notification = message.notification!;
        final title = notification.title ?? "New Alert";
        final body = notification.body ?? "An emergency has been reported.";
        
        // 使用我们之前设置的 navigatorKey 来获取当前的 context
        final context = navigatorKey.currentContext;

        // 确保 context 存在才弹窗
        if (context != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 1. 先关掉 Dialog
                    _handleMessage(message);     // 2. 然后才跳转页面
                  },
                  child: const Text("View Details"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Dismiss"),
                ),
              ],
            ),
          );
        }
      }
    });
  }

  // 这个方法完全不变
  Future<void> subscribeToAlerts() async {
    await _firebaseMessaging.subscribeToTopic("new_alerts");
    print("Guard subscribed to new_alerts topic!");
  }

  // 这个方法完全不变
  Future<void> unsubscribeFromAlerts() async {
    await _firebaseMessaging.unsubscribeFromTopic("new_alerts");
    print("Guard unsubscribed from new_alerts topic.");
  }
}