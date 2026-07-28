import '../models/maintenance_history.dart';

/// Pure business logic for fuel consumption — no I/O.
class FuelService {
  /// L/100km for each fuel entry, keyed by history id, computed from the
  /// km travelled since the previous fill-up. Ordered by km rather than
  /// doneAt: `done_at` is a date-only column, so same-day fill-ups (a
  /// common case — back-filling a couple of receipts at once) would tie
  /// on date and sort ambiguously, while km is monotonically increasing
  /// by definition. The first fill-up (and any entry missing km/liters,
  /// or with a non-increasing km delta) has no entry in the returned map.
  static Map<String, double> consumptionByEntryId(
      List<MaintenanceHistory> history) {
    final fuel = history
        .where((h) => h.isFuel && h.km != null && h.liters != null)
        .toList()
      ..sort((a, b) => a.km!.compareTo(b.km!));

    final result = <String, double>{};
    for (var i = 1; i < fuel.length; i++) {
      final prev = fuel[i - 1];
      final cur = fuel[i];
      final kmDelta = cur.km! - prev.km!;
      if (kmDelta > 0) {
        result[cur.id] = cur.liters! / kmDelta * 100;
      }
    }
    return result;
  }
}
