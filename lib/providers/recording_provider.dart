import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recordedAudioProvider = StateProvider<File?>((ref) => null);
final recordedVideoProvider = StateProvider<File?>((ref) => null);

final isRecordingAudioProvider = StateProvider<bool>((ref) => false);
final isRecordingVideoProvider = StateProvider<bool>((ref) => false);
