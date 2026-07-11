import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/maintenance_prediction.dart';

/// A maintenance type row with a progress bar (km consumed of interval),
/// color-coded status and the km/date forecast.
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
    final p = prediction;
    final color = statusColor(p.urgency);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    child: Text(p.type.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  if (onMarkDone != null)
                    IconButton(
                      tooltip: 'Marquer comme fait',
                      icon: const Icon(Icons.check_circle_outline),
                      color: AppColors.ok,
                      onPressed: onMarkDone,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: p.urgency.clamp(0.02, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Text(_kmLabel(p),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
                  Text(_dateLabel(p),
                      style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _kmLabel(MaintenancePrediction p) {
    if (p.remainingKm == null) return 'Basé sur le temps';
    if (p.remainingKm! < 0) return 'Dépassé de ${-p.remainingKm!} km';
    return '≈ ${p.remainingKm} km restants';
  }

  String _dateLabel(MaintenancePrediction p) {
    if (p.dueDate == null) return '';
    return Fmt.relative(p.dueDate);
  }
}
