import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hello_flutter/SafetyCompanionBottomSheetAI.dart';

// ---------------------------------------------------------
// MODE ENUM
// ---------------------------------------------------------
enum CompanionMode { selection, vc, ai }

// ---------------------------------------------------------
// WRAPPER (switches between selection / VC / AI)
// ---------------------------------------------------------
class SafetyCompanionBottomSheetWrapper extends StatefulWidget {
  const SafetyCompanionBottomSheetWrapper({super.key});

  @override
  State<SafetyCompanionBottomSheetWrapper> createState() =>
      _SafetyCompanionBottomSheetWrapperState();
}

class _SafetyCompanionBottomSheetWrapperState
    extends State<SafetyCompanionBottomSheetWrapper> {
  CompanionMode _mode = CompanionMode.selection;

  void _resetToSelection() {
    setState(() {
      _mode = CompanionMode.selection;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
      case CompanionMode.selection:
        return _buildSelectionUI();
      case CompanionMode.vc:
        return SafetyCompanionBottomSheetVC(onBack: _resetToSelection);
      case CompanionMode.ai:
        return SafetyCompanionBottomSheetAI(onBack: _resetToSelection);
    }
  }

  Widget _buildSelectionUI() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            "Choose Your Companion",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => setState(() => _mode = CompanionMode.vc),
            icon: const Icon(Icons.record_voice_over, color: Colors.white),
            label: const Text(
              "Virtual Companion Voice",
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => setState(() => _mode = CompanionMode.ai),
            icon: const Icon(Icons.smart_toy, color: Colors.white),
            label: const Text(
              "AI Live Chat",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// BASE CLASS
// ---------------------------------------------------------
abstract class SafetyCompanionBottomSheet extends StatelessWidget {
  final List<String> encouragingMessages;
  final Map<String, String> messageNames;
  final VoidCallback? onBack;

  const SafetyCompanionBottomSheet({
    super.key,
    required this.encouragingMessages,
    required this.messageNames,
    this.onBack,
  });

  String getMessageName(String path) {
    return messageNames[path] ?? 'Encouragement';
  }
}

// ---------------------------------------------------------
// VIRTUAL COMPANION (with audio)
// ---------------------------------------------------------
class SafetyCompanionBottomSheetVC extends StatefulWidget {
  final VoidCallback? onBack;
  const SafetyCompanionBottomSheetVC({super.key, this.onBack});

  @override
  State<SafetyCompanionBottomSheetVC> createState() =>
      _SafetyCompanionBottomSheetVCState();
}

class _SafetyCompanionBottomSheetVCState
    extends State<SafetyCompanionBottomSheetVC> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int _currentMessageIndex = 0;
  double _volume = 1.0;

  // Updated to use numbered MP3 files
  final List<String> encouragingMessages = List.generate(
    13,
    (index) => 'audio/${index + 1}.mp3',
  );

  // Updated message names for numbered files
  final Map<String, String> messageNames = {
    for (int i = 1; i <= 13; i++) 'audio/$i.mp3': 'Encouragement $i',
  };

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    _setMaxVolume();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
      });
    });
  }

  Future<void> _setMaxVolume() async {
    await _audioPlayer.setVolume(1.0);
    setState(() {
      _volume = 1.0;
    });
  }

  Future<void> _increaseVolume() async {
    double newVolume = (_volume + 0.1).clamp(0.0, 1.0);
    await _audioPlayer.setVolume(newVolume);
    setState(() {
      _volume = newVolume;
    });
  }

  Future<void> _decreaseVolume() async {
    double newVolume = (_volume - 0.1).clamp(0.0, 1.0);
    await _audioPlayer.setVolume(newVolume);
    setState(() {
      _volume = newVolume;
    });
  }

  Future<void> _playAudio(String audioPath) async {
    await _audioPlayer.setVolume(_volume);
    setState(() {
      _isPlaying = true;
    });
    await _audioPlayer.play(AssetSource(audioPath));
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
    });
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
          Row(
            children: [
              if (widget.onBack != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.blue),
                  onPressed: widget.onBack,
                ),
              const Expanded(
                child: Text(
                  'Virtual Companion Voice',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.volume_down, color: Colors.blue),
                onPressed: _decreaseVolume,
              ),
              Text(
                '${_getVolumeIcon()} ${(_volume * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.blue),
                onPressed: _increaseVolume,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 32,
                  color: Colors.blue,
                ),
                onPressed: _isPlaying
                    ? _stopAudio
                    : () =>
                          _playAudio(encouragingMessages[_currentMessageIndex]),
              ),
              Text(
                messageNames[encouragingMessages[_currentMessageIndex]] ??
                    'Encouragement',
                style: const TextStyle(fontSize: 14),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 32, color: Colors.blue),
                onPressed: () {
                  setState(() {
                    _currentMessageIndex =
                        (_currentMessageIndex + 1) % encouragingMessages.length;
                  });
                  _playAudio(encouragingMessages[_currentMessageIndex]);
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
