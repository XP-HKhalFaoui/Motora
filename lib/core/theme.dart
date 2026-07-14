import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for one theme (dark or light), per the Motora design
/// system (motora-app-ui-ux-design/project/PROMPT-claude-code.md §5).
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.navBar,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.primary,
    required this.accent,
    required this.ok,
    required this.warn,
    required this.danger,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color navBar;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color primary;
  final Color accent;
  final Color ok;
  final Color warn;
  final Color danger;

  static const dark = AppPalette(
    background: Color(0xFF0E1520),
    surface: Color(0xFF17202E),
    surfaceElevated: Color(0xFF1E2A3A),
    navBar: Color(0xFF0C121B),
    textPrimary: Color(0xFFEAF0F7),
    textSecondary: Color(0xFF8695A8),
    textMuted: Color(0xFF5D6B7E),
    border: Color(0x12FFFFFF), // rgba(255,255,255,.07)
    primary: Color(0xFF4C8DFF),
    accent: Color(0xFFFF8A3D),
    ok: Color(0xFF35C88A),
    warn: Color(0xFFF5B23D),
    danger: Color(0xFFFF5D5D),
  );

  static const light = AppPalette(
    background: Color(0xFFEEF1F6),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFE6EAF1),
    navBar: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF16202E),
    textSecondary: Color(0xFF5E6B7D),
    textMuted: Color(0xFF93A0B0),
    border: Color(0x14121C2A), // rgba(18,28,42,.08)
    primary: Color(0xFF2F72E8),
    accent: Color(0xFFF2732A),
    ok: Color(0xFF1FA971),
    warn: Color(0xFFC8871B),
    danger: Color(0xFFE23B3B),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? navBar,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? primary,
    Color? accent,
    Color? ok,
    Color? warn,
    Color? danger,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      navBar: navBar ?? this.navBar,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      ok: ok ?? this.ok,
      warn: warn ?? this.warn,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

/// Convenience accessor: `context.palette.primary`.
extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

/// Soft drop shadow used on cards in light theme, per §5 "ombre douce
/// 0 8px 24px -16px rgba(60,72,92,.5)" — dark theme relies on surface/
/// background contrast alone and uses no shadow.
List<BoxShadow>? cardShadow(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? null
        : const [
            BoxShadow(
              color: Color(0x803C485C),
              offset: Offset(0, 8),
              blurRadius: 24,
              spreadRadius: -16,
            ),
          ];

/// Maps a normalized "urgency" (0 = fine, 1 = overdue) to a status color.
Color statusColorFor(AppPalette p, double urgency) {
  if (urgency >= 0.85) return p.danger;
  if (urgency >= 0.6) return p.warn;
  return p.ok;
}

class AppTheme {
  static ThemeData _build(AppPalette p, Brightness brightness) {
    final manrope = GoogleFonts.manropeTextTheme();
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: p.background,
      extensions: [p],
      colorScheme: (brightness == Brightness.dark
              ? const ColorScheme.dark()
              : const ColorScheme.light())
          .copyWith(
        primary: p.primary,
        secondary: p.accent,
        surface: p.surface,
        error: p.danger,
        onSurface: p.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        elevation: 0,
        centerTitle: false,
        foregroundColor: p.textPrimary,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: p.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -.3,
        ),
        iconTheme: IconThemeData(color: p.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.border),
        ),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.accent,
        foregroundColor: brightness == Brightness.dark
            ? const Color(0xFF1A0F08)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: TextStyle(color: p.textMuted),
        labelStyle: TextStyle(color: p.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: p.primary.withValues(alpha: .4),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle: GoogleFonts.manrope(
              fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.border),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.primary),
      ),
      dividerTheme: DividerThemeData(color: p.border, space: 1),
      textTheme: manrope.apply(
        bodyColor: p.textPrimary,
        displayColor: p.textPrimary,
      ),
    );
  }

  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);
  static ThemeData get light => _build(AppPalette.light, Brightness.light);
}
