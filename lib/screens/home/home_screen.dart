import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_text.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/maintenance_icons.dart';
import '../../core/theme.dart';
import '../../models/maintenance_prediction.dart';
import '../../models/vehicle.dart';
import '../../providers/auth_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/prediction_service.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/storage_image.dart';
import '../../widgets/striped_placeholder.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';
import '../vehicle_detail/vehicle_hub_screen.dart';
import 'alerts_banner.dart';
import 'vehicle_form_screen.dart';

/// Accueil (screen 02) — the "garage": a compact branded header, a slim
/// priority-alert strip, then one health-ringed card per vehicle. Lives
/// inside [AppShell] — no own Scaffold/AppBar.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final user = ref.watch(currentUserProvider);
    final displayName = _displayName(user?.email, user?.userMetadata);
    final initials = _initials(displayName);

    return Container(
      color: p.background,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(vehiclesProvider.notifier).refresh(),
          color: p.primary,
          backgroundColor: p.surface,
          child: AsyncValueView<List<Vehicle>>(
            value: vehiclesAsync,
            onRetry: () => ref.read(vehiclesProvider.notifier).refresh(),
            data: (vehicles) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Motora',
                        style: AppText.wordmark(p.textPrimary, size: 24)),
                    const Spacer(),
                    _BellButton(
                      hasAlerts:
                          (ref.watch(remindersProvider).value ?? const [])
                              .isNotEmpty,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen())),
                    ),
                    const SizedBox(width: 10),
                    // The initials are decoration; a screen reader needs to
                    // hear what the control does, not the letter in it.
                    Semantics(
                      button: true,
                      label: 'Réglages',
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen())),
                        customBorder: const CircleBorder(),
                        child: Container(
                          // 48dp minimum touch target; the visible circle
                          // stays 42 via the inner decoration.
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.surfaceElevated,
                              border: Border.all(color: p.border),
                            ),
                            child: Text(initials,
                                style: AppText.odometer(p.primary, size: 14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (displayName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Bonjour $displayName 👋',
                      style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                ],
                const SizedBox(height: 20),
                const AlertsBanner(),
                if (vehicles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: EmptyState(
                      icon: Icons.directions_car_outlined,
                      message:
                          "Aucun véhicule.\nAppuyez sur le + pour commencer.",
                    ),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('MON GARAGE',
                          style: AppText.sectionLabel(p.textSecondary)),
                      Text(
                        '${vehicles.length} véhicule${vehicles.length > 1 ? 's' : ''}',
                        style: AppText.sectionLabel(p.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...vehicles.map((v) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _VehicleCard(vehicle: v),
                      )),
                ],
                const SizedBox(height: 4),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VehicleFormScreen()),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Ajouter un véhicule'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _displayName(String? email, Map<String, dynamic>? meta) {
    final fullName = meta?['full_name'] as String?;
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim().split(' ').first;
    }
    if (email == null || email.isEmpty) return '';
    return email.split('@').first;
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.hasAlerts, required this.onTap});
  final bool hasAlerts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      // The red dot is the only thing distinguishing the two states
      // visually — say it out loud rather than leaving it to colour.
      label: hasAlerts ? 'Alertes, échéances en attente' : 'Alertes',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.surfaceElevated,
              border: Border.all(color: p.border),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_rounded,
                    size: 20, color: p.textSecondary),
                if (hasAlerts)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.danger,
                        border:
                            Border.all(color: p.surfaceElevated, width: 1.5),
                      ),
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

