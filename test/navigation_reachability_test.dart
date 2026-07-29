import 'package:carnet_auto/core/theme.dart';
import 'package:carnet_auto/models/admin_document.dart';
import 'package:carnet_auto/models/maintenance_history.dart';
import 'package:carnet_auto/models/maintenance_prediction.dart';
import 'package:carnet_auto/models/mileage_log.dart';
import 'package:carnet_auto/models/vehicle.dart';
import 'package:carnet_auto/providers/document_provider.dart';
import 'package:carnet_auto/providers/maintenance_provider.dart';
import 'package:carnet_auto/providers/shell_provider.dart';
import 'package:carnet_auto/providers/ui_state_provider.dart';
import 'package:carnet_auto/providers/vehicle_provider.dart';
import 'package:carnet_auto/screens/shell/tabs/more_tab.dart';
import 'package:carnet_auto/screens/shell/vehicle_selector.dart';
import 'package:carnet_auto/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Replacing the hub with tabs moved seven destinations that each had a
/// single entry point. An orphaned screen breaks no existing test — it
/// just quietly stops being reachable — so these assert the entry points
/// exist.

class _StubVehicles extends VehiclesNotifier {
  @override
  Future<List<Vehicle>> build() async => const [
        Vehicle(id: 'v1', userId: 'u1', name: 'Clio', currentKm: 100000),
        Vehicle(id: 'v2', userId: 'u1', name: 'Kangoo', currentKm: 200000),
      ];
}

Widget _host(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: [
        vehiclesProvider.overrideWith(_StubVehicles.new),
        maintenanceHistoryProvider('v1')
            .overrideWith((ref) async => const <MaintenanceHistory>[]),
        mileageLogsProvider('v1')
            .overrideWith((ref) async => const <MileageLog>[]),
        documentsProvider('v1')
            .overrideWith((ref) async => const <AdminDocument>[]),
        predictionsProvider('v1')
            .overrideWith((ref) async => const <MaintenancePrediction>[]),
        ...overrides,
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
        home: Scaffold(body: child),
      ),
    );

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  testWidgets('Plus reaches every destination the hub used to hold',
      (tester) async {
    await tester.pumpWidget(_host(const MoreTab(vehicleId: 'v1')));
    await tester.pumpAndSettle();

    for (final label in [
      'Rapports', // was overview_section's only link
      'Carburant', // was hub segment 4
      'Kilométrage', // was hub segment 3
      'Documents', // was hub segment 2
      'Mes garages', // was reachable only from Paramètres
      'Paramètres', // was reachable only from the home avatar
    ]) {
      expect(find.text(label), findsOneWidget, reason: '$label is orphaned');
    }
  });

  testWidgets('Plus hides vehicle-scoped rows when there is no vehicle',
      (tester) async {
    await tester.pumpWidget(_host(const MoreTab(vehicleId: null)));
    await tester.pumpAndSettle();

    expect(find.text('Rapports'), findsNothing);
    // The global ones stay: settings is the only way to sign out or
    // delete the account.
    expect(find.text('Paramètres'), findsOneWidget);
  });

  testWidgets('the bottom bar exposes all four destinations', (tester) async {
    await tester.pumpWidget(_host(BottomNavBar(
      current: ShellTab.vehicle,
      onSelect: (_) {},
    )));
    await tester.pumpAndSettle();

    for (final label in ['Véhicule', 'Historique', 'Échéances', 'Plus']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('the selector switches vehicle and records the choice',
      (tester) async {
    // The hub's initState was the only writer of selectedVehicleIdProvider.
    // If the selector doesn't take that over, everything downstream
    // silently falls back to the first vehicle forever.
    late WidgetRef ref;
    await tester.pumpWidget(_host(Consumer(builder: (context, r, _) {
      ref = r;
      return const VehicleSelector();
    })));
    await tester.pumpAndSettle();

    expect(ref.read(selectedVehicleIdProvider), isNull);
    expect(find.text('Clio'), findsOneWidget);

    await tester.tap(find.text('Clio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kangoo').last);
    await tester.pumpAndSettle();

    expect(ref.read(selectedVehicleIdProvider), 'v2');
  });

  testWidgets('the selector offers a way to add a vehicle', (tester) async {
    // Losing the home screen removed the "Ajouter un véhicule" link.
    await tester.pumpWidget(_host(const VehicleSelector()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clio'));
    await tester.pumpAndSettle();

    expect(find.text('Ajouter un véhicule'), findsOneWidget);
  });
}
