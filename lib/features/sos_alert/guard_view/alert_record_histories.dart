import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:async';

class RecordingsPage extends StatefulWidget {
  final String alertId;
  const RecordingsPage({super.key, required this.alertId});

  @override
  State<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingDocId;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isSeeking = false;
  bool _isLoading = false;
  bool _isCompleted = false;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration?>? _durationSub;

  @override
  void initState() {
    super.initState();
    _initAudioSession();
    _listenPlayer();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
    await session.setActive(true); // 激活音频会话
    print("AudioSession configured & activated ✅");
  }

  void _listenPlayer() {
    // 监听播放状态
    _audioPlayer.playerStateStream.listen((state) {
      if (_currentlyPlayingDocId != null) {
        if (state.processingState == ProcessingState.loading) {
          // 只有 setUrl 之后才 loading
          setState(() => _isLoading = true);
        } else if (state.processingState == ProcessingState.ready) {
          setState(() => _isLoading = false);
        } else if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isCompleted = true;
            _isLoading = false;
            _currentPosition = Duration.zero;
          });
        }
      }
    });

    // 监听音频时长（只更新一次总时长）
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _durationSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
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
            setState(() {
              _isCompleted = false;
              _currentPosition = Duration.zero;
            });
          }
          await _audioPlayer.play();
        }
      } else {
        // 新音频
        setState(() {
          _isLoading = true;
          _currentlyPlayingDocId = docId;
          _currentPosition = Duration.zero;
          _isCompleted = false;
        });

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
    if (d == null || d.inSeconds < 0) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Audio Recordings")),
      body: StreamBuilder<QuerySnapshot>(
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
          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading audio: ${snapshot.error}"),
            );
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
              final isPlaying = _currentlyPlayingDocId == audioDocs[index].id;
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
                        onPressed: url != null
                            ? () => _playRecording(url, audioDocs[index].id)
                            : null,
                      ),
                    ),
                    if (isPlaying) ...[
                      // 加载指示器
                      if (isCurrentLoading)
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: LinearProgressIndicator(),
                        ),

                      // 播放控制条 (仅在非加载状态显示)
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
                                    // 只更新 UI，不立即 seek
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
                                      await _audioPlayer.play(); // 确保 seek 后继续播
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
      ),
    );
  }
}
