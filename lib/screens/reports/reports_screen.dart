import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_text.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/reports_service.dart';
import '../../widgets/async_value_view.dart';

/// "Rapports" — what the car actually costs.
///
/// Every figure here was already being collected and none of it was shown:
/// the app had two tiles (total spend, intervention count) for a ledger
/// holding fuel, interventions, expenses and every odometer reading.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key, required this.vehicleId});
  final String vehicleId;

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  var _period = ReportPeriod.last12Months;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final vehicle = ref.watch(vehicleByIdProvider(widget.vehicleId));
    final historyAsync =
        ref.watch(maintenanceHistoryProvider(widget.vehicleId));
    final logs =
        ref.watch(mileageLogsProvider(widget.vehicleId)).value ?? const [];

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        title: Text('Rapports · ${vehicle?.name ?? ''}',
            overflow: TextOverflow.ellipsis,
            style: AppText.screenTitle(p.textPrimary, size: 18)),
      ),
      body: AsyncValueView(
        value: historyAsync,
        onRetry: () =>
            ref.invalidate(maintenanceHistoryProvider(widget.vehicleId)),
        data: (history) {
          final report = ReportsService.build(
            history: history,
            logs: logs,
            period: _period,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              _PeriodPicker(
                period: _period,
                onChanged: (v) => setState(() => _period = v),
              ),
              const SizedBox(height: 18),
              if (report.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: EmptyState(
                    icon: Icons.query_stats,
                    message: 'Rien à analyser sur cette période.',
                  ),
                )
              else ...[
                _Summary(report: report),
                const SizedBox(height: 20),
                _Breakdown(report: report),
                if (report.monthly.length >= 2) ...[
                  const SizedBox(height: 20),
                  Text('DÉPENSES MENSUELLES',
                      style: AppText.sectionLabel(p.textSecondary)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
                    height: 240,
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: p.border),
                    ),
                    child: _MonthlyChart(months: report.monthly),
                  ),
                  const SizedBox(height: 10),
                  const _Legend(),
                ],
                if (report.averageConsumption != null) ...[
                  const SizedBox(height: 20),
                  _Consumption(report: report),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.period, required this.onChanged});
  final ReportPeriod period;
  final ValueChanged<ReportPeriod> onChanged;

  static const _labels = {
    ReportPeriod.last3Months: '3 mois',
    ReportPeriod.last12Months: '12 mois',
    ReportPeriod.thisYear: 'Cette année',
    ReportPeriod.all: 'Tout',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in _labels.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Semantics(
                button: true,
                selected: entry.key == period,
                label: entry.value,
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => onChanged(entry.key),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: entry.key == period ? p.primary : p.surface,
                      border: Border.all(
                          color: entry.key == period ? p.primary : p.border),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(entry.value,
                        style: TextStyle(
                          color: entry.key == period
                              ? p.onPrimary
                              : p.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.report});
  final VehicleReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(
            child: _Card(
              title: 'Coût',
              value: Fmt.money(report.totals.total),
              rows: [
                ('par jour', Fmt.money(report.costPerDay)),
                ('par km', Fmt.money(report.costPerKm)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Card(
              title: 'Distance',
              value: Fmt.km(report.distanceKm),
              rows: [
                (
                  'par jour',
                  report.days > 0 && report.distanceKm > 0
                      ? Fmt.km((report.distanceKm / report.days).round())
                      : '—'
                ),
                ('entrées', '${report.entryCount}'),
              ],
            ),
          ),
        ]),
      ],
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.report});
  final VehicleReport report;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = report.totals;
    final entries = [
      ('Carburant', t.fuel, p.warn),
      ('Entretien', t.maintenance, p.primary),
      ('Dépenses', t.expense, p.danger),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          for (final (label, amount, color) in entries) ...[
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: TextStyle(color: p.textSecondary, fontSize: 13.5)),
                ),
                Text(
                  t.total > 0 ? '${(amount / t.total * 100).round()} %' : '—',
                  style: TextStyle(color: p.textMuted, fontSize: 12),
                ),
                const SizedBox(width: 12),
                Text(Fmt.money(amount),
                    style: AppText.odometer(p.textPrimary, size: 14)),
              ],
            ),
            if (label != 'Dépenses') const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.months});
  final List<MonthlyTotals> months;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final maxY =
        months.map((m) => m.totals.total).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxY * 1.15 + 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 3).clamp(1, double.infinity),
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
              reservedSize: 42,
              getTitlesWidget: (value, meta) => Text(
                value >= 1000
                    ? '${(value / 1000).toStringAsFixed(0)}k'
                    : value.toStringAsFixed(0),
                style: TextStyle(color: p.textMuted, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= months.length) return const SizedBox.shrink();
                // With a year of bars there is no room for every label;
                // show one in three, always including the last.
                final step = (months.length / 4).ceil().clamp(1, 12);
                if (i != months.length - 1 && i % step != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(Fmt.monthShort(months[i].month),
                      style: TextStyle(color: p.textMuted, fontSize: 9)),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => p.surfaceElevated,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final m = months[group.x];
              return BarTooltipItem(
                '${Fmt.monthYear(m.month)}\n${Fmt.money(m.totals.total)}',
                TextStyle(
                    color: p.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < months.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: months[i].totals.total,
                  width: 14,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                  // Stacked in the same order as the breakdown above.
                  rodStackItems: [
                    BarChartRodStackItem(0, months[i].totals.fuel, p.warn),
                    BarChartRodStackItem(
                        months[i].totals.fuel,
                        months[i].totals.fuel + months[i].totals.maintenance,
                        p.primary),
                    BarChartRodStackItem(
                        months[i].totals.fuel + months[i].totals.maintenance,
                        months[i].totals.total,
                        p.danger),
                  ],
                  color: p.border,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final items = [
      ('Carburant', p.warn),
      ('Entretien', p.primary),
      ('Dépenses', p.danger),
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        for (final (label, color) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(color: p.textSecondary, fontSize: 12)),
            ],
          ),
      ],
    );
  }
}

class _Consumption extends StatelessWidget {
  const _Consumption({required this.report});
  final VehicleReport report;

  String _l(double? v) => v == null ? '—' : '${v.toStringAsFixed(1)} L/100';

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Consommation',
      value: _l(report.averageConsumption),
      rows: [
        ('meilleure', _l(report.bestConsumption)),
        ('pire', _l(report.worstConsumption)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.value,
    required this.rows,
  });

  final String title;
  final String value;
  final List<(String, String)> rows;

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
          Text(title, style: AppText.sectionLabel(p.textSecondary)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: AppText.screenTitle(p.textPrimary, size: 20)),
          ),
          const SizedBox(height: 10),
          Divider(color: p.border, height: 1),
          const SizedBox(height: 8),
          for (final (label, v) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: TextStyle(color: p.textMuted, fontSize: 11.5)),
                  Text(v,
                      style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
