import 'package:carnet_auto/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp declares French localization delegates',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MotoraApp()));
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('fr'));
    expect(app.supportedLocales, contains(const Locale('fr')));
    expect(
      app.localizationsDelegates,
      contains(GlobalMaterialLocalizations.delegate),
    );
  });

  testWidgets('the date picker renders in French, not English',
      (tester) async {
    // The regression this guards: showDatePicker is used for interventions
    // and documents, and without the delegates its buttons read
    // "Cancel"/"OK" in an otherwise French app.
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDatePicker(
            context: context,
            initialDate: DateTime(2026, 7, 28),
            firstDate: DateTime(2000),
            lastDate: DateTime(2030),
          ),
          child: const Text('ouvrir'),
        ),
      ),
    ));

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Annuler'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });
}
