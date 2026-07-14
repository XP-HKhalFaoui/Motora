import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography helpers matching the Motora design system:
/// Manrope for UI/body text (handled by the app's [TextTheme]), Space
/// Grotesk for screen titles, the wordmark, and every technical/numeric
/// value (odometer, costs, counters) — see PROMPT-claude-code.md §5.
class AppText {
  AppText._();

  /// Screen / section title, e.g. "Mes véhicules", "Entretien".
  static TextStyle screenTitle(Color color, {double size = 24}) =>
      GoogleFonts.spaceGrotesk(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -.4,
        height: 1.1,
      );

  /// The "Motora" wordmark.
  static TextStyle wordmark(Color color, {double size = 30}) =>
      GoogleFonts.spaceGrotesk(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -.5,
        height: 1,
      );

  /// Large odometer-style number (km, totals).
  static TextStyle odometer(Color color, {double size = 22}) =>
      GoogleFonts.spaceGrotesk(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -.3,
        height: 1,
      );

  /// Small technical value, e.g. "dans 320 km", a chip amount.
  static TextStyle technical(Color color, {double size = 13}) =>
      GoogleFonts.spaceGrotesk(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
      );

  /// Uppercase section label ("2 VÉHICULES", "PROCHAINES ÉCHÉANCES").
  static TextStyle sectionLabel(Color color, {double size = 12.5}) => TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: .5,
      );
}
