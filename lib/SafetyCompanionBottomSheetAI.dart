import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

class SafetyCompanionBottomSheetAI extends StatefulWidget {
  final VoidCallback? onBack;
  const SafetyCompanionBottomSheetAI({super.key, this.onBack});

  @override
  State<SafetyCompanionBottomSheetAI> createState() =>
      _SafetyCompanionBottomSheetAIState();
}

class _SafetyCompanionBottomSheetAIState
    extends State<SafetyCompanionBottomSheetAI> {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isListening = false;
  String _recognizedText = "Tap the mic and start speaking…";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('STT status: $status'),
      onError: (error) => debugPrint('STT error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });

        if (result.finalResult) {
          _respondToUser(_recognizedText);
        }
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _respondToUser(String userText) async {
    // Simple AI response (replace with your own logic / API call)
    String response = "You said: $userText. Stay safe, I’m here with you.";

    // Speak it out
    await _tts.speak(response);

    // (Optional) also play using audioplayers if you have pre-generated audio
    // await _audioPlayer.play(UrlSource('https://your-audio-file.mp3'));
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
                  icon: const Icon(Icons.arrow_back, color: Colors.orange),
                  onPressed: widget.onBack,
                ),
              const Expanded(
                child: Text(
                  'Safety Companion',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Display recognized speech
          Text(
            _recognizedText,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Mic button
          IconButton(
            iconSize: 48,
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : Colors.orange,
            ),
            onPressed: _isListening ? _stopListening : _startListening,
          ),
          const SizedBox(height: 8),
          Text(
            _isListening ? "Listening…" : "Tap to talk",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
