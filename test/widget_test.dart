// Basic smoke test: the app boots without throwing.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carnet_auto/main.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MotoraApp()),
    );
    await tester.pump();

    // Without --dart-define Supabase credentials, the app shows the
    // "misconfigured" screen instead of crashing.
    expect(find.textContaining('Supabase'), findsWidgets);
  });
}
