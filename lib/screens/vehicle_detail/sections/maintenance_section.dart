import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_text.dart';
import '../../../core/theme.dart';
import '../../../models/maintenance_prediction.dart';
import '../../../providers/maintenance_provider.dart';
import '../../../widgets/async_value_view.dart';
import '../../../widgets/maintenance_card.dart';
import '../../maintenance/add_maintenance_type_sheet.dart';
import '../../quick_add/add_history_sheet.dart';

/// "Entretien" section of the vehicle hub: 3 status counters + the list of
/// maintenance types with progress, plus an "add type" action. Scoped to a
/// single [vehicleId] (the hub already picks the car, so there is no pill
/// selector here anymore).
class MaintenanceSection extends ConsumerWidget {
  const MaintenanceSection({super.key, required this.vehicleId});
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView(
      value: ref.watch(predictionsProvider(vehicleId)),
      data: (predictions) =>
          _Body(vehicleId: vehicleId, predictions: predictions),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.vehicleId, required this.predictions});
  final String vehicleId;
  final List<MaintenancePrediction> predictions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final urgent = predictions.where((p) => p.urgency >= 0.85).length;
    final watch =
        predictions.where((p) => p.urgency >= 0.6 && p.urgency < 0.85).length;
    final ok = predictions.where((p) => p.urgency < 0.6).length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _CountTile(count: urgent, label: 'urgent', color: p.danger)),
            const SizedBox(width: 8),
            Expanded(
                child: _CountTile(
                    count: watch, label: 'à surveiller', color: p.warn)),
            const SizedBox(width: 8),
            Expanded(child: _CountTile(count: ok, label: 'OK', color: p.ok)),
          ],
        ),
        const SizedBox(height: 18),
        if (predictions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Text(
              "Aucun type d'entretien configuré pour ce véhicule.",
              style: TextStyle(color: p.textMuted),
            ),
          )
        else
          ...predictions.map((pr) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MaintenanceCard(
                  prediction: pr,
                  onTap: () => showAddMaintenanceTypeSheet(context, vehicleId,
                      existing: pr.type),
                  onMarkDone: () => _markDone(context, ref, pr),
                ),
              )),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () => showAddMaintenanceTypeSheet(context, vehicleId),
          icon: Icon(Icons.add_circle_outline, color: p.textSecondary),
          label: const Text("Ajouter un type d'entretien"),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: p.border, width: 1.5),
          ),
        ),
      ],
    );
  }

  /// Validating an échéance opens the intervention form pre-linked to this
  /// type (title + current km prefilled), so the user confirms the date, km
  /// and the garage that did the work before it's saved to history. Saving
  /// records the intervention and resets the échéance (the linked type's
  /// "last done" markers are advanced by the controller on insert).
  void _markDone(
      BuildContext context, WidgetRef ref, MaintenancePrediction pr) {
    showAddHistorySheet(
      context,
      vehicleId,
      defaultTitle: pr.type.label,
      defaultMaintenanceTypeId: pr.type.id,
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
