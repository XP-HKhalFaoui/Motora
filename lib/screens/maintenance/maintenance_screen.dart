import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_text.dart';
import '../../core/theme.dart';
import '../../models/maintenance_prediction.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/maintenance_card.dart';
import '../../widgets/vehicle_pill_selector.dart';
import 'add_maintenance_type_sheet.dart';

/// Entretien / Pièces (screen 04): vehicle selector, 3 status counters,
/// list of maintenance types with progress + colored left border.
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final vehicles = ref.watch(vehiclesProvider).value ?? const [];
    final vehicleId = ref.watch(effectiveSelectedVehicleIdProvider);

    return Container(
      color: p.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
          children: [
            Text('Entretien', style: AppText.screenTitle(p.textPrimary)),
            const SizedBox(height: 16),
            VehiclePillSelector(vehicles: vehicles),
            if (vehicleId == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('Ajoutez un véhicule pour commencer.',
                      style: TextStyle(color: p.textMuted)),
                ),
              )
            else
              AsyncValueView(
                value: ref.watch(predictionsProvider(vehicleId)),
                data: (predictions) =>
                    _Body(vehicleId: vehicleId, predictions: predictions),
              ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.vehicleId, required this.predictions});
  final String vehicleId;
  final List<MaintenancePrediction> predictions;

  @override
  Widget build(BuildContext context) {
    final urgent = predictions.where((p) => p.urgency >= 0.85).length;
    final watch =
        predictions.where((p) => p.urgency >= 0.6 && p.urgency < 0.85).length;
    final ok = predictions.where((p) => p.urgency < 0.6).length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _CountTile(
                    count: urgent,
                    label: 'urgent',
                    color: context.palette.danger)),
            const SizedBox(width: 8),
            Expanded(
                child: _CountTile(
                    count: watch,
                    label: 'à surveiller',
                    color: context.palette.warn)),
            const SizedBox(width: 8),
            Expanded(
                child: _CountTile(
                    count: ok, label: 'OK', color: context.palette.ok)),
          ],
        ),
        const SizedBox(height: 18),
        if (predictions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Text(
              "Aucun type d'entretien configuré pour ce véhicule.",
              style: TextStyle(color: context.palette.textMuted),
            ),
          )
        else
          ...predictions.map((pr) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MaintenanceCard(
                  prediction: pr,
                  onTap: () => showAddMaintenanceTypeSheet(context, vehicleId,
                      existing: pr.type),
                ),
              )),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () => showAddMaintenanceTypeSheet(context, vehicleId),
          icon: Icon(Icons.add_circle_outline,
              color: context.palette.textSecondary),
          label: const Text("Ajouter un type d'entretien"),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
                color: context.palette.border,
                style: BorderStyle.solid,
                width: 1.5),
          ),
        ),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile(
      {required this.count, required this.label, required this.color});
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        border: Border.all(color: color.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text('$count', style: AppText.screenTitle(color, size: 20)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
