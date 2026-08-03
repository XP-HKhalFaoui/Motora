import 'dart:async';

import 'package:carnet_auto/core/theme.dart';
import 'package:carnet_auto/models/admin_document.dart';
import 'package:carnet_auto/models/maintenance_history.dart';
import 'package:carnet_auto/models/maintenance_prediction.dart';
import 'package:carnet_auto/models/mileage_log.dart';
import 'package:carnet_auto/models/reminder.dart';
import 'package:carnet_auto/models/vehicle.dart';
import 'package:carnet_auto/providers/aurora_shell_provider.dart';
import 'package:carnet_auto/providers/auth_provider.dart';
import 'package:carnet_auto/providers/document_provider.dart';
import 'package:carnet_auto/providers/maintenance_provider.dart';
import 'package:carnet_auto/providers/notification_provider.dart';
import 'package:carnet_auto/providers/vehicle_provider.dart';
import 'package:carnet_auto/screens/shell/app_shell.dart';
import 'package:carnet_auto/widgets/aurora/aurora_floating_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _StubVehicles extends VehiclesNotifier {
  @override
  Future<List<Vehicle>> build() async => const [
        Vehicle(id: 'v1', userId: 'u1', name: 'Clio', currentKm: 100000),
      ];
}

Future<void> _pumpShell(WidgetTester tester) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      // AuroraHomeScreen's greeting reads this; Supabase is never
      // initialized in a widget test, so the real provider would throw.
      currentUserProvider.overrideWithValue(null),
      vehiclesProvider.overrideWith(_StubVehicles.new),
      maintenanceHistoryProvider('v1')
          .overrideWith((ref) async => const <MaintenanceHistory>[]),
      mileageLogsProvider('v1')
          .overrideWith((ref) async => const <MileageLog>[]),
      documentsProvider('v1')
          .overrideWith((ref) async => const <AdminDocument>[]),
      predictionsProvider('v1')
          .overrideWith((ref) async => const <MaintenancePrediction>[]),
      // Left pending on purpose: a resolved value would run the scheduler,
      // which reaches the notification platform channel.
      remindersProvider
          .overrideWith((ref) => Completer<List<Reminder>>().future),
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
      home: const AppShell(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  testWidgets('opens on Accueil with the vehicle name shown', (tester) async {
    await _pumpShell(tester);

    // The vehicle name appears twice: the greeting block and the photo
    // hero's plate/km pill row's neighbourhood.
    expect(find.text('Clio'), findsWidgets);
    expect(find.textContaining('Bonjour'), findsOneWidget);
  });

  testWidgets('each tab shows its own content', (tester) async {
    await _pumpShell(tester);

    await tester.tap(find.bySemanticsLabel('Journal'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rechercher'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Échéances'));
    await tester.pumpAndSettle();
    expect(find.text('Échéances'), findsOneWidget);
    expect(find.text('Rien à signaler'), findsOneWidget,
        reason: 'no predictions/documents were stubbed for this vehicle');

    await tester.tap(find.bySemanticsLabel('Rapports'));
    await tester.pumpAndSettle();
    expect(find.text('Rapports'), findsOneWidget);
  });

  testWidgets('the quick-add sheet exposes all five entry kinds', (tester) async {
    await _pumpShell(tester);

    await tester.tap(find.bySemanticsLabel('Ajouter une entrée'));
    await tester.pumpAndSettle();

    for (final label in [
      'Relevé kilométrique',
      'Réparation',
      'Plein de carburant',
      'Dépense',
      'Document scanné',
    ]) {
      expect(find.text(label), findsOneWidget, reason: '$label is orphaned');
    }
  });

  testWidgets('a tapped reminder lands on Échéances', (tester) async {
    // It used to push the hub with initialSection: 1. With tabs it has to
    // be a selection, or the notification silently goes nowhere.
    await _pumpShell(tester);

    final element = tester.element(find.byType(AppShell));
    final container = ProviderScope.containerOf(element);
    expect(container.read(auroraShellTabProvider), AuroraNavTab.home);

    await tester.tap(find.bySemanticsLabel('Échéances'));
    await tester.pumpAndSettle();
    expect(container.read(auroraShellTabProvider), AuroraNavTab.due);
  });
}
