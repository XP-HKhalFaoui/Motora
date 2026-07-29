import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_text.dart';
import '../../../core/formatters.dart';
import '../../../core/theme.dart';
import '../../../models/maintenance_history.dart';
import '../../../providers/maintenance_provider.dart';
import '../../../services/fuel_service.dart';
import '../../../widgets/async_value_view.dart';
import '../../quick_add/add_history_sheet.dart';

/// "Carburant" section of the vehicle hub.
///
/// The L/100km maths already existed but only ever surfaced as a small chip
/// buried in the history timeline; this gathers the aggregates — average
/// consumption, cost per km, litres and spend — plus a consumption curve.
class FuelSection extends ConsumerWidget {
  const FuelSection({super.key, required this.vehicleId});
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView(
      value: ref.watch(maintenanceHistoryProvider(vehicleId)),
      onRetry: () => ref.invalidate(maintenanceHistoryProvider(vehicleId)),
      data: (history) => _Body(vehicleId: vehicleId, history: history),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.vehicleId, required this.history});
  final String vehicleId;
  final List<MaintenanceHistory> history;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final stats = FuelService.analyze(history);

    if (stats.fillUps == 0) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('Aucun plein enregistré.',
                style: TextStyle(color: p.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () => showAddHistorySheet(context, vehicleId,
                defaultTitle: 'Plein / carburant', isFuel: true),
            icon: const Icon(Icons.local_gas_station, size: 20),
            label: const Text('Ajouter un plein'),
          ),
        ],
      );
    }

    // Chronological, and only the entries that actually carry a measured
    // consumption — a partial fill has none by construction.
    final measured = history
        .where((h) => stats.consumptionByEntryId.containsKey(h.id))
        .toList()
      ..sort((a, b) => a.km!.compareTo(b.km!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                value: stats.averageConsumption == null
                    ? '—'
                    : '${stats.averageConsumption!.toStringAsFixed(1)} L',
                label: 'moyenne / 100 km',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                value:
                    stats.costPerKm == null ? '—' : Fmt.money(stats.costPerKm),
                label: 'coût / km',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                value: '${stats.totalLiters.toStringAsFixed(0)} L',
                label:
                    stats.fillUps == 1 ? '1 plein' : '${stats.fillUps} pleins',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                value: Fmt.money(stats.totalCost),
                label: 'total carburant',
              ),
            ),
          ],
        ),
        if (stats.averageConsumption == null) ...[
          const SizedBox(height: 14),
          const _Hint(
            text: 'Enregistrez deux pleins complets avec le kilométrage '
                'pour obtenir une consommation.',
          ),
        ],
        if (measured.length >= 2) ...[
          const SizedBox(height: 20),
          Text('CONSOMMATION', style: AppText.sectionLabel(p.textSecondary)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.border),
            ),
            height: 200,
            child: _ConsumptionChart(
              entries: measured,
              consumption: stats.consumptionByEntryId,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PLEINS', style: AppText.sectionLabel(p.textSecondary)),
            TextButton.icon(
              onPressed: () => showAddHistorySheet(context, vehicleId,
                  defaultTitle: 'Plein / carburant', isFuel: true),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Plein'),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...history.where((h) => h.isFuel).map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FillUpTile(
                vehicleId: vehicleId,
                entry: h,
                consumption: stats.consumptionByEntryId[h.id],
              ),
            )),
      ],
    );
  }
}

class _ConsumptionChart extends StatelessWidget {
  const _ConsumptionChart({required this.entries, required this.consumption});

  final List<MaintenanceHistory> entries; // ordered by km
  final Map<String, double> consumption;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final spots = entries
        .map((e) => FlSpot(e.km!.toDouble(), consumption[e.id]!))
        .toList();
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final yPad = (maxY - minY) * 0.15 + 0.5;

    return LineChart(
      LineChartData(
        minX: spots.first.x,
        maxX: spots.last.x,
        minY: (minY - yPad).clamp(0, double.infinity),
        maxY: maxY + yPad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((maxY - minY) / 3).clamp(0.5, double.infinity),
          getDrawingHorizontalLine: (_) =>
              FlLine(color: p.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style: TextStyle(color: p.textMuted, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              // Endpoints only; see the same workaround in MileageSection —
              // fl_chart's interval ticks drift off the true edge.
              interval:
                  (spots.last.x - spots.first.x).clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final onEdge = (value - meta.min).abs() < 1 ||
                    (value - meta.max).abs() < 1;
                if (!onEdge) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${(value / 1000).toStringAsFixed(0)}k',
                      style: TextStyle(color: p.textMuted, fontSize: 9)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => p.surfaceElevated,
            getTooltipItems: (touched) => touched
                .map((s) => LineTooltipItem(
                      '${s.y.toStringAsFixed(1)} L/100km\n${Fmt.km(s.x.round())}',
                      TextStyle(
                          color: p.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: p.warn,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: p.warn,
                strokeWidth: 2,
                strokeColor: p.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: p.warn.withValues(alpha: .12),
            ),
          ),
        ],
      ),
    );
  }
}

class _FillUpTile extends StatelessWidget {
  const _FillUpTile({
    required this.vehicleId,
    required this.entry,
    this.consumption,
  });

  final String vehicleId;
  final MaintenanceHistory entry;
  final double? consumption;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showAddHistorySheet(context, vehicleId, existing: entry),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: p.border)),
          child: Row(
            children: [
              Icon(Icons.local_gas_station, size: 20, color: p.warn),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        if (entry.liters != null)
                          '${entry.liters!.toStringAsFixed(1)} L',
                        if (entry.km != null) Fmt.km(entry.km),
                      ].join(' · '),
                      style: AppText.odometer(p.textPrimary, size: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        Fmt.date(entry.doneAt),
                        if (!entry.isFullTank) 'plein partiel',
                        if (entry.garageName != null) entry.garageName!,
                      ].join(' · '),
                      style: TextStyle(color: p.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (entry.cost != null)
                    Text(Fmt.money(entry.cost),
                        style: AppText.odometer(p.primary, size: 14)),
                  if (consumption != null) ...[
                    const SizedBox(height: 2),
                    Text('${consumption!.toStringAsFixed(1)} L/100',
                        style: TextStyle(
                            color: p.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: p.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(color: p.textSecondary, fontSize: 12.5)),
          ),
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
