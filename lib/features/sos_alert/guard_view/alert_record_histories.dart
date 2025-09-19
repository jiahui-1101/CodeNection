// 文件名: recordings_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
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

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _initAudioSession();
    _listenPlayer();
  }

  /// 初始化 AudioSession，确保 Android/iOS 播放正常
  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
  }

  /// 监听播放状态和位置
  void _listenPlayer() {
    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _currentlyPlayingDocId = null;
          _currentPosition = Duration.zero;
        });
      }
    });

    _positionSub = _audioPlayer.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _currentPosition = pos);
    });

    _audioPlayer.durationStream.listen((dur) {
      if (!mounted) return;
      setState(() => _totalDuration = dur ?? Duration.zero);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// 播放/暂停指定音频
  Future<void> _playRecording(String url, String docId) async {
    try {
      if (_currentlyPlayingDocId == docId) {
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(url)));
        await _audioPlayer.play();
        setState(() => _currentlyPlayingDocId = docId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error playing audio: $e")),
      );
    }
  }

  String _formatDuration(Duration d) {
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
            return Center(child: Text("Error loading audio: ${snapshot.error}"));
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
              final isPlaying = _currentlyPlayingDocId == audioDocs[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.mic),
                      title: Text(uploadedAt != null
                          ? "Recording at ${TimeOfDay.fromDateTime(uploadedAt).format(context)}"
                          : "Recording"),
                      trailing: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          size: 30,
                        ),
                        onPressed: url != null
                            ? () => _playRecording(url, audioDocs[index].id)
                            : null,
                      ),
                    ),
                    if (isPlaying)
                      Column(
                        children: [
                          Slider(
                            min: 0,
                            max: _totalDuration.inMilliseconds > 0
                                ? _totalDuration.inMilliseconds.toDouble()
                                : 1.0,
                            value: _currentPosition.inMilliseconds
                                .clamp(0, _totalDuration.inMilliseconds)
                                .toDouble(),
                            onChanged: (value) async {
                              await _audioPlayer
                                  .seek(Duration(milliseconds: value.toInt()));
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0)
                                .copyWith(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(_currentPosition)),
                                Text(_formatDuration(_totalDuration)),
                              ],
                            ),
                          ),
                        ],
                      ),
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
