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

  /// 0 = fresh, 1 = due now, >1 = overdue (clamped in [0,1] for UI bars).
  final double urgency;

  const MaintenancePrediction({
    required this.type,
    required this.remainingKm,
    required this.dueDate,
    required this.kmPerMonth,
    required this.urgency,
  });

  bool get isDueSoon => urgency >= 0.6;
  bool get isOverdue => (remainingKm != null && remainingKm! < 0) ||
      (dueDate != null && dueDate!.isBefore(DateTime.now()));
}
