import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_text.dart';
import '../../core/formatters.dart';
import '../../core/maintenance_icons.dart';
import '../../core/theme.dart';
import '../../models/maintenance_prediction.dart';
import '../../models/vehicle.dart';
import '../../providers/auth_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/prediction_service.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/striped_placeholder.dart';
import '../settings/settings_screen.dart';
import '../vehicle_detail/vehicle_detail_screen.dart';
import 'alerts_banner.dart';
import 'vehicle_form_screen.dart';

/// Accueil (screen 02): greeting + avatar, priority-alerts card, vehicle
/// cards. Lives inside [AppShell] — no own Scaffold/AppBar.
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
          child: AsyncValueView<List<Vehicle>>(
            value: vehiclesAsync,
            onRetry: () => ref.read(vehiclesProvider.notifier).refresh(),
            data: (vehicles) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bonjour $displayName',
                              style: TextStyle(
                                  color: p.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 3),
                          Text('Mes véhicules',
                              style: AppText.screenTitle(p.textPrimary)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.surfaceElevated,
                          border: Border.all(color: p.border),
                        ),
                        child: Text(initials,
                            style: AppText.odometer(p.primary, size: 15)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
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
                  Text(
                    '${vehicles.length} véhicule${vehicles.length > 1 ? 's' : ''}',
                    style: AppText.sectionLabel(p.textSecondary),
                  ),
                  const SizedBox(height: 12),
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
                      MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
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

class _VehicleCard extends ConsumerWidget {
  const _VehicleCard({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final logsAsync = ref.watch(mileageLogsProvider(vehicle.id));
    final predictionsAsync = ref.watch(predictionsProvider(vehicle.id));
    final kmPerMonth = logsAsync.value == null
        ? null
        : PredictionService.monthlyKmAverage(logsAsync.value!);
    final topPredictions = (predictionsAsync.value ?? const <MaintenancePrediction>[])
        .take(2)
        .toList();

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
              builder: (_) => VehicleDetailScreen(vehicleId: vehicle.id)),
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
                    StripedPlaceholder(label: 'photo · ${vehicle.name}'),
                    if (vehicle.plateNumber != null)
                      Positioned(
                        right: 12,
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
                padding: const EdgeInsets.all(16),
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
                    if (topPredictions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: topPredictions
                            .map((pred) => Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        right:
                                            pred == topPredictions.first &&
                                                    topPredictions.length > 1
                                                ? 8
                                                : 0),
                                    child: _EchChip(prediction: pred),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
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

class _EchChip extends StatelessWidget {
  const _EchChip({required this.prediction});
  final MaintenancePrediction prediction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = statusColorFor(p, prediction.urgency);
    final label = prediction.remainingKm != null
        ? '${prediction.type.label} · ${prediction.remainingKm! < 0 ? 'dépassé' : '${prediction.remainingKm} km'}'
        : prediction.type.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        border: Border.all(color: color.withValues(alpha: .3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(maintenanceIconFor(prediction.type.label), size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
