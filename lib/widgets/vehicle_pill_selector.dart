import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/vehicle.dart';
import '../providers/ui_state_provider.dart';

/// Segmented vehicle switcher used at the top of Entretien and Documents
/// (screens 04/06 — "sélecteur segmenté par véhicule").
class VehiclePillSelector extends ConsumerWidget {
  const VehiclePillSelector({super.key, required this.vehicles});
  final List<Vehicle> vehicles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final selected = ref.watch(effectiveSelectedVehicleIdProvider);
    if (vehicles.length < 2) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: vehicles.map((v) {
          final active = v.id == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(selectedVehicleIdProvider.notifier).state = v.id,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? p.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  v.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : p.textSecondary,
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
