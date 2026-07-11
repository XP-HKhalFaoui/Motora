import 'package:flutter/material.dart';

/// Sober, technical-but-warm palette: dark blue/grey with orange accents
/// for alerts (per the design brief in the conception doc).
class AppColors {
  static const Color primary = Color(0xFF2B4C7E); // deep blue
  static const Color primaryDark = Color(0xFF1B2A41);
  static const Color accent = Color(0xFFF29E4E); // warm orange
  static const Color background = Color(0xFF0F1621);
  static const Color surface = Color(0xFF1A2433);
  static const Color surfaceAlt = Color(0xFF222E40);

  // Status colors for maintenance / documents.
  static const Color ok = Color(0xFF3FB984); // green
  static const Color warn = Color(0xFFF2B84E); // orange
  static const Color danger = Color(0xFFE5604D); // red

  static const Color textPrimary = Color(0xFFEAF0F6);
  static const Color textMuted = Color(0xFF8DA0B6);
}

/// Maps a normalized "urgency" (0 = fine, 1 = overdue) to a status color.
Color statusColor(double urgency) {
  if (urgency >= 0.85) return AppColors.danger;
  if (urgency >= 0.6) return AppColors.warn;
  return AppColors.ok;
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primaryDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }
}
