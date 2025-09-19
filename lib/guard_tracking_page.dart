import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:rxdart/rxdart.dart';
import 'features/sos_alert/service/location_service.dart';

class TrackingPage extends StatefulWidget {
  final String alertId;
  final String guardId;

  const TrackingPage({
    super.key,
    required this.alertId,
    required this.guardId,
  });

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  GoogleMapController? _mapController;
  late LocationService _guardLocationService;

  @override
  void initState() {
    super.initState();
    _guardLocationService = LocationService(widget.guardId, isAlert: false);
    _guardLocationService.startSharingLocation();
  }

  Future<void> _endTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm End Task"),
        content: const Text("Are you sure you want to mark this alert as completed?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Confirm")),
        ],
      ),
    );

    if (confirmed == true) {
      await _guardLocationService.stopSharingLocation();
      await FirebaseFirestore.instance.collection('alerts').doc(widget.alertId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'duress': false,
      });
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _guardLocationService.stopSharingLocation(); 
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Stream<DocumentSnapshot> alertStream = FirebaseFirestore.instance.collection('alerts').doc(widget.alertId).snapshots();
    final Stream<DocumentSnapshot> guardStream = FirebaseFirestore.instance.collection('guards').doc(widget.guardId).snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tracking Alert"),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: CombineLatestStream.combine2(alertStream, guardStream, (a, b) => [a, b]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final alertSnap = snapshot.data![0];
          final guardSnap = snapshot.data![1];

          if (!alertSnap.exists) return const Center(child: Text("Waiting for user's location..."));

          final alertData = alertSnap.data() as Map<String, dynamic>;
          final status = alertData['status'] as String?;

          return Column(
            children: [
              Expanded(
                flex: 3,
                child: _buildMap(alertData, guardSnap.data() as Map<String, dynamic>?),
              ),
              Expanded(
                flex: 2,
                child: _buildAudioList(),
              ),
              if (status == 'accepted')
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.done_all),
                    label: const Text("End Task"),
                    onPressed: _endTask,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50)
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(Map<String, dynamic> alertData, Map<String, dynamic>? guardData) {
    final userLat = alertData['latitude'] as double?;
    final userLng = alertData['longitude'] as double?;

    final Set<Marker> markers = {};
    
    LatLng? userPosition;
    if (userLat != null && userLng != null) {
      userPosition = LatLng(userLat, userLng);
      markers.add(Marker(
        markerId: const MarkerId("user_location"),
        position: userPosition,
        infoWindow: const InfoWindow(title: "User Location"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    LatLng? guardPosition;
    if (guardData != null) {
      final guardLat = guardData['latitude'] as double?;
      final guardLng = guardData['longitude'] as double?;
      if (guardLat != null && guardLng != null) {
        guardPosition = LatLng(guardLat, guardLng);
        markers.add(Marker(
          markerId: const MarkerId("guard_location"),
          position: guardPosition,
          infoWindow: const InfoWindow(title: "Your Location"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ));
      }
    }
    
    if (_mapController != null && userPosition != null && guardPosition != null) {
      final southwest = LatLng(
        userPosition.latitude < guardPosition.latitude ? userPosition.latitude : guardPosition.latitude,
        userPosition.longitude < guardPosition.longitude ? userPosition.longitude : guardPosition.longitude,
      );
      final northeast = LatLng(
        userPosition.latitude > guardPosition.latitude ? userPosition.latitude : guardPosition.latitude,
        userPosition.longitude > guardPosition.longitude ? userPosition.longitude : guardPosition.longitude,
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(LatLngBounds(southwest: southwest, northeast: northeast), 100.0)
      );
    }

    if (userPosition == null) return const Center(child: Text("Location data not available."));

    return GoogleMap(
      onMapCreated: (controller) => _mapController = controller,
      initialCameraPosition: CameraPosition(target: userPosition, zoom: 16),
      markers: markers,
    );
  }

  Widget _buildAudioList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('alerts').doc(widget.alertId).collection('audio').orderBy('uploadedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text("Error loading audio: ${snapshot.error}"));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No audio recordings yet."));
          final audioDocs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: audioDocs.length,
            itemBuilder: (context, index) {
              final audioData = audioDocs[index].data() as Map<String, dynamic>;
              final url = audioData['url'] as String?;
              final uploadedAt = (audioData['uploadedAt'] as Timestamp?)?.toDate();
              return ListTile(
                leading: const Icon(Icons.mic),
                title: Text(uploadedAt != null ? "Recording at ${TimeOfDay.fromDateTime(uploadedAt).format(context)}" : "Recording"),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: url != null ? () async {
                    await _audioPlayer.stop();
                    await _audioPlayer.play(UrlSource(url));
                  } : null,
                ),
              );
            },
          );
      },
    );
  }
}