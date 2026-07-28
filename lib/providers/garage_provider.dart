import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/garage.dart';
import 'service_providers.dart';

/// The current user's garages (repair shops), ordered by name.
final garagesProvider = FutureProvider<List<Garage>>((ref) async {
  return ref.read(supabaseServiceProvider).fetchGarages();
});

/// Number of interventions linked to each garage, keyed by garage id.
final garageCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.read(supabaseServiceProvider).fetchGarageInterventionCounts();
});

final garageControllerProvider =
    Provider<GarageController>((ref) => GarageController(ref));

class GarageController {
  GarageController(this.ref);
  final Ref ref;

  Future<Garage> add(Garage g) async {
    final created = await ref.read(supabaseServiceProvider).createGarage(g);
    ref.invalidate(garagesProvider);
    return created;
  }

  Future<void> update(String id, Map<String, dynamic> patch) async {
    await ref.read(supabaseServiceProvider).updateGarage(id, patch);
    ref.invalidate(garagesProvider);
  }

  Future<void> remove(String id) async {
    await ref.read(supabaseServiceProvider).deleteGarage(id);
    ref.invalidate(garagesProvider);
    ref.invalidate(garageCountsProvider);
  }
}
