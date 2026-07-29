import 'package:carnet_auto/core/formatters.dart';
import 'package:carnet_auto/core/theme.dart';
import 'package:carnet_auto/models/maintenance_history.dart';
import 'package:carnet_auto/models/mileage_log.dart';
import 'package:carnet_auto/models/vehicle.dart';
import 'package:carnet_auto/providers/maintenance_provider.dart';
import 'package:carnet_auto/providers/vehicle_provider.dart';
import 'package:carnet_auto/screens/reports/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

MaintenanceHistory _e(String id, HistoryEntryKind kind, DateTime at,
        {double? cost, int? km}) =>
    MaintenanceHistory(
      id: id,
      vehicleId: 'v1',
      title: id,
      kind: kind,
      cost: cost,
      km: km,
      doneAt: at,
    );

Future<void> _pump(WidgetTester tester,
    {required List<MaintenanceHistory> history}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      maintenanceHistoryProvider('v1').overrideWith((ref) async => history),
      mileageLogsProvider('v1').overrideWith((ref) async => [
            MileageLog(
                id: '1',
                vehicleId: 'v1',
                km: 100000,
                recordedAt: DateTime(2026, 1, 1)),
            MileageLog(
                id: '2',
                vehicleId: 'v1',
                km: 110000,
                recordedAt: DateTime(2026, 7, 1)),
          ]),
      vehiclesProvider.overrideWith(() => _StubVehicles()),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: const ReportsScreen(vehicleId: 'v1'),
    ),
  ));
  await tester.pumpAndSettle();
}

class _StubVehicles extends VehiclesNotifier {
  @override
  Future<List<Vehicle>> build() async => const [
        Vehicle(id: 'v1', userId: 'u1', name: 'Clio', currentKm: 110000),
      ];
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  testWidgets('shows the cost split the app collects', (tester) async {
    await _pump(tester, history: [
      _e('f', HistoryEntryKind.fuel, DateTime(2026, 7, 1), cost: 1000),
      _e('m', HistoryEntryKind.maintenance, DateTime(2026, 7, 2), cost: 8000),
      _e('x', HistoryEntryKind.expense, DateTime(2026, 7, 3), cost: 12000),
    ]);

    expect(find.text('Carburant'), findsWidgets);
    expect(find.text('Entretien'), findsWidgets);
    expect(find.text('Dépenses'), findsWidgets);
    // The total, and each category's own amount.
    expect(find.text(Fmt.money(21000)), findsOneWidget);
    expect(find.text(Fmt.money(12000)), findsOneWidget);
  });

  testWidgets('says there is nothing to analyse rather than showing zeros',
      (tester) async {
    await _pump(tester, history: const []);

    expect(find.textContaining('Rien à analyser'), findsOneWidget);
    // No fabricated 0 DA anywhere.
    expect(find.text(Fmt.money(0)), findsNothing);
  });
}
