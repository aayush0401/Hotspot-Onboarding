import 'package:flutter_riverpod/flutter_riverpod.dart';

final experienceTextProvider = StateProvider<String>((ref) => ''); // 250 chars for experience screen
final questionTextProviderEx = StateProvider<String>((ref) => ''); // 600 chars for onboarding question
