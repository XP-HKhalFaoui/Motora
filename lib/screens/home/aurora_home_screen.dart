import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/aurora_theme.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../models/maintenance_history.dart';
import '../../models/maintenance_prediction.dart';
import '../../models/vehicle.dart';
import '../../providers/aurora_shell_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/next_due_service.dart';
import '../../services/reports_service.dart';
import '../../widgets/aurora/aurora_animate_once.dart';
import '../../widgets/aurora/aurora_app_bar_chip.dart';
import '../../widgets/aurora/aurora_card.dart';
import '../../widgets/aurora/aurora_empty_state.dart';
import '../../widgets/aurora/aurora_floating_nav.dart';
import '../../widgets/aurora/aurora_image_slot.dart';
import '../../widgets/aurora/aurora_list_row.dart';
import '../../widgets/aurora/aurora_progress_ring.dart';
import '../../widgets/storage_image.dart';
import '../home/vehicle_form_screen.dart';
import '../maintenance/add_maintenance_type_sheet.dart';
import '../new_entry/aurora_new_entry_screen.dart';
import '../notifications/notifications_screen.dart';

/// Home — "Accueil". Answers "is anything due, and what is this car
/// costing me?" in one glance. Body-only (no Scaffold, no nav) — it sits
/// inside the shell's `IndexedStack` (see `screens/shell/app_shell.dart`)
/// alongside Due, Ledger and Reports, behind the shared floating nav.
class AuroraHomeScreen extends ConsumerWidget {
  const AuroraHomeScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aurora = context.aurora;
    final vehicle = ref.watch(vehicleByIdProvider(vehicleId));
    if (vehicle == null) {
      return Center(
        child: Text('Véhicule introuvable.',
            style: AuroraText.bodyValue(aurora.textPrimary)),
      );
    }

    final predictions = ref.watch(predictionsProvider(vehicleId)).value ??
        const <MaintenancePrediction>[];
    final documents = ref.watch(documentsProvider(vehicleId)).value ?? const [];
    final history = ref.watch(maintenanceHistoryProvider(vehicleId)).value ??
        const <MaintenanceHistory>[];
    final logs = ref.watch(mileageLogsProvider(vehicleId)).value ?? const [];
    final settings = ref.watch(settingsProvider).value;
    final daysAlertThreshold =
        settings?.daysAlertThreshold ?? Thresholds.daysAlert;
    final reminders = ref.watch(remindersProvider).value ?? const [];

    final nextDue = NextDueService.next(
      predictions: predictions,
      documents: documents,
      daysAlertThreshold: daysAlertThreshold,
    );
    final report = ReportsService.build(
        history: history, logs: logs, period: ReportPeriod.all);

    MaintenancePrediction? nearestKm;
    for (final p
        in predictions.where((p) => !p.needsSetup && p.remainingKm != null)) {
      if (nearestKm == null || p.remainingKm! < nearestKm.remainingKm!) {
        nearestKm = p;
      }
    }
    final okDocs =
        documents.where((d) => d.daysToExpiry >= daysAlertThreshold).length;

    final recent = [...history]..sort((a, b) => b.doneAt.compareTo(a.doneAt));
    final recentTop = recent.take(2).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(AuroraSpacing.screenPaddingH, 12,
          AuroraSpacing.screenPaddingH, AuroraSpacing.bottomNavClearance),
      children: [
        _AppBarRow(vehicle: vehicle, hasAlerts: reminders.isNotEmpty),
        const SizedBox(height: AuroraSpacing.blockGap),
        _VehiclePhoto(vehicle: vehicle),
        const SizedBox(height: AuroraSpacing.blockGap),
        _NextDueCard(item: nextDue, vehicleId: vehicleId),
        const SizedBox(height: AuroraSpacing.blockGap),
        _StatGrid(
            report: report,
            nearestKm: nearestKm,
            okDocs: okDocs,
            totalDocs: documents.length),
        const SizedBox(height: AuroraSpacing.blockGap),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Activité récente',
                style: AuroraText.sectionLabel(aurora.textPrimary, size: 14)),
            GestureDetector(
              onTap: () => ref.read(auroraShellTabProvider.notifier).state =
                  AuroraNavTab.ledger,
              child: Text('Tout voir',
                  style:
                      AuroraText.sectionLabel(AuroraColors.accent, size: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentTop.isEmpty)
          const AuroraEmptyState(
            title: 'Aucune activité',
            message: "Enregistrez un plein, une réparation ou une dépense depuis l'ajout rapide.",
          )
        else
          for (var i = 0; i < recentTop.length; i++) ...[
            if (i > 0) const SizedBox(height: 9),
            _ActivityRow(
              entry: recentTop[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AuroraNewEntryScreen(
                      vehicleId: vehicleId, existing: recentTop[i]),
                ),
              ),
            ),
          ],
      ],
    );
  }
}

