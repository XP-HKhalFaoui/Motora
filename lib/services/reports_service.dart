import '../models/maintenance_history.dart';
import '../models/mileage_log.dart';
import 'fuel_service.dart';

enum ReportPeriod { last3Months, last12Months, thisYear, all }

/// Spend split the way the app already separates its ledger.
class CategoryTotals {
  const CategoryTotals({
    required this.fuel,
    required this.maintenance,
    required this.expense,
  });

  final double fuel;
  final double maintenance;
  final double expense;

  double get total => fuel + maintenance + expense;

  static const zero = CategoryTotals(fuel: 0, maintenance: 0, expense: 0);
}

/// One bar of the monthly chart.
class MonthlyTotals {
  const MonthlyTotals({required this.month, required this.totals});

  /// First day of the month, so bars sort and label without ambiguity.
  final DateTime month;
  final CategoryTotals totals;
}

class VehicleReport {
  const VehicleReport({
    required this.totals,
    required this.monthly,
    required this.entryCount,
    required this.distanceKm,
    required this.days,
    required this.costPerKm,
    required this.costPerDay,
    required this.averageConsumption,
    required this.bestConsumption,
    required this.worstConsumption,
    required this.from,
  });

  final CategoryTotals totals;
  final List<MonthlyTotals> monthly;
  final int entryCount;

  /// Distance covered over the window, from every odometer reading in it.
  final int distanceKm;

  /// Days the window actually spans.
  final int days;

  /// Null rather than zero when the denominator is unknown — a cost per km
  /// computed from no distance would read as "this car is free".
  final double? costPerKm;
  final double? costPerDay;

  final double? averageConsumption;
  final double? bestConsumption;
  final double? worstConsumption;

  /// Start of the window, null when reporting over everything.
  final DateTime? from;

  bool get isEmpty => entryCount == 0;

  static const empty = VehicleReport(
    totals: CategoryTotals.zero,
    monthly: [],
    entryCount: 0,
    distanceKm: 0,
    days: 0,
    costPerKm: null,
    costPerDay: null,
    averageConsumption: null,
    bestConsumption: null,
    worstConsumption: null,
    from: null,
  );
}

/// Turns the ledger into the figures the Rapports screen shows.
///
/// Pure: no I/O, no clock except the injectable [now], so every number
/// here is testable on fixed data.
class ReportsService {
  static VehicleReport build({
    required List<MaintenanceHistory> history,
    required List<MileageLog> logs,
    required ReportPeriod period,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final from = startOf(period, ref);

    final entries = from == null
        ? history
        : history.where((h) => !h.doneAt.isBefore(from)).toList();
    if (entries.isEmpty) return VehicleReport.empty;

    var fuel = 0.0, maintenance = 0.0, expense = 0.0;
    for (final e in entries) {
      final cost = e.cost ?? 0;
      switch (e.kind) {
        case HistoryEntryKind.fuel:
          fuel += cost;
        case HistoryEntryKind.maintenance:
          maintenance += cost;
        case HistoryEntryKind.expense:
          expense += cost;
      }
    }
    final totals =
        CategoryTotals(fuel: fuel, maintenance: maintenance, expense: expense);

    // Distance from every odometer reading in the window, whichever entry
    // carried it — mileage logs and history rows both record km.
    final readings = <int>[
      for (final l in logs)
        if (from == null || !l.recordedAt.isBefore(from)) l.km,
      for (final e in entries)
        if (e.km != null) e.km!,
    ]..sort();
    final distanceKm =
        readings.length >= 2 ? readings.last - readings.first : 0;

    final windowStart = from ??
        entries.map((e) => e.doneAt).reduce((a, b) => a.isBefore(b) ? a : b);
    final days = ref.difference(windowStart).inDays.clamp(1, 1 << 30);

    // Consumption is only meaningful over full-tank stretches, and only
    // for the fill-ups inside the window.
    final consumption = FuelService.consumptionByEntryId(history);
    final windowed = <double>[
      for (final e in entries)
        if (consumption[e.id] != null) consumption[e.id]!,
    ];

    return VehicleReport(
      totals: totals,
      monthly: _monthly(entries),
      entryCount: entries.length,
      distanceKm: distanceKm,
      days: days,
      costPerKm: distanceKm > 0 ? totals.total / distanceKm : null,
      costPerDay: totals.total > 0 ? totals.total / days : null,
      averageConsumption: windowed.isEmpty
          ? null
          : windowed.reduce((a, b) => a + b) / windowed.length,
      bestConsumption:
          windowed.isEmpty ? null : windowed.reduce((a, b) => a < b ? a : b),
      worstConsumption:
          windowed.isEmpty ? null : windowed.reduce((a, b) => a > b ? a : b),
      from: from,
    );
  }

  /// Start of [period], or null for "everything".
  static DateTime? startOf(ReportPeriod period, DateTime now) =>
      switch (period) {
        ReportPeriod.last3Months => DateTime(now.year, now.month - 2, 1),
        ReportPeriod.last12Months => DateTime(now.year, now.month - 11, 1),
        ReportPeriod.thisYear => DateTime(now.year, 1, 1),
        ReportPeriod.all => null,
      };

  /// Oldest month first, with empty months in between kept so the chart
  /// shows a gap rather than silently compressing time.
  static List<MonthlyTotals> _monthly(List<MaintenanceHistory> entries) {
    final buckets = <DateTime, List<double>>{};
    for (final e in entries) {
      final key = DateTime(e.doneAt.year, e.doneAt.month);
      final slot = buckets.putIfAbsent(key, () => [0, 0, 0]);
      final cost = e.cost ?? 0;
      switch (e.kind) {
        case HistoryEntryKind.fuel:
          slot[0] += cost;
        case HistoryEntryKind.maintenance:
          slot[1] += cost;
        case HistoryEntryKind.expense:
          slot[2] += cost;
      }
    }
    if (buckets.isEmpty) return const [];

    final months = buckets.keys.toList()..sort();
    final result = <MonthlyTotals>[];
    for (var m = months.first;
        !m.isAfter(months.last);
        m = DateTime(m.year, m.month + 1)) {
      final slot = buckets[m] ?? const [0.0, 0.0, 0.0];
      result.add(MonthlyTotals(
        month: m,
        totals: CategoryTotals(
            fuel: slot[0], maintenance: slot[1], expense: slot[2]),
      ));
    }
    return result;
  }
}
