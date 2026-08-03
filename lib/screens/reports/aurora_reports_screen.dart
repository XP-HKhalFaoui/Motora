import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/aurora_theme.dart';
import '../../core/formatters.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/prediction_service.dart';
import '../../services/reports_service.dart';
import '../../widgets/aurora/aurora_animate_once.dart';
import '../../widgets/aurora/aurora_empty_state.dart';

/// Reports — "Rapports". Cost and consumption over a selectable period.
/// Body-only, same integration model as the other Aurora tabs.
class AuroraReportsScreen extends ConsumerStatefulWidget {
  const AuroraReportsScreen({super.key, required this.vehicleId});
  final String vehicleId;

  @override
  ConsumerState<AuroraReportsScreen> createState() => _AuroraReportsScreenState();
}

class _AuroraReportsScreenState extends ConsumerState<AuroraReportsScreen> {
  var _period = ReportPeriod.last12Months;

  static const _periodLabels = {
    ReportPeriod.last3Months: '3 mois',
    ReportPeriod.last12Months: '12 mois',
    ReportPeriod.thisYear: 'Cette année',
    ReportPeriod.all: 'Tout',
  };

  Future<void> _pickPeriod() async {
    final picked = await showModalBottomSheet<ReportPeriod>(
      context: context,
      backgroundColor: AuroraColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AuroraRadii.largeCard)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final entry in _periodLabels.entries)
              ListTile(
                title: Text(entry.value, style: AuroraText.listRowTitle(AuroraColors.ink)),
                trailing: entry.key == _period
                    ? const Icon(PhosphorIconsFill.arrowRight, color: AuroraColors.accent, size: 18)
                    : null,
                onTap: () => Navigator.pop(sheetContext, entry.key),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _period = picked);
  }

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    final vehicle = ref.watch(vehicleByIdProvider(widget.vehicleId));
    final history = ref.watch(maintenanceHistoryProvider(widget.vehicleId)).value ?? const [];
    final logs = ref.watch(mileageLogsProvider(widget.vehicleId)).value ?? const [];
    final report = ReportsService.build(history: history, logs: logs, period: _period);
    final kmPerMonth = PredictionService.measuredMonthlyKmAverage(logs);

    final cutoff = ReportsService.startOf(_period, DateTime.now());
    final mileagePoints = [
      for (final l in logs)
        if (cutoff == null || !l.recordedAt.isBefore(cutoff)) l,
    ]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AuroraSpacing.screenPaddingH, 12, AuroraSpacing.screenPaddingH, AuroraSpacing.bottomNavClearance),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rapports', style: AuroraText.screenTitle(aurora.textPrimary)),
            _PeriodPill(label: _periodLabels[_period]!, onTap: _pickPeriod),
          ],
        ),
        const SizedBox(height: AuroraSpacing.blockGap),
        _MileageCard(
          currentKm: vehicle?.currentKm ?? 0,
          kmPerMonth: kmPerMonth,
          points: mileagePoints.map((l) => l.km.toDouble()).toList(),
          firstLabel: mileagePoints.isEmpty ? null : Fmt.dayMonth(mileagePoints.first.recordedAt),
          lastLabel: mileagePoints.isEmpty ? null : Fmt.dayMonth(mileagePoints.last.recordedAt),
        ),
        const SizedBox(height: AuroraSpacing.blockGap),
        if (report.isEmpty)
          AuroraEmptyState(
            title: 'Rien à analyser',
            message: 'Aucune donnée sur cette période.',
            actionLabel: _period == ReportPeriod.all ? null : 'Voir tout',
            onAction: _period == ReportPeriod.all
                ? null
                : () => setState(() => _period = ReportPeriod.all),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _KpiTile(
                  label: 'Dépense / mois',
                  value: Fmt.money(report.totals.total / (report.monthly.isEmpty ? 1 : report.monthly.length)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiTile(
                  label: 'Conso. moyenne',
                  value: report.averageConsumption == null
                      ? '—'
                      : '${report.averageConsumption!.toStringAsFixed(1)} L/100',
                ),
              ),
            ],
          ),
          const SizedBox(height: AuroraSpacing.blockGap),
          if (report.monthly.length >= 2) ...[
            _MonthlyBarsCard(monthly: report.monthly),
            const SizedBox(height: AuroraSpacing.blockGap),
          ],
          _BreakdownCard(totals: report.totals),
        ],
      ],
    );
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AuroraRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: aurora.card,
          borderRadius: BorderRadius.circular(AuroraRadii.pill),
          boxShadow: aurora.useCardShadows ? AuroraShadows.cardSoft : null,
          border: aurora.useCardShadows ? null : Border.all(color: AuroraColors.darkHairlineBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(color: AuroraColors.ink, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(PhosphorIconsRegular.caretDown, size: 14, color: AuroraColors.iconMutedOnWhite),
          ],
        ),
      ),
    );
  }
}

