import 'package:carnet_auto/core/formatters.dart';
import 'package:carnet_auto/core/theme.dart';
import 'package:carnet_auto/models/maintenance_history.dart';
import 'package:carnet_auto/providers/maintenance_provider.dart';
import 'package:carnet_auto/screens/ledger/aurora_ledger_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _history = [
  MaintenanceHistory(
    id: 'h1',
    vehicleId: 'v1',
    title: 'Vidange moteur',
    kind: HistoryEntryKind.maintenance,
    doneAt: DateTime(2026, 7, 10),
    cost: 3500,
    km: 128300,
  ),
  MaintenanceHistory(
    id: 'h2',
    vehicleId: 'v1',
    title: 'Péage',
    kind: HistoryEntryKind.expense,
    category: 'peage',
    doneAt: DateTime(2026, 6, 2),
    cost: 200,
  ),
];

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      maintenanceHistoryProvider('v1').overrideWith((ref) async => _history),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: AuroraLedgerScreen(vehicleId: 'v1')),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  testWidgets('shows the period total and both entries grouped by month', (tester) async {
    await _pump(tester);

    expect(find.text('Journal'), findsOneWidget);
    expect(find.text(Fmt.money(3700)), findsOneWidget); // 3500 + 200
    expect(find.text('2 entrées'), findsOneWidget);
    expect(find.text('Vidange moteur'), findsOneWidget);
    expect(find.text('Péage'), findsOneWidget);
    // Mixed-case month label, not the shared Fmt.monthHeader's ALL CAPS.
    expect(find.text('Juillet 2026'), findsOneWidget);
    expect(find.text('Juin 2026'), findsOneWidget);
  });

  testWidgets('the Entretien filter chip hides the expense row', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Entretien'));
    await tester.pumpAndSettle();

    expect(find.text('Vidange moteur'), findsOneWidget);
    expect(find.text('Péage'), findsNothing);
  });

  testWidgets('search narrows to matching entries', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField).first, 'péage');
    await tester.pumpAndSettle();

    expect(find.text('Péage'), findsOneWidget);
    expect(find.text('Vidange moteur'), findsNothing);
  });

  testWidgets('the funnel chip resets active filters', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Carburant'));
    await tester.pumpAndSettle();
    expect(find.text('Vidange moteur'), findsNothing);
    expect(find.text('Péage'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Réinitialiser les filtres'));
    await tester.pumpAndSettle();

    expect(find.text('Vidange moteur'), findsOneWidget);
    expect(find.text('Péage'), findsOneWidget);
  });
}
