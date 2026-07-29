import 'package:carnet_auto/core/theme.dart';
import 'package:carnet_auto/models/maintenance_prediction.dart';
import 'package:carnet_auto/models/maintenance_type.dart';
import 'package:carnet_auto/widgets/km_gauge.dart';
import 'package:carnet_auto/widgets/maintenance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('the km gauge announces its reading', (tester) async {
    // It is a CustomPaint: without an explicit label a screen reader
    // finds nothing at all where the odometer is.
    await tester.pumpWidget(_host(
      const KmGauge(currentKm: 148320, subtitle: '+1 200 km / mois'),
    ));

    expect(
      find.bySemanticsLabel(RegExp(r'Kilométrage.*148.*320')),
      findsOneWidget,
    );
  });

  testWidgets('every tappable control meets the 48dp minimum', (tester) async {
    // Guards the whole maintenance card, mark-as-done button included.
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(MaintenanceCard(
      prediction: const MaintenancePrediction(
        type: MaintenanceType(
          id: 't1',
          vehicleId: 'v1',
          label: 'Vidange moteur',
          intervalKm: 7000,
          lastDoneKm: 140000,
        ),
        remainingKm: 2000,
        dueDate: null,
        kmPerMonth: 1000,
        urgency: 0.7,
      ),
      onMarkDone: () {},
    )));

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('interactive elements are labelled and contrast enough',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(MaintenanceCard(
      prediction: const MaintenancePrediction(
        type: MaintenanceType(
          id: 't1',
          vehicleId: 'v1',
          label: 'Kit distribution',
          intervalKm: 60000,
        ),
        remainingKm: null,
        dueDate: null,
        kmPerMonth: 1000,
        urgency: 0,
        needsSetup: true,
      ),
      onMarkDone: () {},
    )));

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
