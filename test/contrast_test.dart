import 'dart:math' as math;

import 'package:carnet_auto/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// AA for body text. Everything checked here is small text — the app's
/// muted labels run at 11px, nowhere near the 18pt that would allow 3:1.
const _aaText = 4.5;

/// AA for UI components and graphical objects (WCAG 1.4.11).
const _aaNonText = 3.0;

void main() {
  for (final entry in {
    'dark': AppPalette.dark,
    'light': AppPalette.light,
  }.entries) {
    final name = entry.key;
    final p = entry.value;

    // Every surface a label can sit on.
    final surfaces = {
      'background': p.background,
      'surface': p.surface,
      'surfaceElevated': p.surfaceElevated,
    };

    group('$name theme', () {
      for (final text in {
        'textPrimary': p.textPrimary,
        'textSecondary': p.textSecondary,
        'textMuted': p.textMuted,
      }.entries) {
        for (final surface in surfaces.entries) {
          test('${text.key} on ${surface.key} meets AA', () {
            final ratio = contrast(text.value, surface.value);
            expect(ratio, greaterThanOrEqualTo(_aaText),
                reason: '${text.key} on ${surface.key} is '
                    '${ratio.toStringAsFixed(2)}:1');
          });
        }
      }

      test('onPrimary on primary meets AA', () {
        // Buttons, the segmented control, year pills and filter chips all
        // put this pair together. White on the dark theme's light-blue
        // primary was 3.2:1, which is why onPrimary exists at all.
        final ratio = contrast(p.onPrimary, p.primary);
        expect(ratio, greaterThanOrEqualTo(_aaText),
            reason: 'onPrimary on primary is ${ratio.toStringAsFixed(2)}:1');
      });

      test('status colors stay distinguishable from their surface', () {
        // ok/warn/danger carry meaning through colour, so they fall under
        // the graphical-object threshold rather than the text one.
        for (final status in {
          'ok': p.ok,
          'warn': p.warn,
          'danger': p.danger,
        }.entries) {
          final ratio = contrast(status.value, p.surface);
          expect(ratio, greaterThanOrEqualTo(_aaNonText),
              reason: '${status.key} on surface is '
                  '${ratio.toStringAsFixed(2)}:1');
        }
      });

      test('entry badges are visible and carry a readable glyph', () {
        // The badges are what make a mixed timeline scannable, so they
        // fall under the graphical-object threshold — both against the
        // surface they sit on and against the glyph drawn inside them.
        // Dark-theme badges are bright tones, which is why onEntryBadge
        // is dark there rather than white.
        for (final badge in {
          'entryFuel': p.entryFuel,
          'entryExpense': p.entryExpense,
          'entryMaintenance': p.entryMaintenance,
          'entryDocument': p.entryDocument,
          'entryMileage': p.entryMileage,
          'entryDue': p.entryDue,
        }.entries) {
          for (final surface in surfaces.entries) {
            final vsSurface = contrast(badge.value, surface.value);
            expect(vsSurface, greaterThanOrEqualTo(_aaNonText),
                reason: '${badge.key} on ${surface.key} is '
                    '${vsSurface.toStringAsFixed(2)}:1');
          }
          final vsGlyph = contrast(p.onEntryBadge, badge.value);
          expect(vsGlyph, greaterThanOrEqualTo(_aaNonText),
              reason: 'glyph on ${badge.key} is '
                  '${vsGlyph.toStringAsFixed(2)}:1');
        }
      });

      test('every entry badge is a distinct hue', () {
        // Two types that look alike defeat the point of colouring them.
        final badges = [
          p.entryFuel,
          p.entryExpense,
          p.entryMaintenance,
          p.entryDocument,
          p.entryMileage,
          p.entryDue,
        ];
        for (var i = 0; i < badges.length; i++) {
          for (var j = i + 1; j < badges.length; j++) {
            expect(badges[i], isNot(badges[j]));
          }
        }
      });

      test('bottom nav entries are legible on the bar', () {
        // The bar is set apart by its top rule, not its fill — in the
        // light theme it is white like the cards. What has to hold is
        // that both states read against it.
        expect(contrast(p.primary, p.navBar), greaterThanOrEqualTo(_aaNonText),
            reason: 'selected entry on the nav bar');
        expect(contrast(p.textMuted, p.navBar), greaterThanOrEqualTo(_aaText),
            reason: 'unselected entry label on the nav bar');
      });

      test('the text scale keeps three distinguishable steps', () {
        // Raising textMuted to pass AA nearly collapsed it into
        // textSecondary; the whole scale moved instead so the hierarchy
        // survives.
        expect(contrast(p.textPrimary, p.textSecondary), greaterThan(1.3));
        expect(contrast(p.textSecondary, p.textMuted), greaterThan(1.3));
      });
    });
  }
}
