import 'package:carnet_auto/core/formatters.dart';
import 'package:carnet_auto/core/theme.dart';
import 'package:carnet_auto/models/maintenance_prediction.dart';
import 'package:carnet_auto/models/maintenance_type.dart';
import 'package:carnet_auto/widgets/maintenance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

MaintenanceType _type({int? lastDoneKm}) => MaintenanceType(
      id: 't1',
      vehicleId: 'v1',
      label: 'Kit distribution',
      intervalKm: 60000,
      lastDoneKm: lastDoneKm,
    );

void main() {
  testWidgets('a type with no anchor asks for one instead of showing a bar',
      (tester) async {
    await tester.pumpWidget(_host(MaintenanceCard(
      prediction: MaintenancePrediction(
        type: _type(),
        remainingKm: null,
        dueDate: null,
        kmPerMonth: 1000,
        urgency: 0,
        needsSetup: true,
      ),
    )));

    expect(find.text('à configurer'), findsOneWidget);
    expect(find.textContaining('Renseignez'), findsOneWidget);
    // The reassuring 0% progress bar must not be there.
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('an anchored type shows its progress and remaining km',
      (tester) async {
    await tester.pumpWidget(_host(MaintenanceCard(
      prediction: MaintenancePrediction(
        type: _type(lastDoneKm: 120000),
        remainingKm: 5000,
        dueDate: null,
        kmPerMonth: 1000,
        urgency: 0.9,
      ),
    )));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining(Fmt.km(5000)), findsWidgets);
    expect(find.text('à configurer'), findsNothing);
  });

  testWidgets('an overdue type says so', (tester) async {
    await tester.pumpWidget(_host(MaintenanceCard(
      prediction: MaintenancePrediction(
        type: _type(lastDoneKm: 120000),
        remainingKm: -20000,
        dueDate: null,
        kmPerMonth: 1000,
        // Unclamped, as PredictionService now emits it.
        urgency: 1.33,
      ),
    )));

    expect(find.textContaining('dépassé'), findsWidgets);
    // The bar still renders, clamped.
    final bar = tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(bar.value, 1.0);
  });

  testWidgets('the mark-as-done action does not hide the badge',
      (tester) async {
    await tester.pumpWidget(_host(MaintenanceCard(
      prediction: MaintenancePrediction(
        type: _type(lastDoneKm: 120000),
        remainingKm: 5000,
        dueDate: null,
        kmPerMonth: 1000,
        urgency: 0.9,
      ),
      onMarkDone: () {},
    )));

    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.textContaining(Fmt.km(5000)), findsWidgets);
  });
}
