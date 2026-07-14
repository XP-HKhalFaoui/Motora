import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_text.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/km_gauge.dart';
import '../../widgets/maintenance_card.dart';
import '../history/history_screen.dart';
import '../home/vehicle_form_screen.dart';
import '../maintenance/add_maintenance_type_sheet.dart';
import 'update_km_sheet.dart';

/// Détail véhicule (screen 03): header, km gauge + update button, 2 stat
/// tiles, "Prochaines échéances" list.
class VehicleDetailScreen extends ConsumerWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final vehicle = ref.watch(vehicleByIdProvider(vehicleId));
    final predictionsAsync = ref.watch(predictionsProvider(vehicleId));
    final historyAsync = ref.watch(maintenanceHistoryProvider(vehicleId));

    final totalCost = (historyAsync.value ?? const [])
        .fold<double>(0, (sum, h) => sum + (h.cost ?? 0));
    final interventionCount = historyAsync.value?.length ?? 0;

    final predictions = predictionsAsync.value ?? const [];
    final topUrgency = predictions.fold<double>(
        0, (max, pr) => pr.urgency > max ? pr.urgency : max);
    final kmPerMonth = predictions.isEmpty ? 0.0 : predictions.first.kmPerMonth;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: vehicle == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: p.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vehicle.name,
                                style: AppText.screenTitle(p.textPrimary,
                                    size: 20)),
                            Text(
                              [
                                if (vehicle.brand != null) vehicle.brand,
                                if (vehicle.year != null)
                                  vehicle.year.toString(),
                                if (vehicle.plateNumber != null)
                                  vehicle.plateNumber,
                              ].whereType<String>().join(' · '),
                              style: TextStyle(
                                  color: p.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: p.textSecondary),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  VehicleFormScreen(existing: vehicle)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Column(
                      children: [
                        KmGauge(
                          currentKm: vehicle.currentKm,
                          subtitle: '+${kmPerMonth.round()} km / mois',
                          progress: topUrgency == 0 ? 0.62 : topUrgency,
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton.icon(
                          onPressed: () =>
                              showUpdateKmSheet(context, vehicleId),
                          icon: const Icon(Icons.speed, size: 20),
                          label: const Text('Mettre à jour le km'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                            value: Fmt.money(totalCost),
                            label: 'entretien total'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                            value: '$interventionCount',
                            label: 'interventions'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                HistoryScreen(vehicleId: vehicleId)),
                      ),
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('Voir l\'historique'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('PROCHAINES ÉCHÉANCES',
                      style: AppText.sectionLabel(p.textSecondary)),
                  const SizedBox(height: 12),
                  AsyncValueView(
                    value: predictionsAsync,
                    data: (preds) {
                      if (preds.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "Aucune échéance configurée pour ce véhicule.",
                            style: TextStyle(color: p.textMuted),
                          ),
                        );
                      }
                      return Column(
                        children: preds
                            .map((pr) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: MaintenanceCard(
                                    prediction: pr,
                                    onTap: () => showAddMaintenanceTypeSheet(
                                        context, vehicleId,
                                        existing: pr.type),
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.screenTitle(p.textPrimary, size: 20)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: p.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
