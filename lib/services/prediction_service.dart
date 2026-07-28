import 'dart:math' as math;

import '../core/constants.dart';
import '../models/maintenance_prediction.dart';
import '../models/maintenance_type.dart';
import '../models/mileage_log.dart';
import '../models/vehicle.dart';

/// Pure business logic — no I/O, easy to unit-test.
///
/// Implements sections 4.1 and 4.2 of the conception doc:
///   moyenne_km_mois = (km_actuel - km_il_y_a_N_mois) / N
///   km_restants     = (last_done_km + interval_km) - current_km
///   mois_restants   = km_restants / moyenne_km_mois
class PredictionService {
  /// Rolling monthly km average over the last [Thresholds.avgWindowMonths]
  /// months, or `null` when there isn't enough history to measure one.
  ///
  /// Callers that need a number regardless should use [monthlyKmAverage];
  /// callers that want to *tell the user* whether the figure is measured or
  /// guessed should use this and check for null.
  static double? measuredMonthlyKmAverage(
    List<MileageLog> logs, {
    DateTime? now,
  }) {
    if (logs.length < 2) return null;

    final ref = now ?? DateTime.now();
    final windowStart =
        DateTime(ref.year, ref.month - Thresholds.avgWindowMonths, ref.day);

    // Logs within the window, oldest -> newest.
    final windowed = logs.where((l) => l.recordedAt.isAfter(windowStart)).toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    // Need at least two points spanning some time to compute a rate.
    final usable = windowed.length >= 2
        ? windowed
        : (List.of(logs)..sort((a, b) => a.recordedAt.compareTo(b.recordedAt)));
    if (usable.length < 2) return null;

    final first = usable.first;
    final last = usable.last;
    final kmDelta = last.km - first.km;
    final dayDelta = last.recordedAt.difference(first.recordedAt).inDays;

    if (dayDelta <= 0 || kmDelta <= 0) return null;

    final perMonth = kmDelta / dayDelta * 30.0;
    // Guard against absurd values from noisy data.
    return perMonth.clamp(1.0, 20000.0);
  }

  /// Monthly km average, falling back to [Thresholds.fallbackKmPerMonth]
  /// when history is too thin to measure one.
  static double monthlyKmAverage(List<MileageLog> logs, {DateTime? now}) =>
      measuredMonthlyKmAverage(logs, now: now) ?? Thresholds.fallbackKmPerMonth;

  /// Forecast one maintenance type.
  ///
  /// Both forecasts are anchored on the *last recorded intervention*, never
  /// on the vehicle's current odometer or today's date. Anchoring on the
  /// current reading would move the target every time the car is driven, so
  /// a maintenance that has never been recorded could never fall due — it
  /// would sit at 0% forever. When an anchor is missing the corresponding
  /// forecast is simply not produced, and if neither is available the
  /// prediction is flagged [MaintenancePrediction.needsSetup] so the UI can
  /// ask for the missing information instead of showing a reassuring 0%.
  static MaintenancePrediction predict({
    required MaintenanceType type,
    required Vehicle vehicle,
    required double kmPerMonth,
    bool kmPerMonthIsEstimated = false,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();

    // ---- km-based forecast --------------------------------------------
    int? remainingKm;
    DateTime? kmDueDate;
    double? kmProgress; // fraction of the interval consumed (>1 = overdue)
    final intervalKm = type.intervalKm;
    final lastDoneKm = type.lastDoneKm;
    if (intervalKm != null && intervalKm > 0 && lastDoneKm != null) {
      remainingKm = lastDoneKm + intervalKm - vehicle.currentKm;
      kmProgress = (vehicle.currentKm - lastDoneKm) / intervalKm;
      if (kmPerMonth > 0) {
        kmDueDate = _addMonths(ref, remainingKm / kmPerMonth);
      }
    }

    // ---- time-based forecast ------------------------------------------
    DateTime? timeDueDate;
    double? timeProgress;
    final intervalMonths = type.intervalMonths;
    final lastDoneDate = type.lastDoneDate;
    if (intervalMonths != null && intervalMonths > 0 && lastDoneDate != null) {
      timeDueDate = DateTime(
          lastDoneDate.year, lastDoneDate.month + intervalMonths, lastDoneDate.day);
      final total = timeDueDate.difference(lastDoneDate).inDays;
      final elapsed = ref.difference(lastDoneDate).inDays;
      if (total > 0) timeProgress = elapsed / total;
    }

    // The binding constraint is whichever comes first.
    final needsSetup = kmProgress == null && timeProgress == null;
    final progress = math.max(kmProgress ?? 0.0, timeProgress ?? 0.0);

    return MaintenancePrediction(
      type: type,
      remainingKm: remainingKm,
      dueDate: _earliest(kmDueDate, timeDueDate),
      kmPerMonth: kmPerMonth,
      kmPerMonthIsEstimated: kmPerMonthIsEstimated,
      // Left unclamped on purpose: clamping to 1.0 would make "due today"
      // and "20 000 km overdue" compare equal, so the most-urgent-first
      // sort could not tell them apart. UI bars clamp at the point of use.
      urgency: needsSetup ? 0.0 : math.max(progress, 0.0),
      needsSetup: needsSetup,
    );
  }

  /// Whether a prediction should raise a reminder (section 4.3).
  ///
  /// [kmThreshold] and [daysThreshold] default to the built-in values but
  /// are overridden by the user's settings.
  static bool needsAlert(
    MaintenancePrediction p, {
    DateTime? now,
    int? kmThreshold,
    int? daysThreshold,
  }) {
    // Nothing to forecast means nothing to warn about — the UI asks the
    // user to fill in the missing anchor instead.
    if (p.needsSetup) return false;

    final ref = now ?? DateTime.now();
    if (p.remainingKm != null &&
        p.remainingKm! < (kmThreshold ?? Thresholds.kmAlert)) {
      return true;
    }
    if (p.dueDate != null) {
      final days = p.dueDate!.difference(ref).inDays;
      if (days < (daysThreshold ?? Thresholds.daysAlert)) return true;
    }
    return false;
  }

  static DateTime _addMonths(DateTime from, double months) {
    // A tiny km/month average against a large remaining distance can push
    // this into the year 18 000; cap it at a century either way so dates
    // stay printable.
    final capped = months.clamp(-1200.0, 1200.0);
    final whole = capped.floor();
    final fracDays = ((capped - whole) * 30).round();
    return DateTime(from.year, from.month + whole, from.day)
        .add(Duration(days: fracDays));
  }

  static DateTime? _earliest(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }
}
