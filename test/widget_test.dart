// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lf_kitchen/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: LFKitchenApp()));

    // Verify that app loads with Dashboard title or warning banner
    expect(find.textContaining('Dashboard'), findsAny);
  });
}
