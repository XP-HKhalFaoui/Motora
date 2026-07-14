import 'package:flutter/material.dart';

import '../core/app_text.dart';
import '../core/formatters.dart';
import '../core/maintenance_icons.dart';
import '../core/theme.dart';
import '../models/maintenance_prediction.dart';
import '../models/maintenance_type.dart';

/// A maintenance type row: 3px colored left border, progress bar and the
/// km/date forecast — screens 03/04 ("bordure gauche colorée de 3px").
class MaintenanceCard extends StatelessWidget {
  const MaintenanceCard({
    super.key,
    required this.prediction,
    this.onTap,
    this.onMarkDone,
  });

  final MaintenancePrediction prediction;
  final VoidCallback? onTap;
  final VoidCallback? onMarkDone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = statusColorFor(p, prediction.urgency);

    // BoxDecoration can't combine borderRadius with a Border whose sides
    // have different colors (the left accent vs. the neutral p.border on
    // the other three) — Flutter throws at paint() and the content behind
    // it silently fails to render. So the rounded surface + neutral border
    // live in an inner ClipRRect, the colored accent is a separate 3px
    // strip beside it, and the outer Container only carries the shadow.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: cardShadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: p.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: color),
                Expanded(
                  child: _CardBody(
                    prediction: prediction,
                    onTap: onTap,
                    onMarkDone: onMarkDone,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.prediction, this.onTap, this.onMarkDone});

  final MaintenancePrediction prediction;
  final VoidCallback? onTap;
  final VoidCallback? onMarkDone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pr = prediction;
    final color = statusColorFor(p, pr.urgency);
    final type = pr.type;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(maintenanceIconFor(type.label), size: 22, color: color),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.label,
                          style: TextStyle(
                              color: p.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(_doneLabel(type),
                          style:
                              TextStyle(color: p.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                if (onMarkDone != null)
                  IconButton(
                    tooltip: 'Marquer comme fait',
                    icon: Icon(Icons.check_circle_outline, color: p.ok),
                    onPressed: onMarkDone,
                    visualDensity: VisualDensity.compact,
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_badgeLabel(pr),
                        style: AppText.technical(color, size: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: pr.urgency.clamp(0.02, 1.0),
                minHeight: 7,
                backgroundColor: p.background,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(_progressLabel(pr),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: p.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Text(_intervalLabel(type),
                    style: TextStyle(
                        color: p.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            if (pr.dueDate != null) ...[
              const SizedBox(height: 3),
              Text('échéance estimée : ${Fmt.date(pr.dueDate)}',
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  String _doneLabel(MaintenanceType type) {
    final km = type.lastDoneKm;
    final date = type.lastDoneDate;
    if (km != null && date != null) {
      return 'Faite à ${Fmt.km(km)} · ${Fmt.date(date)}';
    }
    if (km != null) return 'Faite à ${Fmt.km(km)}';
    if (date != null) return 'Faite le ${Fmt.date(date)}';
    return 'Aucune intervention enregistrée';
  }

  String _badgeLabel(MaintenancePrediction p) {
    if (p.remainingKm != null) {
      return p.remainingKm! < 0
          ? '${-p.remainingKm!} km dépassé'
          : '${p.remainingKm} km';
    }
    if (p.dueDate != null) return Fmt.relative(p.dueDate);
    return '—';
  }

  String _progressLabel(MaintenancePrediction p) {
    if (p.remainingKm == null) return Fmt.relative(p.dueDate);
    return p.remainingKm! < 0
        ? 'dépassé de ${-p.remainingKm!} km'
        : '≈ ${p.remainingKm} km restants';
  }

  String _intervalLabel(MaintenanceType type) {
    final intervalKm = type.intervalKm;
    final intervalMonths = type.intervalMonths;
    if (intervalKm != null) return 'tous les ${Fmt.km(intervalKm)}';
    if (intervalMonths != null) return 'tous les $intervalMonths mois';
    return '';
  }
}