class _VehicleCard extends ConsumerWidget {
  const _VehicleCard({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final predictions =
        ref.watch(predictionsProvider(vehicle.id)).value ?? const [];
    final logsAsync = ref.watch(mileageLogsProvider(vehicle.id));
    // Only a *measured* average is shown; with fewer than two readings
    // there is nothing to average and inventing a figure would read as
    // real data.
    final kmPerMonth = logsAsync.value == null
        ? null
        : PredictionService.measuredMonthlyKmAverage(logsAsync.value!);

    // "Santé" is a holistic score — the average of every échéance's
    // remaining headroom — so a single overdue item dents it without
    // zeroing an otherwise-healthy car. The worst item is still surfaced
    // in the action strip below. Types with no recorded last intervention
    // are excluded: they carry urgency 0 but that means "unknown", and
    // counting them would inflate the score towards a false 100%.
    final forecastable = predictions.where((pr) => !pr.needsSetup).toList();
    final int? health;
    if (forecastable.isEmpty) {
      health = null;
    } else {
      final avgUrgency =
          forecastable.fold<double>(0, (s, pr) => s + pr.urgency) /
              forecastable.length;
      health = ((1 - avgUrgency) * 100).round().clamp(0, 100);
    }
    MaintenancePrediction? worst;
    for (final pr in forecastable) {
      if (worst == null || pr.urgency > worst.urgency) worst = pr;
    }
    final toConfigure = predictions.length - forecastable.length;

    final subtitleParts = [
      if (vehicle.brand != null) vehicle.brand,
      if (vehicle.year != null) vehicle.year.toString(),
    ].whereType<String>().join(' · ');

    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => VehicleHubScreen(vehicleId: vehicle.id)),
        ),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: p.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 118,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    StorageImage(
                      bucket: Buckets.vehiclePhotos,
                      reference: vehicle.photoUrl,
                      fallback:
                          StripedPlaceholder(label: 'photo · ${vehicle.name}'),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _HealthRing(percent: health),
                    ),
                    if (toConfigure > 0)
                      Positioned(
                        top: 10,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$toConfigure à configurer',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    if (vehicle.plateNumber != null)
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(vehicle.plateNumber!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                              Text(vehicle.name,
                                  style: AppText.screenTitle(p.textPrimary,
                                      size: 18)),
                              if (subtitleParts.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(subtitleParts,
                                    style: TextStyle(
                                        color: p.textSecondary, fontSize: 13)),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(Fmt.km(vehicle.currentKm),
                                style: AppText.odometer(p.textPrimary)),
                            const SizedBox(height: 3),
                            Text(
                              kmPerMonth == null
                                  ? 'km'
                                  : 'km · +${kmPerMonth.round()}/mois',
                              style: TextStyle(
                                  color: p.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _ActionStrip(worst: worst, toConfigure: toConfigure),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The single most-urgent next action for a vehicle — or an "à jour" state
/// when nothing is due. Colored by urgency.
class _ActionStrip extends StatelessWidget {
  const _ActionStrip({required this.worst, this.toConfigure = 0});

  /// Most urgent *forecastable* échéance, or null when none can be
  /// forecast yet.
  final MaintenancePrediction? worst;

  /// How many types are waiting on a last-intervention anchor.
  final int toConfigure;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    if (worst == null && toConfigure > 0) {
      return _strip(
        color: p.textSecondary,
        icon: Icons.info_outline,
        label: 'Entretiens à configurer',
        trailing: '$toConfigure en attente',
      );
    }

    if (worst == null || worst!.urgency < 0.6) {
      return _strip(
        color: p.ok,
        icon: Icons.check_circle_rounded,
        label: 'À jour',
        trailing: worst == null ? 'aucune échéance' : 'rien d\'urgent',
      );
    }

    final color = statusColorFor(p, worst!.urgency);
    final remaining = worst!.remainingKm;
    final trailing = remaining != null
        ? (remaining < 0 ? 'en retard' : 'dans $remaining km')
        : (worst!.isOverdue ? 'en retard' : 'bientôt');

    return _strip(
      color: color,
      icon: maintenanceIconFor(worst!.type.label),
      label: worst!.type.label,
      trailing: trailing,
    );
  }

  Widget _strip({
    required Color color,
    required IconData icon,
    required String label,
    required String trailing,
  }) {
    return Builder(builder: (context) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          border: Border.all(color: color.withValues(alpha: .3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: color, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Text(trailing, style: AppText.technical(color, size: 12.5)),
          ],
        ),
      );
    });
  }
}

/// Compact circular "santé" ring overlaid on the vehicle photo. A null
/// [percent] means there is nothing to score yet (no forecastable
/// échéance) and renders an empty neutral ring rather than a green 100%.
class _HealthRing extends StatelessWidget {
  const _HealthRing({required this.percent});
  final int? percent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final percent = this.percent;
    // A CustomPaint draws nothing a screen reader can see, and this ring
    // is the primary health signal on the card.
    return Semantics(
      label: percent == null
          ? 'Santé du véhicule non calculable'
          : 'Santé du véhicule $percent %',
      excludeSemantics: true,
      child: _ring(context, p, percent),
    );
  }

  Widget _ring(BuildContext context, AppPalette p, int? percent) {
    if (percent == null) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: p.surface.withValues(alpha: .92),
        ),
        child: CustomPaint(
          painter:
              _RingPainter(progress: 0, color: p.textMuted, track: p.border),
          child: Center(
            child: Text('—', style: AppText.odometer(p.textMuted, size: 16)),
          ),
        ),
      );
    }
    final urgency = 1 - percent / 100;
    final color = statusColorFor(p, urgency);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.surface.withValues(alpha: .92),
      ),
      child: CustomPaint(
        painter: _RingPainter(
          progress: percent / 100,
          color: color,
          track: p.border,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                        text: '$percent',
                        style: AppText.odometer(color, size: 16)),
                    TextSpan(
                        text: '%', style: AppText.technical(color, size: 9)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(
      {required this.progress, required this.color, required this.track});
  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    const start = -math.pi / 2;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, trackPaint);
    if (progress > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
          math.pi * 2 * progress.clamp(0, 1), false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
