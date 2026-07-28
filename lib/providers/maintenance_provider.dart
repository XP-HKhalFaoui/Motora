import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/maintenance_history.dart';
import '../models/maintenance_prediction.dart';
import '../models/maintenance_type.dart';
import '../services/prediction_service.dart';
import 'garage_provider.dart';
import 'service_providers.dart';
import 'vehicle_provider.dart';

/// Maintenance types for a vehicle.
final maintenanceTypesProvider =
    FutureProvider.family<List<MaintenanceType>, String>(
        (ref, vehicleId) async {
  return ref.read(supabaseServiceProvider).fetchMaintenanceTypes(vehicleId);
});

/// Repair/intervention history for a vehicle.
final maintenanceHistoryProvider =
    FutureProvider.family<List<MaintenanceHistory>, String>(
        (ref, vehicleId) async {
  return ref.read(supabaseServiceProvider).fetchHistory(vehicleId);
});

/// Computed predictions for every maintenance type of a vehicle, ordered
/// most-urgent first. Combines vehicle km, mileage logs and the interval
/// config through [PredictionService].
final predictionsProvider =
    FutureProvider.family<List<MaintenancePrediction>, String>(
        (ref, vehicleId) async {
  final vehicle = ref.watch(vehicleByIdProvider(vehicleId));
  final types = await ref.watch(maintenanceTypesProvider(vehicleId).future);
  final logs = await ref.watch(mileageLogsProvider(vehicleId).future);
  if (vehicle == null) return const [];

  final measured = PredictionService.measuredMonthlyKmAverage(logs);
  final kmPerMonth = measured ?? Thresholds.fallbackKmPerMonth;
  // Types that can't be forecast yet sort last: they carry urgency 0 but
  // "unknown" is not the same as "fresh", so they shouldn't outrank a
  // healthy échéance either.
  final preds = types
      .map((t) => PredictionService.predict(
            type: t,
            vehicle: vehicle,
            kmPerMonth: kmPerMonth,
            kmPerMonthIsEstimated: measured == null,
          ))
      .toList()
    ..sort((a, b) {
      if (a.needsSetup != b.needsSetup) return a.needsSetup ? 1 : -1;
      return b.urgency.compareTo(a.urgency);
    });
  return preds;
});

/// Mutations for maintenance types + history. Invalidates dependents.
final maintenanceControllerProvider =
    Provider<MaintenanceController>((ref) => MaintenanceController(ref));

class MaintenanceController {
  MaintenanceController(this.ref);
  final Ref ref;

  Future<void> addType(MaintenanceType t) async {
    await ref.read(supabaseServiceProvider).createMaintenanceType(t);
    _invalidate(t.vehicleId);
  }

  Future<void> updateType(
      String vehicleId, String id, Map<String, dynamic> patch) async {
    await ref.read(supabaseServiceProvider).updateMaintenanceType(id, patch);
    _invalidate(vehicleId);
  }

  Future<void> deleteType(String vehicleId, String id) async {
    await ref.read(supabaseServiceProvider).deleteMaintenanceType(id);
    _invalidate(vehicleId);
  }

  /// Records the intervention and, if a km reading was entered, feeds it
  /// into mileage_logs too — so the vehicle's current km (and the km/month
  /// average used for predictions) stays centralized no matter which entry
  /// point (entretien, carburant, or the dedicated km-update sheet) it came
  /// from. The DB trigger only ever raises current_km (GREATEST), so a
  /// back-filled reading from an older, lower-km intervention is safe.
  Future<void> addHistory(MaintenanceHistory h) async {
    await ref.read(supabaseServiceProvider).addHistory(h);
    if (h.km != null) {
      await ref.read(vehiclesProvider.notifier).addMileage(
            h.vehicleId,
            h.km!,
            note: h.title,
          );
    }
    _invalidateHistory(h.vehicleId);
  }

  /// Edits an existing intervention. Unlike [addHistory], this doesn't
  /// touch mileage_logs — an edit is a correction to an already-recorded
  /// event, not a new odometer reading, so it shouldn't add another log
  /// entry (that already happened when the intervention was first saved).
  Future<void> updateHistory(MaintenanceHistory h) async {
    await ref.read(supabaseServiceProvider).updateHistory(h);
    _invalidateHistory(h.vehicleId);
  }

  Future<void> deleteHistory(String vehicleId, String id) async {
    await ref.read(supabaseServiceProvider).deleteHistory(id);
    _invalidateHistory(vehicleId);
  }

  void _invalidate(String vehicleId) {
    ref.invalidate(maintenanceTypesProvider(vehicleId));
    ref.invalidate(predictionsProvider(vehicleId));
  }

  /// Anything that touches an intervention also moves the linked type's
  /// anchor (recomputed by the DB trigger) and the per-garage intervention
  /// counts, so those caches have to go too. deleteHistory used to refresh
  /// only the history list, leaving stale predictions behind.
  void _invalidateHistory(String vehicleId) {
    _invalidate(vehicleId);
    ref.invalidate(maintenanceHistoryProvider(vehicleId));
    ref.invalidate(garageCountsProvider);
  }
}