class _AppBarRow extends ConsumerWidget {
  const _AppBarRow({required this.vehicle, required this.hasAlerts});
  final Vehicle vehicle;
  final bool hasAlerts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aurora = context.aurora;
    final user = ref.watch(currentUserProvider);
    final greetName = user?.email?.split('@').first ?? '';

    // Not wrapped to a fixed 38px height: that figure is the app-bar
    // chip's own size, not a ceiling on the whole row — forcing it here
    // clipped the two-line greeting/name block, which is naturally a
    // little taller than the chips beside it.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AuroraAppBarChip(
          icon: PhosphorIconsRegular.list,
          semanticLabel: 'Menu',
          onTap: () => Scaffold.of(context).openDrawer(),
        ),
        const SizedBox(width: 11),
        const AuroraAppBarChip(
          icon: PhosphorIconsFill.carProfile,
          semanticLabel: 'Véhicule',
        ),
        const SizedBox(width: 11),
        Expanded(
          child: GestureDetector(
            onTap: () => _showVehicleSwitcher(context, ref),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Bonjour $greetName',
                    style: AuroraText.meta(aurora.muted)),
                Row(
                  children: [
                    Flexible(
                      child: Text(vehicle.name,
                          overflow: TextOverflow.ellipsis,
                          style: AuroraText.cardTitle(aurora.textPrimary,
                              size: 17)),
                    ),
                    const SizedBox(width: 4),
                    const Icon(PhosphorIconsRegular.caretDown,
                        size: 12, color: AuroraColors.iconMutedOnWhite),
                  ],
                ),
              ],
            ),
          ),
        ),
        AuroraAppBarChip(
          icon: PhosphorIconsRegular.bell,
          semanticLabel:
              hasAlerts ? 'Alertes, échéances en attente' : 'Alertes',
          showDot: hasAlerts,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
      ],
    );
  }

  Future<void> _showVehicleSwitcher(BuildContext context, WidgetRef ref) async {
    final vehicles = ref.read(vehiclesProvider).value ?? const <Vehicle>[];
    final current = ref.read(effectiveSelectedVehicleIdProvider);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.aurora.card,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AuroraRadii.largeCard)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final v in vehicles)
              ListTile(
                leading: Icon(PhosphorIconsFill.carProfile,
                    color: v.id == current
                        ? AuroraColors.accent
                        : context.aurora.iconMutedOnWhite),
                title: Text(v.name,
                    style: AuroraText.listRowTitle(context.aurora.textPrimary,
                        size: v.id == current ? 15 : 14)),
                subtitle: Text(Fmt.km(v.currentKm),
                    style: AuroraText.meta(context.aurora.muted)),
                trailing: v.id == current
                    ? const Icon(PhosphorIconsRegular.caretRight,
                        color: AuroraColors.accent)
                    : null,
                onTap: () {
                  ref.read(selectedVehicleIdProvider.notifier).state = v.id;
                  Navigator.pop(sheetContext);
                },
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(PhosphorIconsRegular.plus,
                  color: AuroraColors.accent),
              title: Text('Ajouter un véhicule',
                  style: AuroraText.listRowTitle(AuroraColors.accent)),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VehicleFormScreen()));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _VehiclePhoto extends StatelessWidget {
  const _VehiclePhoto({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AuroraRadii.largeCard),
            child: StorageImage(
              bucket: Buckets.vehiclePhotos,
              reference: vehicle.photoUrl,
              fallback: const AuroraPhotoPlaceholder(),
            ),
          ),
          if (vehicle.plateNumber != null)
            Positioned(
                left: 10,
                bottom: 10,
                child: _GlassPill(text: vehicle.plateNumber!)),
          Positioned(
              right: 10,
              bottom: 10,
              child: _GlassPill(text: Fmt.km(vehicle.currentKm))),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AuroraRadii.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .88),
            borderRadius: BorderRadius.circular(AuroraRadii.pill),
          ),
          child: Text(text,
              style: const TextStyle(
                  color: AuroraColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _NextDueCard extends StatelessWidget {
  const _NextDueCard({required this.item, required this.vehicleId});
  final NextDueItem? item;
  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    final due = item;
    if (due == null) {
      return AuroraCard(
        raised: true,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aucune échéance',
                      style: AuroraText.cardTitle(aurora.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                      'Ajoutez un type d\'entretien ou un document pour suivre vos échéances.',
                      style: AuroraText.meta(aurora.muted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => showAddMaintenanceTypeSheet(context, vehicleId),
              child: Text('Configurer',
                  style:
                      AuroraText.sectionLabel(AuroraColors.accent, size: 13)),
            ),
          ],
        ),
      );
    }

    final days = due.remainingDays;
    return AuroraCard(
      raised: true,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prochaine échéance',
                    style: AuroraText.meta(aurora.muted)),
                const SizedBox(height: 4),
                Text(due.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AuroraText.cardTitle(aurora.textPrimary)),
                const SizedBox(height: 4),
                Text(
                    '${Fmt.relative(due.dueDate)} · ${Fmt.dayMonth(due.dueDate)}',
                    style: const TextStyle(
                        color: AuroraColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AuroraAnimateOnce(
            builder: (context, factor) => AuroraProgressRing(
              progress: due.progress * factor,
              value: days == null ? '—' : '${days.abs()}',
              unit: 'jours',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.report,
    required this.nearestKm,
    required this.okDocs,
    required this.totalDocs,
  });

  final VehicleReport report;
  final MaintenancePrediction? nearestKm;
  final int okDocs;
  final int totalDocs;

  @override
  Widget build(BuildContext context) {
    final km = nearestKm;
    final kmValue = km == null
        ? '—'
        : (km.remainingKm! <= 0 ? 'à faire' : Fmt.km(km.remainingKm));
    final kmLabel = km?.type.label ?? 'Entretien';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: PhosphorIconsFill.currencyEur,
                label: 'Coût/km',
                value: report.costPerKm == null
                    ? '—'
                    : Fmt.money(report.costPerKm),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: PhosphorIconsFill.drop,
                label: 'Conso.',
                value: report.averageConsumption == null
                    ? '—'
                    : '${report.averageConsumption!.toStringAsFixed(1)} L',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                  icon: PhosphorIconsFill.gauge,
                  label: kmLabel,
                  value: kmValue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: PhosphorIconsFill.fileText,
                label: 'Papiers OK',
                value: totalDocs == 0 ? '—' : '$okDocs / $totalDocs',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.icon, required this.label, required this.value});
  final PhosphorIconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return AuroraCard(
      radius: AuroraRadii.smallCard,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AuroraColors.accentTint14,
              borderRadius: BorderRadius.circular(AuroraRadii.iconChipSmall),
            ),
            child: Icon(icon, size: 15, color: AuroraColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AuroraText.meta(aurora.muted, size: 10)),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AuroraText.tabularValue(aurora.textPrimary, size: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry, required this.onTap});
  final MaintenanceHistory entry;
  final VoidCallback onTap;

  static PhosphorIconData _iconFor(HistoryEntryKind kind) => switch (kind) {
        HistoryEntryKind.fuel => PhosphorIconsFill.gasPump,
        HistoryEntryKind.expense => PhosphorIconsFill.currencyEur,
        HistoryEntryKind.maintenance => PhosphorIconsFill.wrench,
      };

  @override
  Widget build(BuildContext context) {
    final meta = [
      Fmt.dayMonth(entry.doneAt),
      if (entry.km != null) Fmt.km(entry.km),
    ].join(' · ');
    return AuroraListRow(
      icon: _iconFor(entry.kind),
      title: entry.title,
      metaText: meta,
      trailingText: entry.cost == null ? null : Fmt.money(entry.cost),
      onTap: onTap,
    );
  }
}
