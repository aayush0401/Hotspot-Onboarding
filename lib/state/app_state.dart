import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/experience.dart';

final experiencesProvider = StateNotifierProvider<ExperiencesNotifier, List<Experience>>(
  (ref) => ExperiencesNotifier([]),
);

class ExperiencesNotifier extends StateNotifier<List<Experience>> {
  ExperiencesNotifier(List<Experience> state) : super(state);

  void setExperiences(List<Experience> list) => state = list;
}

final selectedExperiencesProvider = StateNotifierProvider<SelectedExperienceNotifier, List<int>>(
  (ref) => SelectedExperienceNotifier([]),
);

class SelectedExperienceNotifier extends StateNotifier<List<int>> {
  SelectedExperienceNotifier(List<int> state) : super(state);

  void toggle(int id) {
    if (state.contains(id)) {
      state = state.where((e) => e != id).toList();
    } else {
      state = [id, ...state]; // add to front (for optional animation)
    }
  }

  void set(List<int> ids) => state = ids;
}

final experiencesTextProvider = StateProvider<String>((ref) => '');
final questionTextProvider = StateProvider<String>((ref) => '');

final recordedAudioProvider = StateProvider<File?>((ref) => null);
final recordedVideoProvider = StateProvider<File?>((ref) => null);
