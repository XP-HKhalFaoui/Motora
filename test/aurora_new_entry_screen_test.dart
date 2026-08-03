import 'package:carnet_auto/core/theme.dart';
import 'package:carnet_auto/models/garage.dart';
import 'package:carnet_auto/models/maintenance_history.dart';
import 'package:carnet_auto/providers/garage_provider.dart';
import 'package:carnet_auto/screens/new_entry/aurora_new_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      garagesProvider.overrideWith((ref) async => const <Garage>[]),
    ],
    child: MaterialApp(theme: AppTheme.light, home: screen),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  testWidgets('Entretien shows Intitulé and Garage, not Litres', (tester) async {
    await _pump(tester, const AuroraNewEntryScreen(vehicleId: 'v1'));

    expect(find.text('Intitulé'), findsOneWidget);
    expect(find.text('Garage'), findsOneWidget);
    expect(find.text('＋ Nouveau garage'), findsOneWidget);
    expect(find.text('Litres'), findsNothing);
    expect(find.text('Plein complet'), findsNothing);
    expect(find.text('Catégorie'), findsNothing);
  });

  testWidgets('Carburant drops Intitulé/Garage for Litres and a full-tank switch',
      (tester) async {
    await _pump(
      tester,
      const AuroraNewEntryScreen(vehicleId: 'v1', kind: HistoryEntryKind.fuel),
    );

    expect(find.text('Litres'), findsOneWidget);
    expect(find.text('Plein complet'), findsOneWidget);
    expect(find.text('Intitulé'), findsNothing);
    expect(find.text('Garage'), findsNothing);
    expect(find.text('＋ Nouveau garage'), findsNothing);
  });

  testWidgets('Dépense shows Intitulé and Catégorie, not Garage or Litres',
      (tester) async {
    await _pump(
      tester,
      const AuroraNewEntryScreen(vehicleId: 'v1', kind: HistoryEntryKind.expense),
    );

    expect(find.text('Intitulé'), findsOneWidget);
    expect(find.text('Catégorie'), findsOneWidget);
    expect(find.text('Garage'), findsNothing);
    expect(find.text('Litres'), findsNothing);
  });

  testWidgets('switching the segmented control swaps the field set', (tester) async {
    await _pump(tester, const AuroraNewEntryScreen(vehicleId: 'v1'));
    expect(find.text('Garage'), findsOneWidget);

    await tester.tap(find.text('Carburant'));
    await tester.pumpAndSettle();

    expect(find.text('Garage'), findsNothing);
    expect(find.text('Litres'), findsOneWidget);
  });

  testWidgets('the linked banner shows the maintenance type and hides on edit',
      (tester) async {
    await _pump(
      tester,
      const AuroraNewEntryScreen(vehicleId: 'v1', linkedLabel: 'Contrôle technique'),
    );

    expect(find.textContaining('Contrôle technique'), findsOneWidget);
    expect(find.textContaining("l'échéance sera remise à zéro"), findsOneWidget);
  });

  testWidgets('editing an existing entry locks the type and offers delete', (tester) async {
    final existing = MaintenanceHistory(
      id: 'h1',
      vehicleId: 'v1',
      title: 'Vidange',
      kind: HistoryEntryKind.maintenance,
      doneAt: DateTime(2026, 5, 1),
    );
    await _pump(tester, AuroraNewEntryScreen(vehicleId: 'v1', existing: existing));

    expect(find.text('Vidange'), findsOneWidget);
    expect(find.text('Supprimer cette entrée'), findsOneWidget);

    // Tapping another segment while editing must not change the kind —
    // Carburant's fields (Litres) must not appear.
    await tester.tap(find.text('Carburant'));
    await tester.pumpAndSettle();
    expect(find.text('Litres'), findsNothing);
    expect(find.text('Garage'), findsOneWidget);
  });
}
