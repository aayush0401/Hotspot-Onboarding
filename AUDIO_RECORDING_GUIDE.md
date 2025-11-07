# Audio Recording Implementation Guide

## Overview
This guide will help you implement audio recording with waveform visualization using the `record` package (already added to pubspec.yaml).

---

## Step 1: Create Audio Recording Service

Create `lib/services/audio_recording_service.dart`:

```dart
import 'dart:io';
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
        print('[AudioRecording] Starting recording to: $path');
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
        print('[AudioRecording] Recording started successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AudioRecording] Error starting recording: $e');
      }
      rethrow;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        if (kDebugMode) {
          print('[AudioRecording] Not currently recording');
        }
        return null;
      }

      final path = await _recorder.stop();
      _isRecording = false;

      if (kDebugMode) {
        print('[AudioRecording] Recording stopped. File saved to: $path');
      }

      return path;
    } catch (e) {
      if (kDebugMode) {
        print('[AudioRecording] Error stopping recording: $e');
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
        print('[AudioRecording] Recording cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AudioRecording] Error cancelling recording: $e');
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
        print('[AudioRecording] Error getting amplitude: $e');
      }
      return 0.0;
    }
  }

  /// Dispose recorder resources
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
```

---

## Step 2: Create Waveform Widget

Create `lib/widgets/audio_waveform.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';

class AudioWaveform extends StatefulWidget {
  final Stream<double> amplitudeStream;
  final Color color;
  final int maxBars;

  const AudioWaveform({
    super.key,
    required this.amplitudeStream,
    this.color = Colors.blue,
    this.maxBars = 50,
  });

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform> {
  final List<double> _amplitudes = [];
  StreamSubscription<double>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.amplitudeStream.listen((amplitude) {
      setState(() {
        _amplitudes.add(amplitude);
        if (_amplitudes.length > widget.maxBars) {
          _amplitudes.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          _amplitudes.length,
          (index) {
            final amplitude = _amplitudes[index];
            return Container(
              width: 3,
              height: 80 * amplitude,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

## Step 3: Update Recording Provider

Add to `lib/providers/recording_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Audio recording state
final recordedAudioProvider = StateProvider<String?>((ref) => null);
final isRecordingAudioProvider = StateProvider<bool>((ref) => false);
final audioAmplitudeProvider = StateProvider<double>((ref) => 0.0);
```

---

## Step 4: Integrate into Onboarding Question Screen

Update `lib/screens/onboarding_question.dart`:

```dart
// Add imports
import '../services/audio_recording_service.dart';
import '../widgets/audio_waveform.dart';
import 'dart:async';

// Add these variables to your State class
final AudioRecordingService _audioService = AudioRecordingService();
Timer? _amplitudeTimer;
final StreamController<double> _amplitudeController = StreamController<double>.broadcast();

