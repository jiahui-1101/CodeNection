import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audio_session/audio_session.dart';
import 'RouteTracker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TrackingPage extends StatefulWidget {
  final String alertId;
  final String guardId;

  const TrackingPage({super.key, required this.alertId, required this.guardId});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  final Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final Set<Polyline> _trackedRoutePolylines = {};
  LatLng? _userPosition;
  LatLng? _guardPosition;
  LatLng? _lastUserPosition;
  LatLng? _lastGuardPosition;
  String _distanceRemaining = "...";
  String _durationRemaining = "...";
  Timer? _routeRecalculationTimer;
  late String _apiKey;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late LocationService _guardLocationService;


  String? _currentlyPlayingDocId;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  final bool _isSeeking = false;
  bool _isLoading = false;
  bool _isCompleted = false;

  RouteTracker? _routeTracker; // <-- made nullable
  final double _trackedDistance = 0;
  final int _trackedPoints = 0;

  // Subscriptions so we can cancel them cleanly
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration?>? _durationSub;

  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.get('GOOGLE_NAVIGATION_API_KEY');

    _guardLocationService = LocationService(widget.guardId, isAlert: false);
    _guardLocationService.startSharingLocation();

    
    _initAudioSession();
    _listenPlayer();

  }

  Future<void> _setupRouteTracking() async {
    try {
  
      if (_userPosition == null) {
        return;
      }
      _routeTracker = RouteTracker(
        apiKey: _apiKey,
        origin: _guardPosition, 
        destination: _userPosition!,
        onRouteReady: (points) {
          if (!mounted) return;
          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                width: 6,
                color: Colors.blue,
              ),
            };
          });
        },
        onLocationUpdated: (latlng) {
          if (!mounted) return;
          setState(() {
            _guardPosition = latlng;
            _updateGuardMarker();
          });
        },
        onProgressUpdated: (remainingMeters, etaMinutes) {
          if (!mounted) return;
          setState(() {
            _distanceRemaining =
                '${(remainingMeters / 1000.0).toStringAsFixed(2)} km';
            _durationRemaining = '${etaMinutes.toStringAsFixed(0)} min';
          });
        },
        onArrived: () {
          if (!mounted) return;
          setState(() {
         
          });
        },
        onError: (err) {
          debugPrint("RouteTracker error: $err");
        },
      );

      await _routeTracker!.initialize();
      _routeTracker!.startTracking();
    } catch (e) {
      debugPrint("Failed to setup route tracker: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Route init failed: $e")));
      }
    }
  }

  Future<void> _startRouteTracking() async {
    try {
      // Do not await a void method; RouteTracker.startTracking() returns void.
      if (_routeTracker == null) {
        // If not created yet, attempt to create it (best-effort)
        await _setupRouteTracking();
        return;
      }

      // startTracking is synchronous (void) in your RouteTracker, so just call it
      _routeTracker!.startTracking();
      print("Route tracking started");
    } catch (e) {
      print("Failed to start route tracking: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("无法开始路线跟踪: $e")));
      }
    }
  }

  void _updateGuardMarker() {
    // 移除旧的守卫标记
    _markers.removeWhere((marker) => marker.markerId.value == "guard_location");

    // 添加新的守卫标记
    if (_guardPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("guard_location"),
          position: _guardPosition!,
          infoWindow: const InfoWindow(title: "Your Location"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
    await session.setActive(true);
    print("AudioSession configured & activated ✅");
  }

  void _listenPlayer() {
    // assign subscriptions so we can cancel later
    _playerStateSub?.cancel();
    _durationSub?.cancel();

    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (_currentlyPlayingDocId != null) {
        if (state.processingState == ProcessingState.loading) {
          if (mounted) setState(() => _isLoading = true);
        } else if (state.processingState == ProcessingState.ready) {
          if (mounted) setState(() => _isLoading = false);
        } else if (state.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() {
              _isCompleted = true;
              _isLoading = false;
              _currentPosition = Duration.zero;
            });
          }
        }
      }
    });

    _durationSub = _audioPlayer.durationStream.listen((duration) {
      if (duration != null && mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
  }

  Future<void> _playRecording(String url, String docId) async {
    try {
      if (_currentlyPlayingDocId == docId) {
        // 同一音频的播放/暂停
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
        } else {
          // 如果是已完成状态，重新开始播放
          if (_isCompleted) {
            await _audioPlayer.seek(Duration.zero);
            if (mounted) {
              setState(() {
                _isCompleted = false;
                _currentPosition = Duration.zero;
              });
            }
          }
          await _audioPlayer.play();
        }
      } else {
        // 新音频
        if (mounted) {
          setState(() {
            _isLoading = true;
            _currentlyPlayingDocId = docId;
            _currentPosition = Duration.zero;
            _isCompleted = false;
          });
        }

        await _audioPlayer.stop();
        await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(url)));
        await _audioPlayer.play();
        print("Playback started ▶️");
      }
    } catch (e) {
      print("Playback error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Playback error: $e")));
      setState(() {
        _isLoading = false;
        _currentlyPlayingDocId = null;
        _isCompleted = false;
      });
    }
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds < 0) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Future<void> _updateCameraBounds() async {
    if (_userPosition == null ||
        _guardPosition == null ||
        !_mapControllerCompleter.isCompleted) {
      return;
    }

    final controller = await _mapControllerCompleter.future;
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            _userPosition!.latitude < _guardPosition!.latitude
                ? _userPosition!.latitude
                : _guardPosition!.latitude,
            _userPosition!.longitude < _guardPosition!.longitude
                ? _userPosition!.longitude
                : _guardPosition!.longitude,
          ),
          northeast: LatLng(
            _userPosition!.latitude > _guardPosition!.latitude
                ? _userPosition!.latitude
                : _guardPosition!.latitude,
            _userPosition!.longitude > _guardPosition!.longitude
                ? _userPosition!.longitude
                : _guardPosition!.longitude,
          ),
        ),
        100.0,
      ),
    );
  }

  LatLng? _extractLatLng(Map<String, dynamic>? data) {
    if (data == null || data['latitude'] == null || data['longitude'] == null) {
      return null;
    }
    return LatLng(data['latitude'], data['longitude']);
  }

  Future<void> _endTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm End Task"),
        content: const Text(
          "Are you sure you want to mark this alert as completed?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _guardLocationService.stopSharingLocation();
      await FirebaseFirestore.instance
          .collection('alerts')
          .doc(widget.alertId)
          .update({
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
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _durationSub?.cancel();
    _audioPlayer.dispose();
    _routeTracker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertStream = FirebaseFirestore.instance
        .collection('alerts')
        .doc(widget.alertId)
        .snapshots();
    final guardStream = FirebaseFirestore.instance
        .collection('guards')
        .doc(widget.guardId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tracking Alert"),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Add the route information button
          IconButton(
            icon: const Icon(Icons.route),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Route Information"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Distance traveled: ${_trackedDistance.toStringAsFixed(2)} meters",
                      ),
                      Text("Points recorded: $_trackedPoints"),
                      Text(
                        "Status: ${_routeTracker?.isTracking == true ? 'Tracking' : 'Not Tracking'}",
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("OK"),
                    ),
                    if (_routeTracker?.isTracking == true)
                      TextButton(
                        onPressed: () {
                          _routeTracker?.stopTracking();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Route tracking stopped"),
                            ),
                          );
                        },
                        child: const Text("Stop Tracking"),
                      ),
                    if (!(_routeTracker?.isTracking == true))
                      TextButton(
                        onPressed: () {
                          _startRouteTracking();
                          Navigator.of(context).pop();
                        },
                        child: const Text("Start Tracking"),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: CombineLatestStream.combine2(
          alertStream,
          guardStream,
          (a, b) => [a, b],
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final alertSnap = snapshot.data![0];
          final guardSnap = snapshot.data![1];
          if (!alertSnap.exists) {
            return const Center(
              child: Text("Alert has been resolved or deleted."),
            );
          }

          final alertData = alertSnap.data() as Map<String, dynamic>;
          final guardData = guardSnap.data() as Map<String, dynamic>?;
          final status = alertData['status'] as String?;

          _userPosition = _extractLatLng(alertData);
          _guardPosition = _extractLatLng(guardData);

          // 检查位置变化，超过100米时重新初始化RouteTracker
          if (_userPosition != null && _guardPosition != null) {
            if (_lastUserPosition == null && _lastGuardPosition == null) {
              // 第一次获取到位置，初始化路线
              _lastUserPosition = _userPosition;
              _lastGuardPosition = _guardPosition;
              _setupRouteTracking();
            } else {
              final userDistance = Geolocator.distanceBetween(
                _lastUserPosition!.latitude,
                _lastUserPosition!.longitude,
                _userPosition!.latitude,
                _userPosition!.longitude,
              );
              final guardDistance = Geolocator.distanceBetween(
                _lastGuardPosition!.latitude,
                _lastGuardPosition!.longitude,
                _guardPosition!.latitude,
                _guardPosition!.longitude,
              );
              if (userDistance > 100 || guardDistance > 100) {
                _lastUserPosition = _userPosition;
                _lastGuardPosition = _guardPosition;
                _setupRouteTracking();
              }
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

    // 添加用户位置标记
    if (_userPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("user_location"),
          position: _userPosition!,
          infoWindow: const InfoWindow(title: "User Location"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    if (_guardPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("guard_location"),
          position: _guardPosition!,
          infoWindow: const InfoWindow(title: "Your Location"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    _updateCameraBounds();

    if (_userPosition == null) {
      return const Center(child: Text("Waiting for user location..."));
    }

    return GoogleMap(
      onMapCreated: (controller) {
        if (!_mapControllerCompleter.isCompleted) {
          _mapControllerCompleter.complete(controller);
        }
      },
      initialCameraPosition: CameraPosition(target: _userPosition!, zoom: 16),
      markers: _markers,
      // 合并两组 polyline：导航（_polylines） + 路线跟踪（_trackedRoutePolylines）
      polylines: {..._polylines, ..._trackedRoutePolylines},
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
              _buildMetricItem(
                Icons.directions_walk,
                _distanceRemaining,
                "Distance to User",
                Colors.blue,
              ),
              _buildMetricItem(
                Icons.timer,
                _durationRemaining,
                "Est. Arrival Time",
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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
            final uploadedAt = (audioData['uploadedAt'] as Timestamp?)
                ?.toDate();
            final docId = audioDocs[index].id;

            if (url == null) return const SizedBox.shrink();

            final isPlaying = _currentlyPlayingDocId == docId;
            final isCurrentLoading = isPlaying && _isLoading;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.mic),
                    title: Text(
                      uploadedAt != null
                          ? "Recording at ${TimeOfDay.fromDateTime(uploadedAt).format(context)}"
                          : "Recording",
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        isCurrentLoading
                            ? Icons.hourglass_bottom
                            : isPlaying && _audioPlayer.playing
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        size: 30,
                      ),
                      onPressed: () => _playRecording(url, docId),
                    ),
                  ),
                  if (isPlaying) ...[
                    if (isCurrentLoading)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: LinearProgressIndicator(),
                      ),
                    if (!isCurrentLoading && _totalDuration > Duration.zero)
                      StreamBuilder<Duration>(
                        stream: _audioPlayer.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;

                          return Column(
                            children: [
                              Slider(
                                min: 0,
                                max: _totalDuration.inMilliseconds.toDouble(),
                                value: position.inMilliseconds
                                    .clamp(0, _totalDuration.inMilliseconds)
                                    .toDouble(),
                                onChanged: (value) {
                                  if (!mounted) return;
                                  setState(() {
                                    _currentPosition = Duration(
                                      milliseconds: value.toInt(),
                                    );
                                  });
                                },
                                onChangeEnd: (value) async {
                                  await _audioPlayer.seek(
                                    Duration(milliseconds: value.toInt()),
                                  );
                                  if (!_audioPlayer.playing) {
                                    await _audioPlayer.play();
                                  }
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDuration(position)),
                                    Text(_formatDuration(_totalDuration)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
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

// LocationService 类定义（假设已存在）
class LocationService {
  final String id;
  final bool isAlert;

  LocationService(this.id, {required this.isAlert});

  Future<void> startSharingLocation() async {
    // 实现位置共享逻辑
  }

  Future<void> stopSharingLocation() async {
    // 实现停止位置共享逻辑
  }
}
