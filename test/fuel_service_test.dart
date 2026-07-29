import 'package:carnet_auto/models/maintenance_history.dart';
import 'package:carnet_auto/services/fuel_service.dart';
import 'package:flutter_test/flutter_test.dart';

MaintenanceHistory _fill(
  String id, {
  int? km,
  double? liters,
  int day = 1,
  double? cost,
  bool full = true,
}) =>
    MaintenanceHistory(
      id: id,
      vehicleId: 'v1',
      title: 'Plein',
      km: km,
      liters: liters,
      cost: cost,
      kind: HistoryEntryKind.fuel,
      isFullTank: full,
      doneAt: DateTime(2026, 7, day),
    );

MaintenanceHistory _repair(String id, {int? km}) => MaintenanceHistory(
      id: id,
      vehicleId: 'v1',
      title: 'Vidange',
      km: km,
      doneAt: DateTime(2026, 7, 1),
    );

void main() {
  group('consumptionByEntryId', () {
    test('is empty without at least two fill-ups', () {
      expect(FuelService.consumptionByEntryId([]), isEmpty);
      expect(
        FuelService.consumptionByEntryId([_fill('a', km: 1000, liters: 40)]),
        isEmpty,
      );
    });

    test('computes L/100km from the km travelled since the last fill-up', () {
      final result = FuelService.consumptionByEntryId([
        _fill('a', km: 10000, liters: 40),
        _fill('b', km: 10500, liters: 35),
      ]);

      // 35 L over 500 km = 7 L/100km. The first fill-up has no baseline.
      expect(result, hasLength(1));
      expect(result['b'], closeTo(7.0, 0.0001));
      expect(result.containsKey('a'), isFalse);
    });

    test('ignores repairs interleaved with fill-ups', () {
      final result = FuelService.consumptionByEntryId([
        _fill('a', km: 10000, liters: 40),
        _repair('r', km: 10200),
        _fill('b', km: 10500, liters: 35),
      ]);

      expect(result.keys, ['b']);
      expect(result['b'], closeTo(7.0, 0.0001));
    });

    test('orders by km, not by date, so same-day fill-ups still work', () {
      // Both recorded on the same day — done_at is a date column, so the
      // dates tie and only km can order them.
      final result = FuelService.consumptionByEntryId([
        _fill('later', km: 10500, liters: 35, day: 3),
        _fill('earlier', km: 10000, liters: 40, day: 3),
      ]);

      expect(result.keys, ['later']);
      expect(result['later'], closeTo(7.0, 0.0001));
    });

    test('skips entries missing km or liters', () {
      final result = FuelService.consumptionByEntryId([
        _fill('a', km: 10000, liters: 40),
        _fill('b', km: 10500),
        _fill('c', liters: 35),
      ]);
      expect(result, isEmpty);
    });

    test('skips a non-increasing km delta rather than dividing by zero', () {
      final result = FuelService.consumptionByEntryId([
        _fill('a', km: 10000, liters: 40),
        _fill('b', km: 10000, liters: 35),
      ]);
      expect(result, isEmpty);
    });
  });

  group('partial fill-ups', () {
    test('carries their litres into the next full tank', () {
      // Brim, +20 L partial, brim. 20 + 30 = 50 L over 1000 km = 5 L/100.
      final result = FuelService.consumptionByEntryId([
        _fill('brim1', km: 10000, liters: 40),
        _fill('partial', km: 10400, liters: 20, full: false),
        _fill('brim2', km: 11000, liters: 30),
      ]);

      expect(result.keys, ['brim2'],
          reason: 'a partial fill cannot be measured on its own');
      expect(result['brim2'], closeTo(5.0, 0.0001));
    });

    test('measuring a partial as if it were full would be wrong', () {
      // The same data read the old way — 30 L over the 600 km since the
      // partial — gives 5 L/100 by coincidence of these numbers, so use a
      // case where the two differ.
      final result = FuelService.consumptionByEntryId([
        _fill('brim1', km: 10000, liters: 40),
        _fill('partial', km: 10100, liters: 10, full: false),
        _fill('brim2', km: 10500, liters: 30),
      ]);
      // 40 L over 500 km = 8 L/100. Treating the partial as a full tank
      // would have reported 30 L / 400 km = 7.5.
      expect(result['brim2'], closeTo(8.0, 0.0001));
    });
  });

  group('analyze', () {
    test('is empty for a vehicle with no fill-ups', () {
      final stats = FuelService.analyze([_repair('r', km: 1000)]);
      expect(stats.fillUps, 0);
      expect(stats.averageConsumption, isNull);
      expect(stats.costPerKm, isNull);
    });

    test('weights the average by distance, not by stretch count', () {
      // 900 km at 5 L/100 (45 L), then 100 km at 15 L/100 (15 L).
      // Distance-weighted: 60 L / 1000 km = 6 L/100.
      // A plain mean of the two figures would say 10.
      final stats = FuelService.analyze([
        _fill('a', km: 0, liters: 30),
        _fill('b', km: 900, liters: 45),
        _fill('c', km: 1000, liters: 15),
      ]);
      expect(stats.averageConsumption, closeTo(6.0, 0.0001));
    });

    test('totals cost and litres, and derives cost per km', () {
      final stats = FuelService.analyze([
        _fill('a', km: 10000, liters: 40, cost: 60),
        _fill('b', km: 10500, liters: 35, cost: 50),
      ]);

      expect(stats.fillUps, 2);
      expect(stats.totalLiters, closeTo(75, 0.0001));
      expect(stats.totalCost, closeTo(110, 0.0001));
      expect(stats.kmCovered, 500);
      expect(stats.costPerKm, closeTo(110 / 500, 0.0001));
    });

    test('leaves cost per km null when no fill-up carries a price', () {
      final stats = FuelService.analyze([
        _fill('a', km: 10000, liters: 40),
        _fill('b', km: 10500, liters: 35),
      ]);
      expect(stats.costPerKm, isNull);
      expect(stats.averageConsumption, closeTo(7.0, 0.0001));
    });
  });
}
