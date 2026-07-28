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
import '../../providers/ui_state_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/storage_image.dart';
import '../../widgets/striped_placeholder.dart';
import '../home/vehicle_form_screen.dart';
import 'sections/documents_section.dart';
import 'sections/fuel_section.dart';
import 'sections/maintenance_section.dart';
import 'sections/mileage_section.dart';
import 'sections/overview_section.dart';

/// Car-first hub (replaces the old "Détail véhicule"): a photo hero header
/// and a sticky segmented control — Aperçu · Entretien · Docs · Km — that
/// gather everything about one vehicle in a single place. Opening a hub
/// also makes this vehicle the quick-add target.
class VehicleHubScreen extends ConsumerStatefulWidget {
  const VehicleHubScreen({
    super.key,
    required this.vehicleId,
    this.initialSection = 0,
  });

  final String vehicleId;
  final int initialSection;

  @override
  ConsumerState<VehicleHubScreen> createState() => _VehicleHubScreenState();
}

class _VehicleHubScreenState extends ConsumerState<VehicleHubScreen> {
  late int _section = widget.initialSection;

  static const _segments = [
    'Aperçu',
    'Entretien',
    'Docs',
    'Km',
    'Carburant',
  ];

  @override
  void initState() {
    super.initState();
    // Make the car we're viewing the default target for the quick-add FAB.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(selectedVehicleIdProvider.notifier).state = widget.vehicleId;
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(predictionsProvider(widget.vehicleId));
    ref.invalidate(maintenanceHistoryProvider(widget.vehicleId));
    ref.invalidate(documentsProvider(widget.vehicleId));
    ref.invalidate(mileageLogsProvider(widget.vehicleId));
  }

  Widget _sectionBody() {
    switch (_section) {
      case 1:
        return MaintenanceSection(vehicleId: widget.vehicleId);
      case 2:
        return DocumentsSection(vehicleId: widget.vehicleId);
      case 3:
        return MileageSection(vehicleId: widget.vehicleId);
      case 4:
        return FuelSection(vehicleId: widget.vehicleId);
      case 0:
      default:
        return OverviewSection(
          vehicleId: widget.vehicleId,
          onOpenSection: (i) => setState(() => _section = i),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final vehicle = ref.watch(vehicleByIdProvider(widget.vehicleId));

    if (vehicle == null) {
      // vehicleByIdProvider is derived from the vehicle list, so a null
      // here means either "still loading" or "no such vehicle" — the
      // latter used to spin forever with no way out.
      final vehicles = ref.watch(vehiclesProvider);
      return Scaffold(
        backgroundColor: p.background,
        appBar: AppBar(backgroundColor: p.background, elevation: 0),
        body: vehicles.isLoading
            ? const Center(child: CircularProgressIndicator())
            : AsyncValueView(
                value: vehicles,
                onRetry: () => ref.read(vehiclesProvider.notifier).refresh(),
                data: (_) => const EmptyState(
                  icon: Icons.directions_car_outlined,
                  message: "Ce véhicule n'existe plus.",
                ),
              ),
      );
    }

    return Scaffold(
      backgroundColor: p.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: p.primary,
        backgroundColor: p.surface,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Hero(vehicle: vehicle)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SegmentBarDelegate(
                child: _SegmentedControl(
                  segments: _segments,
                  current: _section,
                  onChanged: (i) => setState(() => _section = i),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              sliver: SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, .02),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_section),
                    child: _sectionBody(),
                  ),
                ),
              ),
            ),
          ],
        ),
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
                _CircleButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
                const Spacer(),
                _ExportButton(vehicleId: vehicle.id),
                const SizedBox(width: 8),
                _CircleButton(
                  icon: Icons.edit_outlined,
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
      tooltip: "Exporter le carnet d'entretien",
      onTap: _export,
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.black.withValues(alpha: .35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.segments,
    required this.current,
    required this.onChanged,
  });

  final List<String> segments;
  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      color: p.background,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segWidth = (constraints.maxWidth) / segments.length;
            return Stack(
              children: [
                AnimatedAlign(
                  alignment: Alignment(
                    segments.length == 1
                        ? 0
                        : -1 + 2 * current / (segments.length - 1),
                    0,
                  ),
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    width: segWidth,
                    height: 40,
                    decoration: BoxDecoration(
                      color: p.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(segments.length, (i) {
                    final active = i == current;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: SizedBox(
                          height: 40,
                          child: Center(
                            // Scales down rather than ellipsising: with five
                            // segments on a narrow phone "Entretien" and
                            // "Carburant" no longer fit at 13px, and "Entr…"
                            // is worse than slightly smaller type.
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                child: Text(
                                  segments[i],
                                  maxLines: 1,
                                  style: TextStyle(
                                    color:
                                        active ? p.onPrimary : p.textSecondary,
                                    fontSize: 13,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SegmentBarDelegate extends SliverPersistentHeaderDelegate {
  _SegmentBarDelegate({required this.child});
  final Widget child;

  static const _height = 66.0;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(height: _height, child: child);
  }

  @override
  bool shouldRebuild(covariant _SegmentBarDelegate oldDelegate) =>
      oldDelegate.child != child;
}
