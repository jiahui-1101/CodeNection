import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final String documentId; 
  final bool isAlert;      
  StreamSubscription<Position>? _positionSubscription;

  LocationService(this.documentId, {this.isAlert = false});

  String get collectionPath => isAlert ? 'alerts' : 'guards';

  Future<void> startSharingLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) async {
      await FirebaseFirestore.instance
          .collection(collectionPath)
          .doc(documentId)
          .set({
        "latitude": position.latitude,
        "longitude": position.longitude,
        "timestamp": FieldValue.serverTimestamp(),
        "active": true,
      }, SetOptions(merge: true));
    });
  }

  Future<void> stopSharingLocation() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    await FirebaseFirestore.instance
        .collection(collectionPath)
        .doc(documentId)
        .set({
      "active": false,
      "stoppedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}