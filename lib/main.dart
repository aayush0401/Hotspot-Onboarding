import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/experience_selection.dart';
import 'providers/experience_provider.dart';
import 'services/mock_api_service.dart';

// Design tokens
const _bgColor = Color(0xFF0E0E0E);
const _primaryText = Color(0xFFFFFFFF);
const _secondaryText = Color(0xFFB0B0B0);
const _accentBlue = Color(0xFF2196F3);

// Enable using a mock API at build time with --dart-define=USE_MOCK=true
const bool _useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

void main() {
  if (_useMock) {
    runApp(ProviderScope(overrides: [apiServiceProvider.overrideWithValue(MockApiService())], child: const HotspotApp()));
  } else {
    runApp(const ProviderScope(child: HotspotApp()));
  }
}

class HotspotApp extends StatelessWidget {
  const HotspotApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: _primaryText, displayColor: _primaryText);

    return MaterialApp(
      title: 'Hotspot Onboarding',
      theme: base.copyWith(
        scaffoldBackgroundColor: _bgColor,
        primaryColor: _accentBlue,
        colorScheme: base.colorScheme.copyWith(primary: _accentBlue, background: _bgColor),
        appBarTheme: const AppBarTheme(backgroundColor: _bgColor, elevation: 0),
        textTheme: textTheme,
        primaryTextTheme: textTheme,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentBlue,
            foregroundColor: _primaryText,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF141414),
          hintStyle: TextStyle(color: _secondaryText),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
      home: const ExperienceSelectionScreen(),
    );
  }
}
