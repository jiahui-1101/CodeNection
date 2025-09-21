import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hello_flutter/GuardianModeScreen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';

class SosAppBarButton extends StatefulWidget {
  const SosAppBarButton({super.key});

  @override
  State<SosAppBarButton> createState() => _SosAppBarButtonState();
}

class _SosAppBarButtonState extends State<SosAppBarButton> {
  final AudioPlayer audioPlayer = AudioPlayer();
  Timer? _longPressTimer;
  int _countdown = 0;

  void _startLongPress(BuildContext context) {
    setState(() {
      _countdown = 3; 
    });

    _longPressTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdown == 1) {
        timer.cancel();
        setState(() => _countdown = 0);

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          return;
        }

        final duressQuery = await FirebaseFirestore.instance
            .collection('alerts')
            .where('userId', isEqualTo: currentUser.uid)
            .where('duress', isEqualTo: true)
            .limit(1)
            .get();

        if (duressQuery.docs.isNotEmpty) {
          return;
        }

        Position? position;
        try {
          position = await Geolocator.getCurrentPosition();
        } catch (e) {
          print("Failed to get location: $e");
        }

         final contactsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('emergency_contacts')
          .get();

        List<Map<String, String>> emergencyContactsList = [];

        for (var doc in contactsSnapshot.docs) {
        emergencyContactsList.add({
          'name': doc.data()['name'] as String,
          'phone': doc.data()['phone'] as String,
        });
      }
        final userFcmToken = await FirebaseMessaging.instance.getToken();
        final docRef = await FirebaseFirestore.instance.collection('alerts').add({
          'status': 'pending',
          'type': 'security',
          'timestamp': FieldValue.serverTimestamp(),
          'userId': currentUser.uid,
          'userName': currentUser.displayName ?? 'A User',
          'title': "SOS Long Press Triggered",
          'latitude': position?.latitude,   
          'longitude': position?.longitude,
          'emergencyContacts': emergencyContactsList,
           'userFcmToken': userFcmToken,
        });
        final alertId = docRef.id;

        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GuardianModeScreen(
            initialMessage: "🚨 SOS Long Press Triggered: Guardian Mode Activated!",
            audioPlayer: audioPlayer,
            alertId: alertId,
          ),
        ));
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  void _endLongPress() {
    _longPressTimer?.cancel();
    if (mounted) {
      setState(() => _countdown = 0);
    }
  }

  void _triggerAlarm(BuildContext context) async {
    if (audioPlayer.state == PlayerState.playing) {
      await audioPlayer.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⏹️ Alarm Sound Stopped!"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await audioPlayer.play(AssetSource("music/alarm.mp3"));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🔊 Alarm Sound Activated!"),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _triggerAlarm(context),
      onLongPressStart: (_) => _startLongPress(context),
      onLongPressEnd: (_) => _endLongPress(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: _countdown > 0
              ? Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.sos_rounded,
                  color: Colors.white,
                  size: 32,
                ),
        ),
      ),
    );
  }
}