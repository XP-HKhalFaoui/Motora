import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'vehicle_provider.dart';

/// The vehicle currently selected on the Entretien / Documents screens
/// (and defaulted to for the quick-add sheet). `null` until a vehicle
/// list has loaded; [effectiveSelectedVehicleIdProvider] falls back to
/// the first vehicle so screens never have to special-case "unset".
final selectedVehicleIdProvider = StateProvider<String?>((ref) => null);

final effectiveSelectedVehicleIdProvider = Provider<String?>((ref) {
  final explicit = ref.watch(selectedVehicleIdProvider);
  final vehicles = ref.watch(vehiclesProvider).value ?? const [];
  if (explicit != null && vehicles.any((v) => v.id == explicit)) {
    return explicit;
  }
  return vehicles.isEmpty ? null : vehicles.first.id;
});
