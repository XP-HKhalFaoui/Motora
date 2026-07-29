import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_text.dart';
import '../../../core/formatters.dart';
import '../../../core/theme.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/maintenance_provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../services/prediction_service.dart';
import '../../../widgets/document_card.dart';
import '../../../widgets/km_gauge.dart';
import '../../../widgets/maintenance_card.dart';
import '../../history/history_screen.dart';
import '../../reports/reports_screen.dart';
import '../update_km_sheet.dart';

/// "Aperçu" section of the vehicle hub: a digest that pulls the key signal
/// from every other tab — km gauge, cost/intervention stats, the next few
/// échéances and the soonest-expiring documents — with links that jump to
/// the relevant full-list section. [onOpenSection] switches the hub's
/// segmented control (1 = Entretien, 2 = Docs, 3 = Km).
class OverviewSection extends ConsumerWidget {
  const OverviewSection({
    super.key,
    required this.vehicleId,
    required this.onOpenSection,
  });

  final String vehicleId;
  final ValueChanged<int> onOpenSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictions =
        ref.watch(predictionsProvider(vehicleId)).value ?? const [];
    final history =
        ref.watch(maintenanceHistoryProvider(vehicleId)).value ?? const [];
    final docs = ref.watch(documentsProvider(vehicleId)).value ?? const [];

    final totalCost = history.fold<double>(0, (s, h) => s + (h.cost ?? 0));
    // The gauge tracks the worst *forecastable* échéance; a type awaiting
    // its last-intervention anchor has urgency 0 meaning "unknown", not
    // "fresh", so it must not drive the ring.
    final forecastable = predictions.where((pr) => !pr.needsSetup).toList();
    final topUrgency = forecastable.fold<double>(
        0, (max, pr) => pr.urgency > max ? pr.urgency : max);

    // The km/month average lives on the mileage logs, not on the
    // predictions — reading it off `predictions.first` showed "+0 km/mois"
    // for any vehicle with no maintenance type configured.
    final logs = ref.watch(mileageLogsProvider(vehicleId)).value ?? const [];
    final kmPerMonth = PredictionService.measuredMonthlyKmAverage(logs);

    final topPreds = predictions.take(3).toList();

    final sortedDocs = [...docs]
      ..sort((a, b) => a.daysToExpiry.compareTo(b.daysToExpiry));
    final topDocs = sortedDocs.take(2).toList();

    final vehicle = ref.watch(vehicleByIdProvider(vehicleId));
    final currentKm = vehicle?.currentKm ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: KmGauge(
            currentKm: currentKm,
            subtitle: kmPerMonth == null
                ? 'moyenne mensuelle à venir'
                : '+${kmPerMonth.round()} km / mois',
            progress: topUrgency.clamp(0.0, 1.0),
          ),
        ),
        const SizedBox(height: 22),
        ElevatedButton.icon(
          onPressed: () => showUpdateKmSheet(context, vehicleId),
          icon: const Icon(Icons.speed, size: 20),
          label: const Text('Mettre à jour le km'),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => onOpenSection(3),
              icon: const Icon(Icons.show_chart, size: 18),
              label: const Text('Historique km'),
            ),
            TextButton.icon(
              onPressed: () => onOpenSection(4),
              icon: const Icon(Icons.local_gas_station, size: 18),
              label: const Text('Carburant'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                  value: Fmt.money(totalCost), label: 'entretien total'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child:
                  _StatTile(value: '${history.length}', label: 'interventions'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => HistoryScreen(vehicleId: vehicleId)),
            ),
            icon: const Icon(Icons.history, size: 18),
            label: const Text("Voir l'historique"),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ReportsScreen(vehicleId: vehicleId)),
            ),
            icon: const Icon(Icons.query_stats, size: 18),
            label: const Text('Rapports'),
          ),
        ),
        const SizedBox(height: 8),
        _SectionHeader(
          label: 'PROCHAINES ÉCHÉANCES',
          onSeeAll: predictions.length > topPreds.length
              ? () => onOpenSection(1)
              : null,
        ),
        const SizedBox(height: 12),
        if (topPreds.isEmpty)
          _EmptyLine(
            text: 'Aucune échéance configurée.',
            actionLabel: 'Configurer',
            onAction: () => onOpenSection(1),
          )
        else
          ...topPreds.map((pr) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MaintenanceCard(
                  prediction: pr,
                  onTap: () => onOpenSection(1),
                ),
              )),
        const SizedBox(height: 18),
        _SectionHeader(
          label: 'DOCUMENTS',
          onSeeAll:
              docs.length > topDocs.length ? () => onOpenSection(2) : null,
        ),
        const SizedBox(height: 12),
        if (topDocs.isEmpty)
          _EmptyLine(
            text: 'Aucun document enregistré.',
            actionLabel: 'Ajouter',
            onAction: () => onOpenSection(2),
          )
        else
          ...topDocs.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DocumentCard(doc: d, onTap: () => onOpenSection(2)),
              )),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.onSeeAll});
  final String label;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.sectionLabel(p.textSecondary)),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text('Voir tout',
                style: TextStyle(
                    color: p.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: TextStyle(color: p.textMuted)),
          ),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
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
