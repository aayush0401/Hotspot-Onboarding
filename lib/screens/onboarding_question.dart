import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import '../providers/state_providers.dart';
import '../providers/recording_provider.dart';
import '../services/audio_recording_service.dart';
import '../widgets/audio_waveform.dart';

class OnboardingQuestionScreen extends ConsumerStatefulWidget {
  const OnboardingQuestionScreen({super.key});

  @override
  ConsumerState<OnboardingQuestionScreen> createState() => _OnboardingQuestionScreenState();
}

class _OnboardingQuestionScreenState extends ConsumerState<OnboardingQuestionScreen> {
  final AudioRecordingService _audioService = AudioRecordingService();
  Timer? _amplitudeTimer;
  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();
  CameraController? _cameraController;
  List<CameraDescription>? _availableCameras;
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _amplitudeTimer?.cancel();
    _amplitudeController.close();
    _audioService.dispose();
    _cameraController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _startAudioRecording() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio recording not supported on web')),
      );
      return;
    }
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
        return;
      }
      
      final filename = 'audio_${DateTime.now().millisecondsSinceEpoch}';
      await _audioService.startRecording(filename);
      ref.read(isRecordingAudioProvider.notifier).state = true;
      
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
        final amplitude = await _audioService.getAmplitude();
        if (!_amplitudeController.isClosed) {
          _amplitudeController.add(amplitude);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _stopAudioRecording() async {
    try {
      _amplitudeTimer?.cancel();
      final path = await _audioService.stopRecording();
      ref.read(isRecordingAudioProvider.notifier).state = false;
      
      if (path != null) {
        ref.read(recordedAudioProvider.notifier).state = File(path);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _cancelAudioRecording() async {
    _amplitudeTimer?.cancel();
    await _audioService.cancelRecording();
    ref.read(isRecordingAudioProvider.notifier).state = false;
  }

  Future<void> _deleteAudio() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Audio?'),
        content: const Text('Are you sure you want to delete this audio recording?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final audioFile = ref.read(recordedAudioProvider);
      if (audioFile != null && audioFile.existsSync()) {
        await audioFile.delete();
      }
      ref.read(recordedAudioProvider.notifier).state = null;
    }
  }

  Future<void> _initCameras() async {
    try {
      _availableCameras ??= await availableCameras();
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video recording not supported on web')),
      );
      return;
    }
    
    try {
      final camStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();
      
      if (!camStatus.isGranted || !micStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera and microphone permissions required')),
          );
        }
        return;
      }

      await _initCameras();
      if ((_availableCameras ?? []).isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No camera available')),
          );
        }
        return;
      }

      final camera = _availableCameras!.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      await _cameraController!.startVideoRecording();
      ref.read(isRecordingVideoProvider.notifier).state = true;
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video error: $e')),
        );
      }
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) {
      return;
    }

    try {
      final file = await _cameraController!.stopVideoRecording();
      ref.read(isRecordingVideoProvider.notifier).state = false;
      ref.read(recordedVideoProvider.notifier).state = File(file.path);
      
      await _initVideoPlayer(File(file.path));
      setState(() {});
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _cancelVideoRecording() async {
    if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
      try {
        await _cameraController!.stopVideoRecording();
      } catch (e) {
        debugPrint('Cancel error: $e');
      }
    }
    ref.read(isRecordingVideoProvider.notifier).state = false;
    setState(() {});
  }

  Future<void> _initVideoPlayer(File videoFile) async {
    try {
      await _videoController?.dispose();
      _videoController = VideoPlayerController.file(videoFile);
      await _videoController!.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('Video player error: $e');
    }
  }

  Future<void> _deleteVideo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Video?'),
        content: const Text('Are you sure you want to delete this video recording?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final videoFile = ref.read(recordedVideoProvider);
      if (videoFile != null && videoFile.existsSync()) {
        await videoFile.delete();
      }
      ref.read(recordedVideoProvider.notifier).state = null;
      await _videoController?.dispose();
      _videoController = null;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRecAudio = ref.watch(isRecordingAudioProvider);
    final isRecVideo = ref.watch(isRecordingVideoProvider);
    final audioFile = ref.watch(recordedAudioProvider);
    final videoFile = ref.watch(recordedVideoProvider);
    final questionText = ref.watch(questionTextProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about yourself',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You can answer using text, audio, or video.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFB0B0B0),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        maxLines: 6,
                        maxLength: 600,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Type your answer here...',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                        onChanged: (value) {
                          ref.read(questionTextProvider.notifier).state = value;
                        },
                      ),
                      const SizedBox(height: 24),
                      if (isRecVideo && _cameraController != null && _cameraController!.value.isInitialized)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recording Video...',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 240,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red, width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CameraPreview(_cameraController!),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      if (videoFile != null && _videoController != null && _videoController!.value.isInitialized && !isRecVideo)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Video Answer',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green, width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AspectRatio(
                                  aspectRatio: _videoController!.value.aspectRatio,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      VideoPlayer(_videoController!),
                                      Positioned.fill(
                                        child: Center(
                                          child: IconButton(
                                            iconSize: 64,
                                            icon: Icon(
                                              _videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                              color: Colors.white,
                                            ),
                                            onPressed: () async {
                                              if (_videoController!.value.isPlaying) {
                                                await _videoController!.pause();
                                              } else {
                                                await _videoController!.play();
                                              }
                                              setState(() {});
                                            },
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        child: VideoProgressIndicator(
                                          _videoController!,
                                          allowScrubbing: true,
                                          colors: const VideoProgressColors(
                                            playedColor: Colors.green,
                                            backgroundColor: Colors.white24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      if (isRecAudio)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recording Audio...',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red, width: 2),
                              ),
                              child: AudioWaveform(
                                amplitudeStream: _amplitudeController.stream,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      if (audioFile != null && !isRecAudio)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Audio Answer',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green, width: 2),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.audiotrack, color: Colors.green, size: 32),
                                  SizedBox(width: 12),
                                  Text(
                                    'Audio recorded successfully',
                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (audioFile == null) ...[
                    if (!isRecAudio)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _startAudioRecording,
                          icon: const Icon(Icons.mic),
                          label: const Text('Audio'),
                        ),
                      )
                    else
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _cancelAudioRecording,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Icon(Icons.close, size: 20),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _stopAudioRecording,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Icon(Icons.stop, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ] else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deleteAudio,
                        icon: const Icon(Icons.delete, size: 20),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
                      ),
                    ),
                  const SizedBox(width: 12),
                  if (videoFile == null) ...[
                    if (!isRecVideo)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _startVideoRecording,
                          icon: const Icon(Icons.videocam),
                          label: const Text('Video'),
                        ),
                      )
                    else
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _cancelVideoRecording,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Icon(Icons.close, size: 20),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _stopVideoRecording,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Icon(Icons.stop, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ] else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deleteVideo,
                        icon: const Icon(Icons.delete, size: 20),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint('=== SUBMISSION ===');
                    debugPrint('Question Text: $questionText');
                    debugPrint('Audio File: ${audioFile?.path}');
                    debugPrint('Video File: ${videoFile?.path}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(' Submitted successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
