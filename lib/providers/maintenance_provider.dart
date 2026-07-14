import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/maintenance_history.dart';
import '../models/maintenance_prediction.dart';
import '../models/maintenance_type.dart';
import '../services/prediction_service.dart';
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

  final kmPerMonth = PredictionService.monthlyKmAverage(logs);
  final preds = types
      .map((t) => PredictionService.predict(
            type: t,
            vehicle: vehicle,
            kmPerMonth: kmPerMonth,
          ))
      .toList()
    ..sort((a, b) => b.urgency.compareTo(a.urgency));
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

  Future<void> addHistory(MaintenanceHistory h) async {
    await ref.read(supabaseServiceProvider).addHistory(h);
    _invalidate(h.vehicleId);
    ref.invalidate(maintenanceHistoryProvider(h.vehicleId));
  }

  Future<void> deleteHistory(String vehicleId, String id) async {
    await ref.read(supabaseServiceProvider).deleteHistory(id);
    ref.invalidate(maintenanceHistoryProvider(vehicleId));
  }

  void _invalidate(String vehicleId) {
    ref.invalidate(maintenanceTypesProvider(vehicleId));
    ref.invalidate(predictionsProvider(vehicleId));
  }
}