// Add this method to start audio recording
Future<void> _startAudioRecording() async {
  if (kIsWeb) {
    if (kDebugMode) {
      print('Audio recording on web — operation skipped.');
    }
    return;
  }

  try {
    // Check permission
    if (!await _audioService.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
      return;
    }

    // Start recording
    final filename = 'audio_${DateTime.now().millisecondsSinceEpoch}';
    await _audioService.startRecording(filename);

    ref.read(isRecordingAudioProvider.notifier).state = true;

    // Start amplitude polling for waveform
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      final amplitude = await _audioService.getAmplitude();
      _amplitudeController.add(amplitude);
      ref.read(audioAmplitudeProvider.notifier).state = amplitude;
    });

    if (kDebugMode) {
      print('Audio recording started');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error starting audio recording: $e');
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

// Add this method to stop audio recording
Future<void> _stopAudioRecording() async {
  try {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;

    final path = await _audioService.stopRecording();
    ref.read(isRecordingAudioProvider.notifier).state = false;

    if (path != null) {
      ref.read(recordedAudioProvider.notifier).state = path;
      if (kDebugMode) {
        print('Audio recording saved to: $path');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error stopping audio recording: $e');
    }
  }
}

// Add this method to cancel audio recording
Future<void> _cancelAudioRecording() async {
  try {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;

    await _audioService.cancelRecording();
    ref.read(isRecordingAudioProvider.notifier).state = false;

    if (kDebugMode) {
      print('Audio recording cancelled');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error cancelling audio recording: $e');
    }
  }
}

// Add to dispose method
@override
void dispose() {
  _amplitudeTimer?.cancel();
  _amplitudeController.close();
  _audioService.dispose();
  super.dispose();
}
```

---

## Step 5: Add UI for Audio Recording

In your build method, add the audio recording button:

```dart
// Replace the old audio recording button section with this
final isRecordingAudio = ref.watch(isRecordingAudioProvider);
final recordedAudio = ref.watch(recordedAudioProvider);

// Show recording button only if no audio is recorded yet
if (recordedAudio == null) {
  Column(
    children: [
      // Show waveform while recording
      if (isRecordingAudio)
        AudioWaveform(
          amplitudeStream: _amplitudeController.stream,
          color: Colors.red,
        ),
      
      // Recording controls
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cancel button (shown while recording)
          if (isRecordingAudio)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              iconSize: 32,
              onPressed: _cancelAudioRecording,
            ),
          
          // Record/Stop button
          IconButton(
            icon: Icon(
              isRecordingAudio ? Icons.stop : Icons.mic,
              color: isRecordingAudio ? Colors.red : Colors.white,
            ),
            iconSize: 48,
            onPressed: isRecordingAudio 
              ? _stopAudioRecording 
              : _startAudioRecording,
          ),
        ],
      ),
      
      Text(
        isRecordingAudio ? 'Recording...' : 'Tap to record audio',
        style: const TextStyle(color: Colors.white70),
      ),
    ],
  ),
} else {
  // Show playback controls when audio is recorded
  Column(
    children: [
      const Icon(Icons.audiotrack, color: Colors.green, size: 48),
      const SizedBox(height: 8),
      const Text('Audio recorded', style: TextStyle(color: Colors.green)),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              // Delete audio file and reset state
              final file = File(recordedAudio);
              file.deleteSync();
              ref.read(recordedAudioProvider.notifier).state = null;
            },
          ),
          // Re-record button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: () {
              // Delete old recording and start new one
              final file = File(recordedAudio);
              file.deleteSync();
              ref.read(recordedAudioProvider.notifier).state = null;
              _startAudioRecording();
            },
          ),
        ],
      ),
    ],
  ),
}
```

---

## Step 6: Add Permissions (Already Done!)

The permissions are already configured in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

For iOS, you'll need to add to `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record audio answers</string>
```

---

## Testing Checklist

### After Implementation
- [ ] Audio recording starts when tapping mic button
- [ ] Waveform animates during recording (shows amplitude)
- [ ] Cancel button appears while recording
- [ ] Can cancel recording (doesn't save file)
- [ ] Can stop recording (saves file)
- [ ] Recording button disappears after saving
- [ ] Shows "Audio recorded" with green icon
- [ ] Delete button removes audio and resets UI
- [ ] Re-record button deletes old audio and starts new recording

### Error Handling
- [ ] Shows permission error if denied
- [ ] Handles recording errors gracefully
- [ ] Doesn't crash if user denies permission
- [ ] Cleans up resources on dispose

### Platform Support
- [ ] Works on Android
- [ ] Works on iOS
- [ ] Gracefully skips on Web (shows message)

---

## Expected Behavior

### Recording Flow
1. User taps **mic button** → Recording starts
2. **Waveform appears** showing real-time audio amplitude
3. User taps **stop button** → Recording saves
4. UI switches to show **playback controls**

### Cancel Flow
1. User taps **mic button** → Recording starts
2. Waveform animates
3. User taps **cancel (X) button** → Recording discarded
4. UI resets to initial state (mic button visible)

### Delete Flow
1. Audio is recorded and saved
2. User taps **delete button**
3. Confirmation dialog (optional): "Delete this recording?"
4. File deleted, UI resets to initial state

---

## Bonus: Add Audio Playback (Brownie Points)

To add playback functionality, install `audioplayers` package:

```yaml
dependencies:
  audioplayers: ^6.1.0
```

Then add playback button in the "Audio recorded" section:

```dart
import 'package:audioplayers/audioplayers.dart';

// In State class
final AudioPlayer _audioPlayer = AudioPlayer();
bool _isPlayingAudio = false;

Future<void> _playAudio(String path) async {
  try {
    if (_isPlayingAudio) {
      await _audioPlayer.stop();
      setState(() => _isPlayingAudio = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(path));
      setState(() => _isPlayingAudio = true);
      
      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() => _isPlayingAudio = false);
      });
    }
  } catch (e) {
    print('Error playing audio: $e');
  }
}

// In dispose
@override
void dispose() {
  _audioPlayer.dispose();
  // ... other disposals
  super.dispose();
}

// Add play button in UI
IconButton(
  icon: Icon(
    _isPlayingAudio ? Icons.pause : Icons.play_arrow,
    color: Colors.blue,
  ),
  onPressed: () => _playAudio(recordedAudio),
),
```

---

## File Sizes

Expected audio file sizes (60 seconds recording):
- **AAC 128 kbps**: ~960 KB
- **AAC 64 kbps**: ~480 KB (lower quality)
- **WAV uncompressed**: ~5.3 MB (very large)

**Recommendation**: Use AAC at 128 kbps for good quality/size balance.

---

## Common Issues & Solutions

### Issue: No waveform animation
**Solution**: Check if `getAmplitude()` is being called in the timer. Print amplitude values to debug.

### Issue: Permission denied
**Solution**: Make sure `RECORD_AUDIO` permission is in AndroidManifest and request at runtime.

### Issue: File not saved
**Solution**: Check if `getApplicationDocumentsDirectory()` returns valid path. Print the path.

### Issue: Waveform too sensitive/not sensitive
**Solution**: Adjust the normalization formula:
```dart
// More sensitive
final normalized = (amplitude.current + 40) / 40;

// Less sensitive
final normalized = (amplitude.current + 60) / 60;
```

---

## Estimated Implementation Time

- **Service creation**: 30 minutes
- **Waveform widget**: 20 minutes
- **UI integration**: 30 minutes
- **Testing & debugging**: 40 minutes

**Total**: ~2 hours

---

## Next Steps

1. ✅ Create `AudioRecordingService` class
2. ✅ Create `AudioWaveform` widget
3. ✅ Add providers for audio state
4. ✅ Integrate into `onboarding_question.dart`
5. ✅ Test on Android device
6. ✅ Test on iOS device
7. 🎁 **(Bonus)** Add playback with `audioplayers`
8. 🎁 **(Bonus)** Add playback waveform with progress indicator

---

**Last Updated**: 2025-01-13  
**Status**: Ready to implement  
**Estimated Completion**: 2 hours
