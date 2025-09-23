import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hello_flutter/features/sos_alert/user_view/GuardianModeScreen.dart';
import '../guard_view/guard_tracking_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  void _handleMessage(RemoteMessage message) {
    final String? alertId = message.data['alertId'];
    final String? notificationType = message.data['notificationType'];

    if (alertId == null) {
      print("❌ Error: Received notification without alertId.");
      return;
    }

    switch (notificationType) {
      case 'NEW_ALERT':

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          print("👮 Guard is viewing a NEW_ALERT. Navigating to GuardTrackingPage.");
              FirebaseFirestore.instance.collection('alerts').doc(alertId).update({
          'status': 'accepted',
          'guardId': currentUser.uid,
          'acceptedAt': FieldValue.serverTimestamp(),
          });

          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => TrackingPage(
                alertId: alertId,
                guardId: currentUser.uid, 
              ),
            ),
          );
        }
        break;

      case 'GUARD_ACCEPTED':
       
        print("🧑 User is notified that GUARD_ACCEPTED. Navigating to GuardianModeScreen.");
    
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => GuardianModeScreen(
              alertId: alertId,
              initialMessage: "Help is on the way!",
              audioPlayer: AudioPlayer(), 
            ),
          ),
        );
        break;

      default:
        print("🤷 Unknown notification type received: $notificationType");
        break;
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

