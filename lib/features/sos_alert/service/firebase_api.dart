import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
// ✅ 1. 我们现在也需要 GuardianModeScreen 的 import
import 'package:hello_flutter/GuardianModeScreen.dart';
import '../guard_view/guard_tracking_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  // vvvvvvvvvvvvvv 这是我们升级了的、更聪明的 function vvvvvvvvvvvvvv
  void _handleMessage(RemoteMessage message) {
    final String? alertId = message.data['alertId'];
    // ✅ 2. 先把标签拿出来
    final String? notificationType = message.data['notificationType'];

    if (alertId == null) {
      print("❌ Error: Received notification without alertId.");
      return;
    }

    // ✅ 3. 用 switch 来“看标签做事”
    switch (notificationType) {
      case 'NEW_ALERT':
        // 如果是给 Guard 的新警报
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          print("👮 Guard is viewing a NEW_ALERT. Navigating to GuardTrackingPage.");
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => TrackingPage(
                alertId: alertId,
                guardId: currentUser.uid, // 用 Guard 自己的 ID
              ),
            ),
          );
        }
        break;

      case 'GUARD_ACCEPTED':
        // 如果是给 User 的“Guard已接单”通知
        print("🧑 User is notified that GUARD_ACCEPTED. Navigating to GuardianModeScreen.");
        // 我们把用户带回到他自己的 GuardianModeScreen
        // 注意：这里我们无法传递 audioPlayer，所以 GuardianModeScreen 需要能够处理这种情况
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => GuardianModeScreen(
              alertId: alertId,
              initialMessage: "Help is on the way!", // 可以给一个默认信息
              audioPlayer: AudioPlayer(), // 创建一个新的实例，或者在 GuardianModeScreen 内部处理
            ),
          ),
        );
        break;

      default:
        print("🤷 Unknown notification type received: $notificationType");
        break;
    }
  }
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

  // ... (你其他的 function 完全不用动) ...
  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fcmToken = await _firebaseMessaging.getToken();
    print("FCM Token: $fcmToken");
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    setupInteractedMessage();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Got a message whilst in the foreground!");

      if (message.notification != null) {
        final notification = message.notification!;
        final title = notification.title ?? "New Alert";
        final body = notification.body ?? "An emergency has been reported.";
        final context = navigatorKey.currentContext;

        if (context != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _handleMessage(message);
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

  Future<void> subscribeToAlerts() async {
    await _firebaseMessaging.subscribeToTopic("new_alerts");
    print("Guard subscribed to new_alerts topic.");
  }

  Future<void> unsubscribeFromAlerts() async {
    await _firebaseMessaging.unsubscribeFromTopic("new_alerts");
    print("Guard unsubscribed from new_alerts topic.");
  }
}

