import 'dart:math' as math;

import 'package:carnet_auto/core/aurora_theme.dart';
import 'package:carnet_auto/widgets/aurora/aurora_app_bar_chip.dart';
import 'package:carnet_auto/widgets/aurora/aurora_filter_chip.dart';
import 'package:carnet_auto/widgets/aurora/aurora_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

const _aaText = 4.5;

Widget _host(Widget child) => MaterialApp(
      theme: ThemeData(extensions: const [AuroraPalette.light]),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('contrast — spec claims muted meets AA on white', () {
    test('muted (#6A6B74) on card meets 4.5:1', () {
      final ratio = _contrast(AuroraColors.muted, AuroraColors.card);
      expect(ratio, greaterThanOrEqualTo(_aaText),
          reason: 'muted on card is ${ratio.toStringAsFixed(2)}:1');
    });

    test('ink (#161826) on card comfortably clears 4.5:1', () {
      final ratio = _contrast(AuroraColors.ink, AuroraColors.card);
      expect(ratio, greaterThanOrEqualTo(_aaText));
    });

    test('onDark on ink (dark-card text) meets 4.5:1', () {
      final ratio = _contrast(AuroraColors.onDark, AuroraColors.ink);
      expect(ratio, greaterThanOrEqualTo(_aaText));
    });
  });

  group('44px minimum tap targets', () {
    testWidgets('a filter chip meets the guideline despite its compact visual',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(
        AuroraFilterChip(label: 'Entretien', selected: false, onTap: () {}),
      ));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('a segmented-control segment meets the guideline', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(SizedBox(
        width: 300,
        child: AuroraSegmentedControl<String>(
          segments: const [
            AuroraSegment(value: 'a', label: 'Tout'),
            AuroraSegment(value: 'b', label: 'Entretien'),
          ],
          value: 'a',
          onChanged: (_) {},
        ),
      )));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('an app-bar chip meets the guideline', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(AuroraAppBarChip(
        icon: PhosphorIconsRegular.bell,
        semanticLabel: 'Alertes',
        onTap: () {},
      )));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });
  });

  group('text scaling to 1.3x', () {
    testWidgets('a filter chip row does not overflow', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [AuroraPalette.light]),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: Row(
              children: [
                AuroraFilterChip(label: 'Entretien', selected: true, onTap: () {}),
                AuroraFilterChip(label: 'Carburant', selected: false, onTap: () {}),
              ],
            ),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('a segmented control does not overflow', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [AuroraPalette.light]),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: SizedBox(
              width: 320,
              child: AuroraSegmentedControl<String>(
                segments: const [
                  AuroraSegment(value: 'a', label: 'Entretien', icon: PhosphorIconsRegular.wrench),
                  AuroraSegment(value: 'b', label: 'Carburant', icon: PhosphorIconsRegular.gasPump),
                  AuroraSegment(value: 'c', label: 'Dépense', icon: PhosphorIconsRegular.currencyEur),
                ],
                value: 'a',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
    });
  });
}
