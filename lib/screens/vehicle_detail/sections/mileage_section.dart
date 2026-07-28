import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_text.dart';
import '../../../core/formatters.dart';
import '../../../core/theme.dart';
import '../../../models/mileage_log.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../services/prediction_service.dart';
import '../../../widgets/async_value_view.dart';
import '../update_km_sheet.dart';

/// "Km" section of the vehicle hub: a km-over-time chart plus a
/// chronological list of every reading, each marked "certifié" (backed by
/// an odometer photo) or "déclaratif" (manually typed).
class MileageSection extends ConsumerWidget {
  const MileageSection({super.key, required this.vehicleId});
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView(
      value: ref.watch(mileageLogsProvider(vehicleId)),
      onRetry: () => ref.invalidate(mileageLogsProvider(vehicleId)),
      data: (logs) => _Body(vehicleId: vehicleId, logs: logs),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.vehicleId, required this.logs});
  final String vehicleId;
  final List<MileageLog> logs;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (logs.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('Aucun relevé kilométrique enregistré.',
                style: TextStyle(color: p.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () => showUpdateKmSheet(context, vehicleId),
            icon: const Icon(Icons.speed, size: 20),
            label: const Text('Ajouter un relevé'),
          ),
        ],
      );
    }

    // Chronological (oldest -> newest) for the chart; `logs` itself stays
    // newest-first for the list below, matching the rest of the app.
    final chrono = List.of(logs)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final kmPerMonth = PredictionService.monthlyKmAverage(logs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                  value: Fmt.km(chrono.last.km), label: 'kilométrage actuel'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                  value: '+${kmPerMonth.round()} km', label: 'moyenne / mois'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (chrono.length >= 2) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.border),
            ),
            height: 200,
            child: _MileageChart(logs: chrono),
          ),
          const SizedBox(height: 20),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RELEVÉS', style: AppText.sectionLabel(p.textSecondary)),
            TextButton.icon(
              onPressed: () => showUpdateKmSheet(context, vehicleId),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Relevé'),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...logs.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LogTile(log: l),
            )),
      ],
    );
  }
}

class _MileageChart extends StatelessWidget {
  const _MileageChart({required this.logs});
  final List<MileageLog> logs; // chronological

  static final _epoch = DateTime(2000);

  double _x(DateTime d) => d.difference(_epoch).inDays.toDouble();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final spots =
        logs.map((l) => FlSpot(_x(l.recordedAt), l.km.toDouble())).toList();
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final yPad = (maxY - minY) * 0.1 + 1;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: (minY - yPad).clamp(0, double.infinity),
        maxY: maxY + yPad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((maxY - minY) / 3).clamp(1, double.infinity),
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
              reservedSize: 46,
              getTitlesWidget: (value, meta) => Text(
                '${(value / 1000).toStringAsFixed(0)}k',
                style: TextStyle(color: p.textMuted, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              // Only the two endpoints are meant to be labelled, but
              // fl_chart's interval-based tick generation can still emit
              // a stray tick a day off from the true edge (floating-point
              // step drift), which visually overlaps it — so the widget
              // itself drops anything that isn't within half a day of
              // meta.min/meta.max rather than trusting interval alone.
              interval: (maxX - minX <= 0 ? 1 : maxX - minX),
              getTitlesWidget: (value, meta) {
                final onEdge = (value - meta.min).abs() < 0.5 ||
                    (value - meta.max).abs() < 0.5;
                if (!onEdge) return const SizedBox.shrink();
                final date = _epoch.add(Duration(days: value.round()));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(Fmt.dateShort(date),
                      style: TextStyle(color: p.textMuted, fontSize: 9)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => p.surfaceElevated,
            getTooltipItems: (touchedSpots) => touchedSpots
                .map((s) => LineTooltipItem(
                      '${Fmt.km(s.y.round())}\n${Fmt.monthYear(_epoch.add(Duration(days: s.x.round())))}',
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
            color: p.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: p.primary,
                strokeWidth: 2,
                strokeColor: p.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: p.primary.withValues(alpha: .12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});
  final MileageLog log;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = log.isCertified ? p.ok : p.textSecondary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          if (log.photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(log.photoUrl!,
                  width: 44, height: 44, fit: BoxFit.cover),
            )
          else
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit_note, color: p.textMuted, size: 22),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Fmt.km(log.km),
                    style: AppText.odometer(p.textPrimary, size: 16)),
                const SizedBox(height: 2),
                Text(
                  [
                    Fmt.date(log.recordedAt),
                    if (log.note != null) log.note,
                  ].whereType<String>().join(' · '),
                  style: TextStyle(color: p.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(log.isCertified ? Icons.verified : Icons.edit_outlined,
                    size: 13, color: color),
                const SizedBox(width: 4),
                Text(log.isCertified ? 'Certifié' : 'Déclaratif',
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
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
