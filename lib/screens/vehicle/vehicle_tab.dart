import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_text.dart';
import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/vehicle.dart';
import '../../providers/carnet_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/storage_image.dart';
import '../../widgets/striped_placeholder.dart';
import '../home/vehicle_form_screen.dart';
import '../vehicle_detail/sections/overview_section.dart';

/// "Véhicule" tab — the photo hero and the digest that pulls the key
/// signal from everywhere else: km gauge, cost stats, the next few
/// échéances and the soonest-expiring documents.
///
/// This was the vehicle hub, a full screen with its own segmented control
/// over five sections. The bottom bar now carries that navigation, so what
/// is left here is the hero plus [OverviewSection]; the other four
/// sections moved to their own tabs or to Plus.
class VehicleTab extends ConsumerWidget {
  const VehicleTab({super.key, required this.vehicleId});

  final String vehicleId;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(predictionsProvider(vehicleId));
    ref.invalidate(maintenanceHistoryProvider(vehicleId));
    ref.invalidate(documentsProvider(vehicleId));
    ref.invalidate(mileageLogsProvider(vehicleId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final vehicle = ref.watch(vehicleByIdProvider(vehicleId));

    if (vehicle == null) {
      // vehicleByIdProvider is derived from the vehicle list, so a null
      // here means either "still loading" or "no such vehicle".
      final vehicles = ref.watch(vehiclesProvider);
      return vehicles.isLoading
          ? const Center(child: CircularProgressIndicator())
          : AsyncValueView(
              value: vehicles,
              onRetry: () => ref.read(vehiclesProvider.notifier).refresh(),
              data: (_) => const EmptyState(
                icon: Icons.directions_car_outlined,
                message: "Ce véhicule n'existe plus.",
              ),
            );
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      color: p.primary,
      backgroundColor: p.surface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Hero(vehicle: vehicle)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            sliver: SliverToBoxAdapter(
              child: OverviewSection(vehicleId: vehicleId),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends ConsumerWidget {
  const _Hero({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final topPad = MediaQuery.of(context).padding.top;
    final subtitle = [
      if (vehicle.brand != null) vehicle.brand,
      if (vehicle.year != null) vehicle.year.toString(),
    ].whereType<String>().join(' · ');

    return SizedBox(
      height: 236 + topPad,
      child: Stack(
        fit: StackFit.expand,
        children: [
          StorageImage(
            bucket: Buckets.vehiclePhotos,
            reference: vehicle.photoUrl,
            fallback: StripedPlaceholder(label: 'photo · ${vehicle.name}'),
          ),
          // Scrim so white controls and text stay legible over any photo.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .38),
                  Colors.black.withValues(alpha: .05),
                  p.background,
                ],
                stops: const [0, .45, 1],
              ),
            ),
          ),
          Positioned(
            top: topPad + 6,
            left: 8,
            right: 8,
            child: Row(
              children: [
                const Spacer(),
                _ExportButton(vehicleId: vehicle.id),
                const SizedBox(width: 8),
                _CircleButton(
                  icon: Icons.edit_outlined,
                  label: 'Modifier le véhicule',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => VehicleFormScreen(existing: vehicle)),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(vehicle.name,
                          style: AppText.screenTitle(p.textPrimary, size: 24)),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: TextStyle(
                                color: p.textSecondary, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(Fmt.km(vehicle.currentKm),
                        style: AppText.odometer(p.textPrimary, size: 22)),
                    if (vehicle.plateNumber != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: p.border),
                        ),
                        child: Text(vehicle.plateNumber!,
                            style: TextStyle(
                                color: p.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Builds and shares the carnet PDF. Gathers every section, including ones
/// the user hasn't opened, so it spins while the data loads.
class _ExportButton extends ConsumerStatefulWidget {
  const _ExportButton({required this.vehicleId});
  final String vehicleId;

  @override
  ConsumerState<_ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends ConsumerState<_ExportButton> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(carnetExporterProvider).share(widget.vehicleId);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .35),
          shape: BoxShape.circle,
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }
    return _CircleButton(
      icon: Icons.ios_share,
      label: "Exporter le carnet d'entretien",
      tooltip: "Exporter le carnet d'entretien",
      onTap: _export,
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.label,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;

  /// Spoken by a screen reader — an icon on its own says nothing.
  final String label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.black.withValues(alpha: .35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // The circle stays 40dp for the design; the tappable area is
        // padded out to the 48dp minimum.
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
    final semantic = Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: button,
    );
    if (tooltip == null) return semantic;
    return Tooltip(message: tooltip!, child: semantic);
  }
}
