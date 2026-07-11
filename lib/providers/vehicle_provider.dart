import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mileage_log.dart';
import '../models/vehicle.dart';
import 'service_providers.dart';

/// List of the current user's vehicles.
final vehiclesProvider =
    AsyncNotifierProvider<VehiclesNotifier, List<Vehicle>>(
        VehiclesNotifier.new);

class VehiclesNotifier extends AsyncNotifier<List<Vehicle>> {
  @override
  Future<List<Vehicle>> build() async {
    return ref.read(supabaseServiceProvider).fetchVehicles();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(supabaseServiceProvider).fetchVehicles());
  }

  Future<Vehicle> add(Vehicle v) async {
    final created = await ref.read(supabaseServiceProvider).createVehicle(v);
    await refresh();
    return created;
  }

  Future<void> update(String id, Map<String, dynamic> patch) async {
    await ref.read(supabaseServiceProvider).updateVehicle(id, patch);
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(supabaseServiceProvider).deleteVehicle(id);
    await refresh();
  }

  /// Add a mileage reading; the DB trigger updates current_km, so we refresh.
  Future<void> addMileage(String vehicleId, int km, {String? note}) async {
    await ref
        .read(supabaseServiceProvider)
        .addMileageLog(vehicleId, km, note: note);
    await refresh();
    ref.invalidate(mileageLogsProvider(vehicleId));
  }
}

/// A single vehicle by id, derived from the list.
final vehicleByIdProvider = Provider.family<Vehicle?, String>((ref, id) {
  final list = ref.watch(vehiclesProvider).value ?? const [];
  for (final v in list) {
    if (v.id == id) return v;
  }
  return null;
});

/// Mileage history for one vehicle (used by charts + prediction).
final mileageLogsProvider =
    FutureProvider.family<List<MileageLog>, String>((ref, vehicleId) async {
  return ref.read(supabaseServiceProvider).fetchMileageLogs(vehicleId);
});
