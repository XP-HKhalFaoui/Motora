import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mileage_log.dart';
import '../models/vehicle.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

/// List of the current user's vehicles.
final vehiclesProvider = AsyncNotifierProvider<VehiclesNotifier, List<Vehicle>>(
    VehiclesNotifier.new);

class VehiclesNotifier extends AsyncNotifier<List<Vehicle>> {
  @override
  Future<List<Vehicle>> build() async {
    // Tied to the session: rebuilt when the signed-in user changes, and
    // never fetched at all without one. Previously this was built once,
    // whenever it first happened to be read — possibly before the session
    // was restored — and kept serving the old account's rows afterwards.
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];
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

  Future<void> updateVehicle(String id, Map<String, dynamic> patch) async {
    await ref.read(supabaseServiceProvider).updateVehicle(id, patch);
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(supabaseServiceProvider).deleteVehicle(id);
    await refresh();
  }

  /// Add a mileage reading; the DB trigger updates current_km, so we refresh.
  /// A [photoUrl] marks the reading as "certifié" rather than "déclaratif".
  Future<void> addMileage(String vehicleId, int km,
      {String? note, String? photoUrl}) async {
    await ref
        .read(supabaseServiceProvider)
        .addMileageLog(vehicleId, km, note: note, photoUrl: photoUrl);
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
