// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lf_kitchen/core/providers/theme_provider.dart';
import 'package:lf_kitchen/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize SharedPreferences with empty values for testing
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app with overridden providers
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const LFKitchenApp(),
      ),
    );

    // Allow one frame to render
    await tester.pump();

    // Verify that app loads without crashing
    // (Dashboard text may not appear if Supabase isn't connected in tests)
    expect(tester.takeException(), isNull);
  });
}
