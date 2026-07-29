import 'package:carnet_auto/models/maintenance_history.dart';
import 'package:carnet_auto/models/mileage_log.dart';
import 'package:carnet_auto/services/reports_service.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 7, 28);

MaintenanceHistory _e(
  String id,
  HistoryEntryKind kind,
  DateTime at, {
  double? cost,
  int? km,
  double? liters,
}) =>
    MaintenanceHistory(
      id: id,
      vehicleId: 'v1',
      title: id,
      kind: kind,
      cost: cost,
      km: km,
      liters: liters,
      doneAt: at,
    );

MileageLog _log(int km, DateTime at) =>
    MileageLog(id: '$km', vehicleId: 'v1', km: km, recordedAt: at);

void main() {
  test('an empty ledger reports nothing rather than zeros', () {
    final r = ReportsService.build(
        history: const [], logs: const [], period: ReportPeriod.all);
    expect(r.isEmpty, isTrue);
    expect(r.costPerKm, isNull);
    expect(r.costPerDay, isNull);
  });

  test('splits spend by the three kinds', () {
    final r = ReportsService.build(
      history: [
        _e('f', HistoryEntryKind.fuel, DateTime(2026, 7, 1), cost: 1000),
        _e('m', HistoryEntryKind.maintenance, DateTime(2026, 7, 2), cost: 8000),
        _e('x', HistoryEntryKind.expense, DateTime(2026, 7, 3), cost: 12000),
      ],
      logs: const [],
      period: ReportPeriod.all,
      now: _now,
    );

    expect(r.totals.fuel, 1000);
    expect(r.totals.maintenance, 8000);
    expect(r.totals.expense, 12000);
    expect(r.totals.total, 21000);
  });

  test('the period window excludes older entries', () {
    final history = [
      _e('old', HistoryEntryKind.fuel, DateTime(2025, 1, 15), cost: 500),
      _e('new', HistoryEntryKind.fuel, DateTime(2026, 7, 1), cost: 1000),
    ];

    final year = ReportsService.build(
        history: history,
        logs: const [],
        period: ReportPeriod.thisYear,
        now: _now);
    final all = ReportsService.build(
        history: history, logs: const [], period: ReportPeriod.all, now: _now);

    expect(year.totals.total, 1000);
    expect(all.totals.total, 1500);
  });

  test('distance uses every odometer reading, wherever it came from', () {
    // One from a mileage log, one carried by a fill-up.
    final r = ReportsService.build(
      history: [
        _e('f', HistoryEntryKind.fuel, DateTime(2026, 7, 20),
            cost: 1000, km: 10500),
      ],
      logs: [_log(10000, DateTime(2026, 7, 1))],
      period: ReportPeriod.all,
      now: _now,
    );

    expect(r.distanceKm, 500);
    expect(r.costPerKm, closeTo(1000 / 500, 0.0001));
  });

  test('cost per km stays null when no distance is known', () {
    // The regression this guards: dividing by zero distance would print a
    // cost per km of 0, i.e. "this car is free".
    final r = ReportsService.build(
      history: [
        _e('x', HistoryEntryKind.expense, DateTime(2026, 7, 1), cost: 12000),
      ],
      logs: const [],
      period: ReportPeriod.all,
      now: _now,
    );

    expect(r.totals.total, 12000);
    expect(r.distanceKm, 0);
    expect(r.costPerKm, isNull);
  });

  test('monthly buckets keep empty months instead of compressing time', () {
    final r = ReportsService.build(
      history: [
        _e('a', HistoryEntryKind.fuel, DateTime(2026, 4, 10), cost: 100),
        // Nothing in May or June.
        _e('b', HistoryEntryKind.fuel, DateTime(2026, 7, 10), cost: 200),
      ],
      logs: const [],
      period: ReportPeriod.all,
      now: _now,
    );

    expect(r.monthly.map((m) => m.month), [
      DateTime(2026, 4),
      DateTime(2026, 5),
      DateTime(2026, 6),
      DateTime(2026, 7),
    ]);
    expect(r.monthly[1].totals.total, 0);
    expect(r.monthly.last.totals.fuel, 200);
  });

  test('consumption reports its range, not just the average', () {
    // Three full tanks: 500 km on 40 L (8.0), then 500 km on 25 L (5.0).
    final r = ReportsService.build(
      history: [
        _e('f1', HistoryEntryKind.fuel, DateTime(2026, 7, 1),
            km: 10000, liters: 30, cost: 900),
        _e('f2', HistoryEntryKind.fuel, DateTime(2026, 7, 10),
            km: 10500, liters: 40, cost: 1200),
        _e('f3', HistoryEntryKind.fuel, DateTime(2026, 7, 20),
            km: 11000, liters: 25, cost: 750),
      ],
      logs: const [],
      period: ReportPeriod.all,
      now: _now,
    );

    expect(r.bestConsumption, closeTo(5.0, 0.0001));
    expect(r.worstConsumption, closeTo(8.0, 0.0001));
    expect(r.averageConsumption, closeTo(6.5, 0.0001));
  });
}
