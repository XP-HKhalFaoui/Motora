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
  /// Rolling monthly km average from mileage logs over the last
  /// [Thresholds.avgWindowMonths] months. Falls back to a sensible default
  /// when there isn't enough history to be meaningful.
  static double monthlyKmAverage(
    List<MileageLog> logs, {
    DateTime? now,
  }) {
    if (logs.length < 2) return Thresholds.fallbackKmPerMonth;

    final ref = now ?? DateTime.now();
    final windowStart =
        DateTime(ref.year, ref.month - Thresholds.avgWindowMonths, ref.day);

    // Logs within the window, oldest -> newest.
    final windowed = logs
        .where((l) => l.recordedAt.isAfter(windowStart))
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    // Need at least two points spanning some time to compute a rate.
    final usable = windowed.length >= 2 ? windowed : (List.of(logs)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt)));
    if (usable.length < 2) return Thresholds.fallbackKmPerMonth;

    final first = usable.first;
    final last = usable.last;
    final kmDelta = last.km - first.km;
    final dayDelta = last.recordedAt.difference(first.recordedAt).inDays;

    if (dayDelta <= 0 || kmDelta <= 0) return Thresholds.fallbackKmPerMonth;

    final perDay = kmDelta / dayDelta;
    final perMonth = perDay * 30.0;
    // Guard against absurd values from noisy data.
    return perMonth.clamp(1.0, 20000.0);
  }

  /// Forecast one maintenance type.
  static MaintenancePrediction predict({
    required MaintenanceType type,
    required Vehicle vehicle,
    required double kmPerMonth,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();

    // ---- km-based forecast --------------------------------------------
    int? remainingKm;
    DateTime? kmDueDate;
    double? kmProgress; // 0..1 of the interval consumed
    if (type.intervalKm != null && type.intervalKm! > 0) {
      final base = type.lastDoneKm ?? vehicle.currentKm;
      final target = base + type.intervalKm!;
      remainingKm = target - vehicle.currentKm;
      kmProgress =
          ((vehicle.currentKm - base) / type.intervalKm!).clamp(0.0, 2.0);
      if (kmPerMonth > 0) {
        final months = remainingKm / kmPerMonth;
        kmDueDate = _addMonths(ref, months);
      }
    }

    // ---- time-based forecast ------------------------------------------
    DateTime? timeDueDate;
    double? timeProgress;
    if (type.intervalMonths != null && type.intervalMonths! > 0) {
      final base = type.lastDoneDate ?? vehicle.createdAt ?? ref;
      timeDueDate = DateTime(
          base.year, base.month + type.intervalMonths!, base.day);
      final total = timeDueDate.difference(base).inDays;
      final elapsed = ref.difference(base).inDays;
      if (total > 0) timeProgress = (elapsed / total).clamp(0.0, 2.0);
    }

    // The binding constraint is whichever comes first.
    final dueDate = _earliest(kmDueDate, timeDueDate);
    final progress =
        math.max(kmProgress ?? 0.0, timeProgress ?? 0.0);

    return MaintenancePrediction(
      type: type,
      remainingKm: remainingKm,
      dueDate: dueDate,
      kmPerMonth: kmPerMonth,
      urgency: progress.clamp(0.0, 1.0),
    );
  }

  /// Whether a prediction should raise a reminder (section 4.3).
  static bool needsAlert(MaintenancePrediction p, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    if (p.remainingKm != null && p.remainingKm! < Thresholds.kmAlert) {
      return true;
    }
    if (p.dueDate != null) {
      final days = p.dueDate!.difference(ref).inDays;
      if (days < Thresholds.daysAlert) return true;
    }
    return false;
  }

  static DateTime _addMonths(DateTime from, double months) {
    final whole = months.floor();
    final fracDays = ((months - whole) * 30).round();
    final base = DateTime(from.year, from.month + whole, from.day);
    return base.add(Duration(days: fracDays));
  }

  static DateTime? _earliest(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }
}
