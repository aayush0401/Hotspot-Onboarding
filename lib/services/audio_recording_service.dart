import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start recording audio to a file
  Future<void> startRecording(String filename) async {
    try {
      if (!await hasPermission()) {
        throw Exception('Microphone permission not granted');
      }

      // Get app directory for saving audio
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$filename.m4a';

      if (kDebugMode) {
        print('🎤 [AudioRecording] Starting recording to: $path');
      }

      // Configure audio settings
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc, // AAC format (good quality, small size)
        bitRate: 128000, // 128 kbps
        sampleRate: 44100, // CD quality
      );

      await _recorder.start(config, path: path);
      _isRecording = true;

      if (kDebugMode) {
        print('✅ [AudioRecording] Recording started successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AudioRecording] Error starting recording: $e');
      }
      rethrow;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        if (kDebugMode) {
          print('⚠️ [AudioRecording] Not currently recording');
        }
        return null;
      }

      final path = await _recorder.stop();
      _isRecording = false;

      if (kDebugMode) {
        print('✅ [AudioRecording] Recording stopped. File saved to: $path');
      }

      return path;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AudioRecording] Error stopping recording: $e');
      }
      _isRecording = false;
      rethrow;
    }
  }

  /// Cancel recording without saving
  Future<void> cancelRecording() async {
    try {
      await _recorder.cancel();
      _isRecording = false;

      if (kDebugMode) {
        print('🚫 [AudioRecording] Recording cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AudioRecording] Error cancelling recording: $e');
      }
      rethrow;
    }
  }

  /// Get amplitude for waveform visualization (0.0 to 1.0)
  Future<double> getAmplitude() async {
    try {
      if (!_isRecording) return 0.0;

      final amplitude = await _recorder.getAmplitude();
      // Normalize current amplitude to 0.0 - 1.0 range
      // amplitude.current is in dBFS (typically -160 to 0)
      final normalized = (amplitude.current + 50) / 50;
      return normalized.clamp(0.0, 1.0);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AudioRecording] Error getting amplitude: $e');
      }
      return 0.0;
    }
  }

  /// Dispose recorder resources
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
