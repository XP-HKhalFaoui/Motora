import 'package:carnet_auto/core/formatters.dart';
import 'package:carnet_auto/core/theme.dart';
import 'package:carnet_auto/models/maintenance_history.dart';
import 'package:carnet_auto/models/mileage_log.dart';
import 'package:carnet_auto/models/vehicle.dart';
import 'package:carnet_auto/providers/maintenance_provider.dart';
import 'package:carnet_auto/providers/vehicle_provider.dart';
import 'package:carnet_auto/screens/reports/aurora_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _now = DateTime.now();

Future<void> _pump(WidgetTester tester, {required List<MaintenanceHistory> history, required List<MileageLog> logs}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      vehiclesProvider.overrideWith(() => _FakeVehiclesNotifier()),
      maintenanceHistoryProvider('v1').overrideWith((ref) async => history),
      mileageLogsProvider('v1').overrideWith((ref) async => logs),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: AuroraReportsScreen(vehicleId: 'v1')),
    ),
  ));
  await tester.pumpAndSettle();
}

class _FakeVehiclesNotifier extends VehiclesNotifier {
  @override
  Future<List<Vehicle>> build() async => const [
        Vehicle(id: 'v1', userId: 'u1', name: 'Clio', currentKm: 128450),
      ];
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  testWidgets('shows an empty state rather than zeros with no data', (tester) async {
    await _pump(tester, history: const [], logs: const []);

    expect(find.text('Rapports'), findsOneWidget);
    expect(find.text('Rien à analyser'), findsOneWidget);
  });

  testWidgets('shows the breakdown split by category once there is data', (tester) async {
    final history = [
      MaintenanceHistory(
          id: 'h1',
          vehicleId: 'v1',
          title: 'Plein',
          kind: HistoryEntryKind.fuel,
          doneAt: _now.subtract(const Duration(days: 5)),
          cost: 2000,
          km: 128000),
      MaintenanceHistory(
          id: 'h2',
          vehicleId: 'v1',
          title: 'Vidange',
          kind: HistoryEntryKind.maintenance,
          doneAt: _now.subtract(const Duration(days: 10)),
          cost: 3500),
    ];
    await _pump(tester, history: history, logs: const []);

    expect(find.text('Carburant'), findsOneWidget);
    expect(find.text('Entretien'), findsOneWidget);
    expect(find.text(Fmt.money(2000)), findsOneWidget);
    expect(find.text(Fmt.money(3500)), findsOneWidget);
  });

  testWidgets('shows the current odometer reading', (tester) async {
    await _pump(tester, history: const [], logs: const []);
    expect(find.textContaining('128'), findsWidgets);
  });
}
