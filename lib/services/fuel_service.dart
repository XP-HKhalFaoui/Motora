import '../models/maintenance_history.dart';

/// Aggregate fuel figures for one vehicle.
class FuelStats {
  const FuelStats({
    required this.consumptionByEntryId,
    required this.averageConsumption,
    required this.costPerKm,
    required this.totalCost,
    required this.totalLiters,
    required this.fillUps,
    required this.kmCovered,
  });

  /// L/100km for each measurable fill-up, keyed by history id.
  final Map<String, double> consumptionByEntryId;

  /// L/100km across every measured stretch, weighted by distance, or null
  /// when nothing can be measured yet.
  final double? averageConsumption;

  /// Fuel cost per km over the covered distance, or null if unknown.
  final double? costPerKm;

  final double totalCost;
  final double totalLiters;
  final int fillUps;

  /// Distance between the first and last fill-up.
  final int kmCovered;

  static const empty = FuelStats(
    consumptionByEntryId: {},
    averageConsumption: null,
    costPerKm: null,
    totalCost: 0,
    totalLiters: 0,
    fillUps: 0,
    kmCovered: 0,
  );
}

/// Pure business logic for fuel consumption — no I/O.
class FuelService {
  /// L/100km for each fill-up that closes a full-tank-to-full-tank stretch.
  ///
  /// Ordered by km rather than doneAt: `done_at` is a date-only column, so
  /// same-day fill-ups — a common case when back-filling receipts — tie on
  /// date and sort ambiguously, while km is monotonically increasing by
  /// definition.
  ///
  /// Only a stretch between two brimmed tanks is measurable. Litres from
  /// partial fills in between are carried forward and counted into the next
  /// full tank, which is what actually went into the engine over that
  /// distance; a partial fill itself gets no figure of its own.
  static Map<String, double> consumptionByEntryId(
      List<MaintenanceHistory> history) {
    final fuel = _orderedFuel(history);

    final result = <String, double>{};
    int? anchorKm;
    var carriedLiters = 0.0;

    for (final entry in fuel) {
      if (!entry.isFullTank) {
        // Poured in, but the tank level is unknown — remember the litres
        // and wait for the next brimmed tank to close the stretch.
        carriedLiters += entry.liters!;
        continue;
      }

      final litersForStretch = carriedLiters + entry.liters!;
      if (anchorKm != null) {
        final kmDelta = entry.km! - anchorKm;
        if (kmDelta > 0) {
          result[entry.id] = litersForStretch / kmDelta * 100;
        }
      }
      anchorKm = entry.km;
      carriedLiters = 0;
    }
    return result;
  }

  /// Everything the Carburant section shows, in one pass.
  static FuelStats analyze(List<MaintenanceHistory> history) {
    final fuel = history.where((h) => h.isFuel).toList();
    if (fuel.isEmpty) return FuelStats.empty;

    final measurable = _orderedFuel(history);
    final consumption = consumptionByEntryId(history);

    final totalCost = fuel.fold<double>(0, (s, h) => s + (h.cost ?? 0));
    final totalLiters = fuel.fold<double>(0, (s, h) => s + (h.liters ?? 0));

    final kmCovered =
        measurable.length >= 2 ? measurable.last.km! - measurable.first.km! : 0;

    // Distance-weighted rather than a mean of the per-stretch figures: a
    // 30 km stretch shouldn't count as much as a 900 km one.
    double? average;
    if (consumption.isNotEmpty) {
      var litres = 0.0;
      var km = 0;
      int? anchorKm;
      var carried = 0.0;
      for (final entry in measurable) {
        if (!entry.isFullTank) {
          carried += entry.liters!;
          continue;
        }
        if (anchorKm != null && entry.km! > anchorKm) {
          litres += carried + entry.liters!;
          km += entry.km! - anchorKm;
        }
        anchorKm = entry.km;
        carried = 0;
      }
      if (km > 0) average = litres / km * 100;
    }

    // Only fill-ups that carry a cost contribute, so a missing price
    // doesn't silently deflate the figure.
    final pricedCost = fuel
        .where((h) => h.cost != null)
        .fold<double>(0, (s, h) => s + h.cost!);
    final costPerKm =
        kmCovered > 0 && pricedCost > 0 ? pricedCost / kmCovered : null;

    return FuelStats(
      consumptionByEntryId: consumption,
      averageConsumption: average,
      costPerKm: costPerKm,
      totalCost: totalCost,
      totalLiters: totalLiters,
      fillUps: fuel.length,
      kmCovered: kmCovered,
    );
  }

  /// Fuel entries usable for maths — km and litres present — oldest first.
  static List<MaintenanceHistory> _orderedFuel(
      List<MaintenanceHistory> history) {
    return history
        .where((h) => h.isFuel && h.km != null && h.liters != null)
        .toList()
      ..sort((a, b) => a.km!.compareTo(b.km!));
  }
}
