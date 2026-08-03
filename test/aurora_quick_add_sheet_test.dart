import 'package:carnet_auto/core/theme.dart';
import 'package:carnet_auto/widgets/aurora/aurora_quick_add_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAuroraQuickAddSheet(context, 'v1'),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the title, subtitle and all five gestures', (tester) async {
    await _open(tester);

    expect(find.text('Ajouter'), findsOneWidget);
    expect(find.text("Cinq gestes, depuis n'importe quel écran"), findsOneWidget);
    expect(find.text('Relevé kilométrique'), findsOneWidget);
    expect(find.text('Saisie ou photo du compteur'), findsOneWidget);
    expect(find.text('Réparation'), findsOneWidget);
    expect(find.text('Plein de carburant'), findsOneWidget);
    expect(find.text('Dépense'), findsOneWidget);
    expect(find.text('Document scanné'), findsOneWidget);
  });
}
