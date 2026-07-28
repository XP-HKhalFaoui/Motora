import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

/// Device-local app preferences (no Supabase table for these — see
/// PROMPT-claude-code.md §9 "Paramètres"). Persisted via SharedPreferences.
///
/// There is deliberately no distance-unit setting: Motora is metric
/// throughout (km intervals, € costs, vignette / carte grise / contrôle
/// technique), and the km/miles toggle that used to live here changed
/// nothing anywhere in the app.
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.kmAlertThreshold,
    required this.daysAlertThreshold,
    required this.pushEnabled,
  });

  final ThemeMode themeMode;
  final int kmAlertThreshold;
  final int daysAlertThreshold;
  final bool pushEnabled;

  factory AppSettings.defaults() => const AppSettings(
        themeMode: ThemeMode.dark,
        kmAlertThreshold: Thresholds.kmAlert,
        daysAlertThreshold: Thresholds.daysAlert,
        pushEnabled: true,
      );

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? kmAlertThreshold,
    int? daysAlertThreshold,
    bool? pushEnabled,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        kmAlertThreshold: kmAlertThreshold ?? this.kmAlertThreshold,
        daysAlertThreshold: daysAlertThreshold ?? this.daysAlertThreshold,
        pushEnabled: pushEnabled ?? this.pushEnabled,
      );
}

const _kThemeMode = 'settings.themeMode';
const _kKmThreshold = 'settings.kmAlertThreshold';
const _kDaysThreshold = 'settings.daysAlertThreshold';
const _kPushEnabled = 'settings.pushEnabled';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// "1.0.0 (1)" — shown in Réglages > À propos.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  late SharedPreferences _prefs;

  @override
  Future<AppSettings> build() async {
    _prefs = await SharedPreferences.getInstance();
    final defaults = AppSettings.defaults();
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == _prefs.getString(_kThemeMode),
        orElse: () => defaults.themeMode,
      ),
      kmAlertThreshold:
          _prefs.getInt(_kKmThreshold) ?? defaults.kmAlertThreshold,
      daysAlertThreshold:
          _prefs.getInt(_kDaysThreshold) ?? defaults.daysAlertThreshold,
      pushEnabled: _prefs.getBool(_kPushEnabled) ?? defaults.pushEnabled,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_kThemeMode, mode.name);
    state = AsyncData((state.value ?? AppSettings.defaults())
        .copyWith(themeMode: mode));
  }

  Future<void> setKmThreshold(int km) async {
    await _prefs.setInt(_kKmThreshold, km);
    state = AsyncData((state.value ?? AppSettings.defaults())
        .copyWith(kmAlertThreshold: km));
  }

  Future<void> setDaysThreshold(int days) async {
    await _prefs.setInt(_kDaysThreshold, days);
    state = AsyncData((state.value ?? AppSettings.defaults())
        .copyWith(daysAlertThreshold: days));
  }

  Future<void> setPushEnabled(bool enabled) async {
    await _prefs.setBool(_kPushEnabled, enabled);
    state = AsyncData((state.value ?? AppSettings.defaults())
        .copyWith(pushEnabled: enabled));
  }
}
