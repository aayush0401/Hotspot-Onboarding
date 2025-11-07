import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hotspot_onboarding/services/mock_api_service.dart';
import 'package:hotspot_onboarding/providers/experience_provider.dart';
import 'package:hotspot_onboarding/screens/experience_selection.dart';

void main() {
  testWidgets('ExperienceSelection shows mocked items via provider override', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(MockApiService()),
        ],
        child: const MaterialApp(home: ExperienceSelectionScreen()),
      ),
    );

    // Let async loads settle
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // We expect the mock items to appear as text
    expect(find.text('Dining'), findsOneWidget);
    expect(find.text('Guided Tours'), findsOneWidget);
    expect(find.text('Workshops'), findsOneWidget);
  });
}
