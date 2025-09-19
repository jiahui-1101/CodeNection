import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../service/location_service.dart';

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

  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _userPosition;
  LatLng? _guardPosition;
  String _distanceRemaining = "...";
  String _durationRemaining = "...";
  Timer? _routeRecalculationTimer;
  final String _apiKey = "AIzaSyALfVigfIlFFmcVIEy-5OGos42GViiQe-M"; 

  final AudioPlayer _audioPlayer = AudioPlayer();
  late LocationService _guardLocationService;

  @override
  void initState() {
    super.initState();
    _guardLocationService = LocationService(widget.guardId, isAlert: false);
    _guardLocationService.startSharingLocation();
    _startRouteRecalculation();
  }
  
  void _startRouteRecalculation() {
    _routeRecalculationTimer?.cancel();
    _routeRecalculationTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      _updateRouteAndInfo();
    });
  }

  Future<void> _updateRouteAndInfo() async {
    if (_userPosition == null || _guardPosition == null || _apiKey.contains("AIzaSyALfVigfIlFFmcVIEy-5OGos42GViiQe-M")) return;
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?'
      'origin=${_guardPosition!.latitude},${_guardPosition!.longitude}&'
      'destination=${_userPosition!.latitude},${_userPosition!.longitude}&'
      'mode=walking&key=$_apiKey',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode != 200 || !mounted) return;
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final leg = route['legs'][0];
        final points = route['overview_polyline']['points'];
        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: const PolylineId('route'),
            points: _decodePolyline(points),
            color: Colors.lightBlueAccent,
            width: 8,
          ));
          _distanceRemaining = leg['distance']['text'];
          _durationRemaining = leg['duration']['text'];
        });
      }
    } catch (e) {
      print("Error fetching directions: $e");
    }
  }

  Future<void> _updateCameraBounds() async {
    if (_userPosition == null || _guardPosition == null || !_mapControllerCompleter.isCompleted) return;
    final controller = await _mapControllerCompleter.future;
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            _userPosition!.latitude < _guardPosition!.latitude ? _userPosition!.latitude : _guardPosition!.latitude,
            _userPosition!.longitude < _guardPosition!.longitude ? _userPosition!.longitude : _guardPosition!.longitude,
          ),
          northeast: LatLng(
            _userPosition!.latitude > _guardPosition!.latitude ? _userPosition!.latitude : _guardPosition!.latitude,
            _userPosition!.longitude > _guardPosition!.longitude ? _userPosition!.longitude : _guardPosition!.longitude,
          ),
        ),
        100.0,
      ),
    );
  }

  LatLng? _extractLatLng(Map<String, dynamic>? data) {
    if (data == null || data['latitude'] == null || data['longitude'] == null) return null;
    return LatLng(data['latitude'], data['longitude']);
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
    _routeRecalculationTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertStream = FirebaseFirestore.instance.collection('alerts').doc(widget.alertId).snapshots();
    final guardStream = FirebaseFirestore.instance.collection('guards').doc(widget.guardId).snapshots();

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
          if (!alertSnap.exists) return const Center(child: Text("Alert has been resolved or deleted."));

          final alertData = alertSnap.data() as Map<String, dynamic>;
          final guardData = guardSnap.data() as Map<String, dynamic>?;
          final status = alertData['status'] as String?;

          _userPosition = _extractLatLng(alertData);
          _guardPosition = _extractLatLng(guardData);

          if (_userPosition != null && _guardPosition != null) {
            if (_routeRecalculationTimer == null || !_routeRecalculationTimer!.isActive) {
               _updateRouteAndInfo();
               _startRouteRecalculation();
            }
          }

          return Column(
            children: [
              _buildNavigationInfoCard(alertData),
              Expanded(flex: 3, child: _buildMap()),
              Expanded(flex: 3, child: _buildAudioList()),
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
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    _markers.clear();
    if (_userPosition != null) {
      _markers.add(Marker(
        markerId: const MarkerId("user_location"),
        position: _userPosition!,
        infoWindow: const InfoWindow(title: "User Location"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }
    if (_guardPosition != null) {
      _markers.add(Marker(
        markerId: const MarkerId("guard_location"),
        position: _guardPosition!,
        infoWindow: const InfoWindow(title: "Your Location"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }
    _updateCameraBounds();
    if (_userPosition == null) return const Center(child: Text("Waiting for user location..."));
    return GoogleMap(
      onMapCreated: (controller) {
        if (!_mapControllerCompleter.isCompleted) {
          _mapControllerCompleter.complete(controller);
        }
      },
      initialCameraPosition: CameraPosition(target: _userPosition!, zoom: 16),
      markers: _markers,
      polylines: _polylines,
    );
  }

  Widget _buildNavigationInfoCard(Map<String, dynamic> alertData) {
     return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blueGrey.shade50,
      child: Column(
        children: [
          Text(
            alertData['title'] ?? 'Emergency Alert',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(Icons.directions_walk, _distanceRemaining, "Distance to User", Colors.blue),
              _buildMetricItem(Icons.timer, _durationRemaining, "Est. Arrival Time", Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAudioList() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .doc(widget.alertId)
            .collection('audio')
            .orderBy('uploadedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No audio recordings yet."));
          }
          final audioDocs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: audioDocs.length,
            itemBuilder: (context, index) {
              final audioData = audioDocs[index].data() as Map<String, dynamic>;
              final url = audioData['url'] as String?;
              final uploadedAt = (audioData['uploadedAt'] as Timestamp?)?.toDate();
              
              if(url == null) return const SizedBox.shrink();

              return AudioPlayerTile(
                key: ValueKey(url),
                audioPlayer: _audioPlayer,
                url: url,
                uploadedAt: uploadedAt,
              );
            },
          );
        });
  }
  
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}

class AudioPlayerTile extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final String url;
  final DateTime? uploadedAt;

  const AudioPlayerTile({
    super.key,
    required this.audioPlayer,
    required this.url,
    this.uploadedAt,
  });

  @override
  State<AudioPlayerTile> createState() => _AudioPlayerTileState();
}

class _AudioPlayerTileState extends State<AudioPlayerTile> {

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: widget.audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final isPlaying = playerState?.playing ?? false;
        final isCurrentSource = widget.audioPlayer.audioSource?.toString().contains(widget.url) ?? false;

        final isLoading = isCurrentSource && (processingState == ProcessingState.loading || processingState == ProcessingState.buffering);
        final isThisTilePlaying = isCurrentSource && isPlaying;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isCurrentSource ? Colors.blueAccent : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.mic),
                title: Text(widget.uploadedAt != null
                    ? "Recording at ${TimeOfDay.fromDateTime(widget.uploadedAt!).format(context)}"
                    : "Recording"),
                trailing: isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      icon: Icon(
                        isThisTilePlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                        size: 30,
                        color: isThisTilePlaying ? Colors.blueAccent : null,
                      ),
                      onPressed: () {
                        if (isThisTilePlaying) {
                          widget.audioPlayer.pause();
                        } else if (isCurrentSource) {
                          widget.audioPlayer.play();
                        } else {

                          widget.audioPlayer.stop();
                          widget.audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(widget.url)));
                          widget.audioPlayer.play();
                        }
                      },
                    ),
              ),
              if (isCurrentSource)
                StreamBuilder<Duration>(
                  stream: widget.audioPlayer.positionStream,
                  builder: (context, positionSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    final duration = widget.audioPlayer.duration ?? Duration.zero;
                    return Column(
                      children: [
                        Slider(
                          min: 0,
                          max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                          value: position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
                          onChanged: (value) {
                            widget.audioPlayer.seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0).copyWith(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position)),
                              Text(_formatDuration(duration)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                ),
            ],
          ),
        );
      }
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}