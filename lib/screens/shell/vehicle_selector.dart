import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/vehicle.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../home/vehicle_form_screen.dart';

/// The vehicle chip in the app bar — the single place the current vehicle
/// is chosen, now that there is no per-vehicle hub to imply it.
///
/// It is also the only writer of [selectedVehicleIdProvider]. That used to
/// be the hub's initState; without a replacement the provider would sit at
/// null forever and everything downstream would silently fall back to the
/// first vehicle.
class VehicleSelector extends ConsumerWidget {
  const VehicleSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final vehicles = ref.watch(vehiclesProvider).value ?? const <Vehicle>[];
    final currentId = ref.watch(effectiveSelectedVehicleIdProvider);
    final current = vehicles.where((v) => v.id == currentId).firstOrNull;

    if (current == null) {
      return Text('Motora', style: AppTextWordmark.of(context));
    }

    return Semantics(
      button: true,
      label: 'Véhicule ${current.name}, changer de véhicule',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () => _pick(context, ref, vehicles, current),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_car_rounded, size: 18, color: p.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  current.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (vehicles.length > 1) ...[
                const SizedBox(width: 2),
                Icon(Icons.expand_more, size: 20, color: p.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    List<Vehicle> vehicles,
    Vehicle current,
  ) async {
    final p = context.palette;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final v in vehicles)
              ListTile(
                leading: Icon(
                  Icons.directions_car_rounded,
                  color: v.id == current.id ? p.primary : p.textMuted,
                ),
                title: Text(v.name,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontWeight: v.id == current.id
                          ? FontWeight.w700
                          : FontWeight.w500,
                    )),
                subtitle: Text(Fmt.km(v.currentKm),
                    style: TextStyle(color: p.textSecondary)),
                trailing: v.id == current.id
                    ? Icon(Icons.check, color: p.primary)
                    : null,
                onTap: () {
                  ref.read(selectedVehicleIdProvider.notifier).state = v.id;
                  Navigator.pop(sheetContext);
                },
              ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: p.primary),
              title: Text('Ajouter un véhicule',
                  style: TextStyle(color: p.primary)),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Small indirection so the wordmark style lives in one place.
class AppTextWordmark {
  static TextStyle of(BuildContext context) => TextStyle(
        color: context.palette.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      );
}
