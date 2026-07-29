import 'package:carnet_auto/core/theme.dart';
import 'package:carnet_auto/models/garage.dart';
import 'package:carnet_auto/models/maintenance_history.dart';
import 'package:carnet_auto/models/maintenance_type.dart';
import 'package:carnet_auto/providers/garage_provider.dart';
import 'package:carnet_auto/providers/maintenance_provider.dart';
import 'package:carnet_auto/screens/quick_add/add_history_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the sheet for [kind] and settles it.
Future<void> _open(WidgetTester tester, HistoryEntryKind kind) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      maintenanceTypesProvider('v1').overrideWith((ref) async => const [
            MaintenanceType(
                id: 't1',
                vehicleId: 'v1',
                label: 'Vidange moteur',
                intervalKm: 7000),
          ]),
      garagesProvider.overrideWith((ref) async => const <Garage>[]),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAddHistorySheet(context, 'v1', kind: kind),
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
  testWidgets('an expense asks for a category, not a maintenance type',
      (tester) async {
    await _open(tester, HistoryEntryKind.expense);

    expect(find.text('Nouvelle dépense'), findsOneWidget);
    expect(find.text('Catégorie'), findsOneWidget);
    // The things that make no sense for an expense must not be there.
    expect(find.textContaining("Lié à un type d'entretien"), findsNothing);
    expect(find.text('Litres'), findsNothing);
    expect(find.text('Garage (optionnel)'), findsNothing);
  });

  testWidgets('a fill-up asks for litres, not a category', (tester) async {
    await _open(tester, HistoryEntryKind.fuel);

    expect(find.text('Nouveau plein'), findsOneWidget);
    expect(find.text('Litres'), findsOneWidget);
    expect(find.text('Catégorie'), findsNothing);
  });

  testWidgets('an intervention keeps its type and garage', (tester) async {
    await _open(tester, HistoryEntryKind.maintenance);

    expect(find.text('Nouvelle intervention'), findsOneWidget);
    expect(find.text('Catégorie'), findsNothing);
    expect(find.text('Litres'), findsNothing);
    expect(find.text('Garage (optionnel)'), findsOneWidget);
  });
}
