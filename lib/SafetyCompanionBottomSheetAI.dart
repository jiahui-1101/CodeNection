import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  bool _isResponding = false;
  String _recognizedText = "Tap the mic and start speaking…";
  final String _apiKey = "AIzaSyDMAuyquC_htfp_w5Q1n-NA1Hg3ccBeXeU";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();

    // Configure TTS
    _tts.setLanguage('en-US');
    _tts.setPitch(1.0);
    _tts.setSpeechRate(0.5);
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

  Future<String> _getGeminiResponse(String prompt) async {
    try {
      const url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

      final response = await http.post(
        Uri.parse('$url?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'You are a helpful safety companion. Provide concise, supportive responses focused on safety and well-being. Keep responses under 150 words.'
                },
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 300,
            'topP': 0.8,
            'topK': 40,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if the response contains candidates
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty && 
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          
          return data['candidates'][0]['content']['parts'][0]['text'];
        } else if (data['promptFeedback'] != null) {
          // Handle cases where the prompt was blocked
          throw Exception('Prompt was blocked due to safety concerns');
        } else {
          throw Exception('Unexpected response format from Gemini API');
        }
      } else {
        debugPrint('Gemini API Error: ${response.statusCode} - ${response.body}');
        
        // Handle specific HTTP errors
        if (response.statusCode == 400) {
          throw Exception('Bad request - check your API key and parameters');
        } else if (response.statusCode == 403) {
          throw Exception('API key is invalid or has insufficient permissions');
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded - try again later');
        } else if (response.statusCode >= 500) {
          throw Exception('Server error - try again later');
        } else {
          throw Exception('Failed to get response: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Error in _getGeminiResponse: $e');
      rethrow;
    }
  }

  Future<void> _respondToUser(String userText) async {
    if (userText.isEmpty) return;

    setState(() => _isResponding = true);

    try {
      final response = await _getGeminiResponse(userText);
      setState(() {
        _recognizedText = response;
      });
      await _tts.speak(response);
    } catch (e) {
      debugPrint('Error in _respondToUser: $e');
      setState(() {
        _recognizedText = "Sorry, I'm having trouble connecting. Please try again. Error: ${e.toString()}";
      });
      await _tts.speak("Sorry, I'm having trouble connecting. Please try again.");
    } finally {
      setState(() => _isResponding = false);
    }
  }

  Widget _buildMicButton() {
    if (_isResponding) {
      return const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
      );
    }
    return Icon(
      _isListening ? Icons.mic : Icons.mic_none,
      color: _isListening ? Colors.red : Colors.orange,
      size: 48,
    );
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
                  'Safety Companion (Gemini)',
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
          _isResponding
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                )
              : Text(
                  _recognizedText,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
          const SizedBox(height: 20),
          IconButton(
            iconSize: 48,
            icon: _buildMicButton(),
            onPressed:
                _isResponding ? null : _isListening ? _stopListening : _startListening,
          ),
          const SizedBox(height: 8),
          Text(
            _isResponding
                ? "Processing..."
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