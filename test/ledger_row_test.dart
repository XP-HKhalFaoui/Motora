import 'package:carnet_auto/core/entry_style.dart';
import 'package:carnet_auto/core/formatters.dart';
import 'package:carnet_auto/core/theme.dart';
import 'package:carnet_auto/models/maintenance_history.dart';
import 'package:carnet_auto/widgets/ledger_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

MaintenanceHistory _entry(HistoryEntryKind kind) => MaintenanceHistory(
      id: 'e',
      vehicleId: 'v1',
      title: 'x',
      kind: kind,
      doneAt: DateTime(2026, 5, 22),
    );

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  testWidgets('shows title, date, odometer and amount', (tester) async {
    await tester.pumpWidget(_host(LedgerRow(
      icon: Icons.local_gas_station,
      color: const Color(0xFFF0A44A),
      title: 'Plein',
      subtitle: 'Station service',
      meta: Fmt.km(19829),
      date: Fmt.dayMonth(DateTime(2026, 5, 22)),
      trailing: Fmt.money(1000),
    )));

    expect(find.text('Plein'), findsOneWidget);
    expect(find.text('Station service'), findsOneWidget);
    expect(find.text(Fmt.km(19829)), findsOneWidget);
    expect(find.text('22 mai'), findsOneWidget);
    expect(find.text(Fmt.money(1000)), findsOneWidget);
  });

  testWidgets('a leading widget replaces the icon badge', (tester) async {
    // The odometer photo is the evidence behind a "certifié" reading; a
    // dense row must not quietly drop it for a generic glyph.
    await tester.pumpWidget(_host(const LedgerRow(
      icon: Icons.speed,
      color: Color(0xFFF084B8),
      title: '569 265 km',
      leading: ColoredBox(color: Color(0xFF00FF00), child: SizedBox.expand()),
    )));

    expect(find.byIcon(Icons.speed), findsNothing);
    expect(find.byType(ColoredBox), findsWidgets);
  });

  testWidgets('the month header is upper-case and spelled out', (tester) async {
    await tester.pumpWidget(
        _host(LedgerMonthHeader(label: Fmt.monthHeader(DateTime(2026, 5)))));

    expect(find.text('MAI 2026'), findsOneWidget);
  });

  group('entryStyleFor', () {
    test('gives each kind its own hue', () {
      const p = AppPalette.dark;
      final fuel = entryStyleFor(p, _entry(HistoryEntryKind.fuel));
      final expense = entryStyleFor(p, _entry(HistoryEntryKind.expense));
      final maintenance =
          entryStyleFor(p, _entry(HistoryEntryKind.maintenance));

      expect(fuel.color, p.entryFuel);
      expect(expense.color, p.entryExpense);
      expect(maintenance.color, p.entryMaintenance);
      expect({fuel.icon, expense.icon, maintenance.icon}, hasLength(3));
    });
  });
}
