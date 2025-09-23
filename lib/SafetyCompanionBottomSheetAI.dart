import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_ai/firebase_ai.dart';

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
  late GenerativeModel _model;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isListening = false;
  bool _isResponding = false;
  bool _isSpeaking = false; // New flag to track TTS state
  String _recognizedText = "Tap the mic and start speaking…";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();

    _tts.setLanguage('en-US');
    _tts.setPitch(1.0);
    _tts.setSpeechRate(0.5);
    
    // Set up TTS event handlers
    _tts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });
    
    _tts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
        _isResponding = false;
      });
      if (!_isListening) {
        _startListening();
      }
    });
    
    _tts.setErrorHandler((message) {
      setState(() {
        _isSpeaking = false;
        _isResponding = false;
      });
    });

    // initialize Gemini via Firebase AI
    _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('STT status: $status'),
      onError: (error) => debugPrint('STT error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });

          if (result.finalResult) {
            _respondToUser(_recognizedText);
          }
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<String> _getGeminiResponse(String prompt) async {
    try {
      final response = await _model.generateContent([
        Content.text(
          'You are a helpful safety companion. Provide concise, supportive responses focused on safety and well-being. Keep responses under 150 words.',
        ),
        Content.text(prompt),
      ]);
      return response.text ?? "I couldn't generate a response.";
    } catch (e) {
      debugPrint('Gemini error: $e');
      throw Exception("Error fetching Gemini response: $e");
    }
  }

  Future<void> _respondToUser(String userText) async {
    if (userText.isEmpty) return;

    setState(() {
      _isResponding = true;
      _isListening = false; // ensure reset
    });

    try {
      final response = await _getGeminiResponse(userText);
      setState(() {
        _recognizedText = response;
      });

      await _tts.speak(response);
    } catch (e) {
      debugPrint('Error in _respondToUser: $e');
      setState(() {
        _recognizedText =
            "Sorry, I'm having trouble connecting. Please try again. Error: ${e.toString()}";
      });

      await _tts.speak(
        "Sorry, I'm having trouble connecting. Please try again.",
      );
    }
  }

  Widget _buildMicButton() {
    if (_isSpeaking) {
      return const Icon(
        Icons.volume_up,
        color: Colors.blue,
        size: 48,
      );
    } else {
      return Icon(
        _isListening ? Icons.mic : Icons.mic_none,
        color: _isListening ? Colors.red : Colors.orange,
        size: 48,
      );
    }
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
                  'AI Live Chat (Gemini)',
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
          Text(
            _recognizedText,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          IconButton(
            iconSize: 48,
            icon: _buildMicButton(),
            onPressed: (_isResponding || _isSpeaking)
                ? null
                : _isListening
                    ? _stopListening
                    : _startListening,
          ),
          const SizedBox(height: 8),
          Text(
            _isResponding
                ? "Processing..."
                : _isSpeaking
                    ? "AI is speaking..."
                    : _isListening
                        ? "Listening…"
                        : "Tap to talk",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}