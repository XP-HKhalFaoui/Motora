import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

enum DistanceUnit { km, miles }

/// Device-local app preferences (no Supabase table for these — see
/// PROMPT-claude-code.md §9 "Paramètres"). Persisted via SharedPreferences.
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.distanceUnit,
    required this.kmAlertThreshold,
    required this.daysAlertThreshold,
    required this.pushEnabled,
  });

  final ThemeMode themeMode;
  final DistanceUnit distanceUnit;
  final int kmAlertThreshold;
  final int daysAlertThreshold;
  final bool pushEnabled;

  factory AppSettings.defaults() => const AppSettings(
        themeMode: ThemeMode.dark,
        distanceUnit: DistanceUnit.km,
        kmAlertThreshold: Thresholds.kmAlert,
        daysAlertThreshold: Thresholds.daysAlert,
        pushEnabled: true,
      );

  AppSettings copyWith({
    ThemeMode? themeMode,
    DistanceUnit? distanceUnit,
    int? kmAlertThreshold,
    int? daysAlertThreshold,
    bool? pushEnabled,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        distanceUnit: distanceUnit ?? this.distanceUnit,
        kmAlertThreshold: kmAlertThreshold ?? this.kmAlertThreshold,
        daysAlertThreshold: daysAlertThreshold ?? this.daysAlertThreshold,
        pushEnabled: pushEnabled ?? this.pushEnabled,
      );
}

const _kThemeMode = 'settings.themeMode';
const _kDistanceUnit = 'settings.distanceUnit';
const _kKmThreshold = 'settings.kmAlertThreshold';
const _kDaysThreshold = 'settings.daysAlertThreshold';
const _kPushEnabled = 'settings.pushEnabled';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

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
      distanceUnit: DistanceUnit.values.firstWhere(
        (u) => u.name == _prefs.getString(_kDistanceUnit),
        orElse: () => defaults.distanceUnit,
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

  Future<void> toggleDarkMode(bool dark) =>
      setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);

  Future<void> setDistanceUnit(DistanceUnit unit) async {
    await _prefs.setString(_kDistanceUnit, unit.name);
    state = AsyncData((state.value ?? AppSettings.defaults())
        .copyWith(distanceUnit: unit));
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
