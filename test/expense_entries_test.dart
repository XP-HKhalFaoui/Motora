import 'package:carnet_auto/core/constants.dart';
import 'package:carnet_auto/models/maintenance_history.dart';
import 'package:carnet_auto/services/fuel_service.dart';
import 'package:carnet_auto/services/history_filter.dart';
import 'package:flutter_test/flutter_test.dart';

MaintenanceHistory _entry(
  String id,
  HistoryEntryKind kind, {
  double? cost,
  String? category,
  double? liters,
  int? km,
}) =>
    MaintenanceHistory(
      id: id,
      vehicleId: 'v1',
      title: id,
      kind: kind,
      category: category,
      cost: cost,
      liters: liters,
      km: km,
      doneAt: DateTime(2026, 7, 1),
    );

void main() {
  group('kind round-trips', () {
    test('serialises as a string and keeps is_fuel in sync', () {
      final json = _entry('e', HistoryEntryKind.expense,
              category: ExpenseCategories.assurance)
          .toInsert();

      expect(json['kind'], 'expense');
      expect(json['category'], 'assurance');
      // Written for APKs built before migration 0007.
      expect(json['is_fuel'], isFalse);
    });

    test('reads rows written before the kind column existed', () {
      // Those rows carry only the boolean.
      final legacyFuel = MaintenanceHistory.fromJson({
        'id': 'f',
        'vehicle_id': 'v1',
        'title': 'Plein',
        'done_at': '2026-07-01',
        'is_fuel': true,
      });
      final legacyRepair = MaintenanceHistory.fromJson({
        'id': 'r',
        'vehicle_id': 'v1',
        'title': 'Vidange',
        'done_at': '2026-07-01',
        'is_fuel': false,
      });

      expect(legacyFuel.kind, HistoryEntryKind.fuel);
      expect(legacyRepair.kind, HistoryEntryKind.maintenance);
    });

    test('the explicit column wins over the legacy boolean', () {
      final row = MaintenanceHistory.fromJson({
        'id': 'x',
        'vehicle_id': 'v1',
        'title': 'Assurance',
        'done_at': '2026-07-01',
        'kind': 'expense',
        'is_fuel': false,
      });
      expect(row.kind, HistoryEntryKind.expense);
      expect(row.isMaintenance, isFalse);
    });
  });

  group('expenses stay out of the maintenance record', () {
    final items = [
      _entry('r', HistoryEntryKind.maintenance, cost: 8000),
      _entry('f', HistoryEntryKind.fuel, cost: 1000, liters: 32, km: 1000),
      _entry('e', HistoryEntryKind.expense,
          cost: 12000, category: ExpenseCategories.assurance),
    ];

    test('the maintenance filter excludes fuel and expenses alike', () {
      final result =
          const HistoryFilter(kind: HistoryKind.maintenance).apply(items);
      expect(result.map((h) => h.id), ['r']);
    });

    test('expenses have their own filter', () {
      final result =
          const HistoryFilter(kind: HistoryKind.expense).apply(items);
      expect(result.map((h) => h.id), ['e']);
    });

    test('an expense never counts as fuel', () {
      // It carries a cost but no litres; letting it through would corrupt
      // the L/100km maths.
      final stats = FuelService.analyze(items);
      expect(stats.fillUps, 1);
      expect(stats.totalCost, 1000);
    });
  });
}
