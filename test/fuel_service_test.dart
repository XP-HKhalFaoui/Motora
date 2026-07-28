import 'package:carnet_auto/models/maintenance_history.dart';
import 'package:carnet_auto/services/fuel_service.dart';
import 'package:flutter_test/flutter_test.dart';

MaintenanceHistory _fill(String id, {int? km, double? liters, int day = 1}) =>
    MaintenanceHistory(
      id: id,
      vehicleId: 'v1',
      title: 'Plein',
      km: km,
      liters: liters,
      isFuel: true,
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
}
