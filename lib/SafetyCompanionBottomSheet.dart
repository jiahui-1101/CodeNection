import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class SafetyCompanionBottomSheet extends StatefulWidget {
  const SafetyCompanionBottomSheet({super.key});

  @override
  State<SafetyCompanionBottomSheet> createState() => _SafetyCompanionBottomSheetState();
}

class _SafetyCompanionBottomSheetState extends State<SafetyCompanionBottomSheet> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int _currentMessageIndex = 0;
  double _volume = 1.0; // Volume level (0.0 to 1.0)
  
  final List<String> _encouragingMessages = [
    'audio/mom_encouragement.mp3',
    'audio/dad_support.mp3',
    'audio/friend_cheer.mp3',
  ];

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    _setMaxVolume(); // Set max volume when initialized
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _playNextMessage();
      });
    });
  }

  Future<void> _setMaxVolume() async {
    try {
      await _audioPlayer.setVolume(1.0); // Set to maximum volume (1.0)
      setState(() {
        _volume = 1.0;
      });
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  Future<void> _increaseVolume() async {
    double newVolume = (_volume + 0.1).clamp(0.0, 1.0);
    try {
      await _audioPlayer.setVolume(newVolume);
      setState(() {
        _volume = newVolume;
      });
    } catch (e) {
      print('Error increasing volume: $e');
    }
  }

  Future<void> _decreaseVolume() async {
    double newVolume = (_volume - 0.1).clamp(0.0, 1.0);
    try {
      await _audioPlayer.setVolume(newVolume);
      setState(() {
        _volume = newVolume;
      });
    } catch (e) {
      print('Error decreasing volume: $e');
    }
  }

  Future<void> _playNextMessage() async {
    await Future.delayed(const Duration(seconds: 30));
    if (mounted) {
      setState(() {
        _currentMessageIndex = (_currentMessageIndex + 1) % _encouragingMessages.length;
      });
      await _playAudio(_encouragingMessages[_currentMessageIndex]);
    }
  }

  Future<void> _playAudio(String audioPath) async {
    try {
      // Set volume before playing
      await _audioPlayer.setVolume(_volume);
      
      setState(() {
        _isPlaying = true;
      });
      
      // Use AssetSource with the correct path
      await _audioPlayer.play(AssetSource(audioPath));
    } catch (e) {
      print('Error playing audio: $e');
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not play audio")),
        );
      }
    }
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  String _getMessageName(String path) {
    final Map<String, String> messageNames = {
      'audio/mom_encouragement.mp3': "Mom's Voice",
      'audio/dad_support.mp3': "Dad's Voice",
      'audio/friend_cheer.mp3': "Friend's Voice",
    };
    return messageNames[path] ?? 'Encouragement';
  }

  String _getVolumeIcon() {
    if (_volume == 0.0) return '🔇';
    if (_volume <= 0.3) return '🔈';
    if (_volume <= 0.6) return '🔉';
    return '🔊';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Virtual Safety Companion',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          
          // Volume Control Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.volume_down, color: Colors.blue),
                onPressed: _decreaseVolume,
              ),
              Text(
                '${_getVolumeIcon()} ${(_volume * 100).toInt()}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.blue),
                onPressed: _increaseVolume,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Playback Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 32,
                  color: Colors.blue,
                ),
                onPressed: _isPlaying ? _stopAudio : () => _playAudio(_encouragingMessages[_currentMessageIndex]),
              ),
              Text(
                _getMessageName(_encouragingMessages[_currentMessageIndex]),
                style: const TextStyle(fontSize: 14),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 32, color: Colors.blue),
                onPressed: () {
                  setState(() {
                    _currentMessageIndex = (_currentMessageIndex + 1) % _encouragingMessages.length;
                  });
                  _playAudio(_encouragingMessages[_currentMessageIndex]);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Hear encouraging messages during your walk',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}