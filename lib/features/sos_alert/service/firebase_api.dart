import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../guard_view/guard_tracking_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  void _handleMessage(RemoteMessage message) {

    final String? alertId = message.data['alertId'];

    final currentUser = FirebaseAuth.instance.currentUser;

    if (alertId != null && currentUser != null) {
      final String guardId = currentUser.uid; 

      print("✅ Handling message: $alertId，PIC Guard: $guardId");

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => TrackingPage(
            alertId: alertId,
            guardId: guardId, 
          ),
        ),
      );
    } else {
      print("❌ Failed to handle message: Missing alertId or user not logged in.");
    }
  }

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
      print("Received a foreground message! ${message.messageId}");
      
      if (message.notification != null) {
        final notification = message.notification!;
        final title = notification.title ?? "New Alert";
        final body = notification.body ?? "You have a new alert.";
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

