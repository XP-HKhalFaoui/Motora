import 'maintenance_type.dart';

/// Computed forecast for a single maintenance type.
class MaintenancePrediction {
  final MaintenanceType type;

  /// km before the maintenance is due (negative => overdue).
  final int? remainingKm;

  /// Estimated due date, from km forecast and/or the time interval.
  final DateTime? dueDate;

  /// Monthly km average used for the estimate.
  final double kmPerMonth;

  /// Whether [kmPerMonth] is a fallback guess rather than a figure measured
  /// from the vehicle's own mileage logs.
  final bool kmPerMonthIsEstimated;

  /// 0 = fresh, 1 = due now, >1 = overdue. Deliberately **not** clamped, so
  /// that sorting can distinguish "due today" from "long overdue"; clamp at
  /// the point of use when driving a progress bar.
  final double urgency;

  /// True when the type has no usable anchor (no last-done km for a km
  /// interval, no last-done date for a time interval), so nothing can be
  /// forecast. [urgency] is 0 in that case and must not be read as "fresh".
  final bool needsSetup;

  const MaintenancePrediction({
    required this.type,
    required this.remainingKm,
    required this.dueDate,
    required this.kmPerMonth,
    required this.urgency,
    this.kmPerMonthIsEstimated = false,
    this.needsSetup = false,
  });

  /// Fraction of the interval consumed, clamped for progress bars.
  double get progress => urgency.clamp(0.0, 1.0);

  bool get isDueSoon => !needsSetup && urgency >= 0.6;

  bool get isOverdue =>
      !needsSetup &&
      ((remainingKm != null && remainingKm! < 0) ||
          (dueDate != null && dueDate!.isBefore(DateTime.now())));
}
