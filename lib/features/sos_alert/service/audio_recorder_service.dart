import 'dart:io';
import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AudioRecorderService {
  final String documentId;
  final bool isAlert;
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  Timer? _recordingTimer;
  String? _currentFilePath;

  AudioRecorderService(this.documentId, {this.isAlert = false});

  // ✅ 核心修改：统一路径逻辑，尽管这里只用到了 'alerts'
  String get collectionPath => isAlert ? 'alerts' : 'guards';

  Future<void> initRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  Future<void> startRecording() async {
    if (_recorder == null || _isRecording) return;
    
    _isRecording = true;
    _cycleRecordingChunk(); 

    _recordingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      _cycleRecordingChunk();
    });
  }
  
  Future<void> _cycleRecordingChunk() async {
    if (_recorder == null || !_isRecording) return;

    String? path;
    if (_recorder!.isRecording) {
      path = await _recorder!.stopRecorder();
    }
    
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        try {
          final storageFileName = "${DateTime.now().millisecondsSinceEpoch}.aac";
          final ref = FirebaseStorage.instance
              .ref("alert_audio/$documentId/$storageFileName");

          UploadTask uploadTask = ref.putFile(file);
          TaskSnapshot snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();

          // 这段逻辑只在 isAlert=true 时被调用，所以 collectionPath 一定是 'alerts'
          await FirebaseFirestore.instance
              .collection(collectionPath)
              .doc(documentId)
              .collection("audio")
              .add({
            "url": downloadUrl,
            "uploadedAt": FieldValue.serverTimestamp(),
          });
          
          print("✅ Audio chunk uploaded successfully: $downloadUrl");
          
          await file.delete();
        } catch (e) {
          print("❌ Failed to upload audio chunk: $e");
        }
      }
    }

    if (_isRecording) {
      Directory tempDir = await getTemporaryDirectory();
      final newFileName = '${DateTime.now().millisecondsSinceEpoch}.aac';
      _currentFilePath = '${tempDir.path}/$newFileName';
      await _recorder!.startRecorder(toFile: _currentFilePath);
    }
  }

  Future<void> stopAndUpload() async {
    if (!_isRecording) return;
    _isRecording = false; 
    _recordingTimer?.cancel();

    await _cycleRecordingChunk();
  }

  Future<void> dispose() async {
    _recordingTimer?.cancel();
    if (_isRecording) {
      await stopAndUpload();
    }
    await _recorder?.closeRecorder();
    _recorder = null;
  }
}