class _MileageCard extends StatelessWidget {
  const _MileageCard({
    required this.currentKm,
    required this.kmPerMonth,
    required this.points,
    required this.firstLabel,
    required this.lastLabel,
  });

  final int currentKm;
  final double? kmPerMonth;
  final List<double> points;
  final String? firstLabel;
  final String? lastLabel;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return Container(
      padding: const EdgeInsets.all(AuroraSpacing.cardPaddingLarge),
      decoration: BoxDecoration(
        color: aurora.card,
        borderRadius: BorderRadius.circular(AuroraRadii.largeCard),
        boxShadow: aurora.useCardShadows ? AuroraShadows.cardRaised : null,
        border: aurora.useCardShadows ? null : Border.all(color: AuroraColors.darkHairlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kilométrage', style: AuroraText.meta(aurora.muted)),
                    const SizedBox(height: 4),
                    // See the Ledger totals card for why this is a
                    // FittedBox: a high-mileage vehicle squeezed against
                    // the trend pill otherwise wraps the number.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(Fmt.km(currentKm).replaceAll(' km', ''),
                          style: AuroraText.heroMetric(aurora.textPrimary)),
                    ),
                  ],
                ),
              ),
              if (kmPerMonth != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AuroraColors.accentTint14,
                    borderRadius: BorderRadius.circular(AuroraRadii.pill),
                  ),
                  child: Text('+${kmPerMonth!.round()} / mois',
                      style: const TextStyle(
                          color: AuroraColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (points.length < 2)
            SizedBox(
              height: 78,
              child: Center(
                child: Text('Pas assez de relevés pour un historique.',
                    style: AuroraText.meta(aurora.muted)),
              ),
            )
          else ...[
            SizedBox(height: 78, child: _MileageChart(points: points)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(firstLabel ?? '', style: AuroraText.axisLabel(AuroraColors.mutedSoft)),
                Text(lastLabel ?? '', style: AuroraText.axisLabel(AuroraColors.mutedSoft)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MileageChart extends StatelessWidget {
  const _MileageChart({required this.points});
  final List<double> points;

  @override
  Widget build(BuildContext context) {
    final minY = points.reduce((a, b) => a < b ? a : b);
    final maxY = points.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).clamp(1, double.infinity) * .1;

    // Draws left-to-right over 600ms on first appearance only, per spec:
    // reveal only the spots up to the animated x-extent, interpolating a
    // partial final segment so the line grows smoothly rather than
    // jumping from point to point.
    return AuroraAnimateOnce(
      duration: const Duration(milliseconds: 600),
      builder: (context, factor) {
        final visibleExtent = factor * (points.length - 1);
        final spots = <FlSpot>[];
        for (var i = 0; i < points.length; i++) {
          if (i <= visibleExtent) {
            spots.add(FlSpot(i.toDouble(), points[i]));
          } else {
            final prev = points[i - 1];
            final frac = (visibleExtent - (i - 1)).clamp(0.0, 1.0);
            spots.add(FlSpot(visibleExtent, prev + (points[i] - prev) * frac));
            break;
          }
        }

        return LineChart(
          LineChartData(
            minX: 0,
            maxX: (points.length - 1).toDouble(),
            minY: minY - pad,
            maxY: maxY + pad,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AuroraColors.accent,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, _) => spot.x == spots.last.x,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(radius: 4, color: AuroraColors.accent, strokeWidth: 0),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AuroraColors.accent.withValues(alpha: .34),
                      AuroraColors.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: aurora.card,
        borderRadius: BorderRadius.circular(AuroraRadii.smallCard),
        boxShadow: aurora.useCardShadows ? AuroraShadows.cardSoft : null,
        border: aurora.useCardShadows ? null : Border.all(color: AuroraColors.darkHairlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AuroraText.meta(aurora.muted)),
          const SizedBox(height: 6),
          // Same wrapping risk as the other hero-style values on this
          // screen — a monthly-average DA amount is wide enough at 19px
          // to wrap inside half the screen's width.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AuroraText.tabularValue(aurora.textPrimary, size: 19)),
          ),
        ],
      ),
    );
  }
}

class _MonthlyBarsCard extends StatefulWidget {
  const _MonthlyBarsCard({required this.monthly});
  final List<MonthlyTotals> monthly;

  @override
  State<_MonthlyBarsCard> createState() => _MonthlyBarsCardState();
}

class _MonthlyBarsCardState extends State<_MonthlyBarsCard> with SingleTickerProviderStateMixin {
  static const _growthMs = 350;
  static const _staggerMs = 40;

  late final int _totalMs = _growthMs + (widget.monthly.length - 1) * _staggerMs;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _totalMs),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Each bar grows on its own [_growthMs] window, starting [_staggerMs]
  /// later than the previous one — the spec's "bars grow bottom-up, 40ms
  /// staggered", on first appearance only.
  Animation<double> _barFactor(int index) {
    final start = index * _staggerMs / _totalMs;
    final end = (index * _staggerMs + _growthMs) / _totalMs;
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end.clamp(start, 1.0), curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    final monthly = widget.monthly;
    final now = DateTime.now();
    final currentKey = DateTime(now.year, now.month);
    final maxY = monthly.map((m) => m.totals.total).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AuroraSpacing.cardPaddingLarge),
      decoration: BoxDecoration(
        color: aurora.card,
        borderRadius: BorderRadius.circular(AuroraRadii.largeCard),
        boxShadow: aurora.useCardShadows ? AuroraShadows.cardSoft : null,
        border: aurora.useCardShadows ? null : Border.all(color: AuroraColors.darkHairlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DÉPENSES MENSUELLES', style: AuroraText.sectionLabel(aurora.textPrimary, size: 13)),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < monthly.length; i++) ...[
                  if (i > 0) const SizedBox(width: 7),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final target =
                            maxY <= 0 ? 0.02 : (monthly[i].totals.total / maxY).clamp(.02, 1.0);
                        return FractionallySizedBox(
                          heightFactor: target * _barFactor(i).value,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: monthly[i].month == currentKey
                                  ? AuroraColors.accent
                                  : AuroraColors.accentTint22,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Fmt.monthShort(monthly.first.month), style: AuroraText.axisLabel(AuroraColors.mutedSoft)),
              if (monthly.length > 2)
                Text(Fmt.monthShort(monthly[monthly.length ~/ 2].month),
                    style: AuroraText.axisLabel(AuroraColors.mutedSoft)),
              Text(Fmt.monthShort(monthly.last.month), style: AuroraText.axisLabel(AuroraColors.mutedSoft)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.totals});
  final CategoryTotals totals;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    // The spec's 4-stop accent ladder (accent, tint55, tint32, tint16) was
    // drawn for up to 4 categories; Motora's ledger only ever has 3
    // (fuel/maintenance/expense), so the 4th stop is unused here.
    final items = [
      ('Carburant', totals.fuel, AuroraColors.accent),
      ('Entretien', totals.maintenance, AuroraColors.accentTint55),
      ('Dépenses', totals.expense, AuroraColors.accentTint32),
    ];

    return Container(
      padding: const EdgeInsets.all(AuroraSpacing.cardPaddingLarge),
      decoration: BoxDecoration(
        color: aurora.card,
        borderRadius: BorderRadius.circular(AuroraRadii.largeCard),
        boxShadow: aurora.useCardShadows ? AuroraShadows.cardSoft : null,
        border: aurora.useCardShadows ? null : Border.all(color: AuroraColors.darkHairlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RÉPARTITION', style: AuroraText.sectionLabel(aurora.textPrimary, size: 13)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: totals.total > 0 ? (items[i].$2 * 1000 / totals.total).round().clamp(1, 1000) : 1,
                      child: ColoredBox(color: items[i].$3),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Sized to each item's own content rather than forced into two
          // equal Expanded halves — a fixed 50/50 split truncated
          // "Entretien"/"Carburant" against a wide DA amount on real
          // devices. This still reads as ~2 columns on a normal phone
          // width; it just doesn't truncate when it can't.
          Wrap(
            spacing: 14,
            runSpacing: 9,
            children: [for (final item in items) _LegendItem(item)],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(this.item);
  final (String, double, Color) item;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    final (label, amount, color) = item;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Text(label, style: AuroraText.meta(aurora.textPrimary, size: 12)),
        const SizedBox(width: 6),
        Text(Fmt.money(amount), style: AuroraText.tabularValue(aurora.textPrimary, size: 12)),
      ],
    );
  }
}
