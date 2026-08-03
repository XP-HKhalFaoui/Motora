import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/aurora_icons.dart';
import '../../core/aurora_theme.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../providers/document_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/postpone_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/due_status_service.dart';
import '../../widgets/aurora/aurora_animate_once.dart';
import '../../widgets/aurora/aurora_app_bar_chip.dart';
import '../../widgets/aurora/aurora_button.dart';
import '../../widgets/aurora/aurora_card.dart';
import '../../widgets/aurora/aurora_count_chip.dart';
import '../../widgets/aurora/aurora_empty_state.dart';
import '../../widgets/aurora/aurora_list_row.dart';
import '../../widgets/aurora/aurora_segmented_control.dart';
import '../admin_documents/add_document_sheet.dart';
import '../maintenance/add_maintenance_type_sheet.dart';
import '../new_entry/aurora_new_entry_screen.dart';

enum _DueFilter { all, maintenance, documents }

/// Due & reminders — "Échéances". The unified list of upcoming
/// maintenance and expiring documents. Body-only, same integration model
/// as [AuroraHomeScreen] — no Scaffold/nav of its own.
class AuroraDueScreen extends ConsumerStatefulWidget {
  const AuroraDueScreen({super.key, required this.vehicleId});
  final String vehicleId;

  @override
  ConsumerState<AuroraDueScreen> createState() => _AuroraDueScreenState();
}

class _AuroraDueScreenState extends ConsumerState<AuroraDueScreen> {
  var _filter = _DueFilter.all;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    final predictions = ref.watch(predictionsProvider(widget.vehicleId)).value ?? const [];
    final documents = ref.watch(documentsProvider(widget.vehicleId)).value ?? const [];
    final settings = ref.watch(settingsProvider).value;
    final kmAlertThreshold = settings?.kmAlertThreshold ?? Thresholds.kmAlert;
    final daysAlertThreshold = settings?.daysAlertThreshold ?? Thresholds.daysAlert;
    final postponeMap = ref.watch(postponeProvider).value ?? const <String, DateTime>{};

    final board = DueStatusService.build(
      predictions: predictions,
      documents: documents,
      kmAlertThreshold: kmAlertThreshold,
      daysAlertThreshold: daysAlertThreshold,
      isPostponed: (id) {
        final until = postponeMap[id];
        return until != null && until.isAfter(DateTime.now());
      },
    );

    final visible = board.entries.where((e) {
      switch (_filter) {
        case _DueFilter.all:
          return true;
        case _DueFilter.maintenance:
          return e.isMaintenance;
        case _DueFilter.documents:
          return !e.isMaintenance;
      }
    }).toList();

    final urgent = visible.where((e) => e.status == DueStatus.urgent).toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
    final hero = urgent.isEmpty ? null : urgent.first;
    final urgentRest = urgent.skip(hero == null ? 0 : 1).toList();

    final watching = visible
        .where((e) => e.status == DueStatus.watch || e.status == DueStatus.toConfigure)
        .toList()
      ..sort((a, b) {
        if (a.status != b.status) return a.status == DueStatus.watch ? -1 : 1;
        return a.sortKey.compareTo(b.sortKey);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AuroraSpacing.screenPaddingH, 12, AuroraSpacing.screenPaddingH, AuroraSpacing.bottomNavClearance),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Échéances', style: AuroraText.screenTitle(aurora.textPrimary)),
            AuroraAppBarChip(
              icon: PhosphorIconsRegular.slidersHorizontal,
              semanticLabel: 'Seuils des alertes',
              onTap: () => Scaffold.of(context).openDrawer(),
            ),
          ],
        ),
        const SizedBox(height: AuroraSpacing.blockGap),
        Row(
          children: [
            Expanded(
              child: AuroraCountChip(
                  count: board.countOf(DueStatus.urgent), label: 'Urgent', filled: true),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AuroraCountChip(
                  count: board.countOf(DueStatus.watch), label: 'À surveiller'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AuroraCountChip(count: board.countOf(DueStatus.ok), label: 'OK'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AuroraCountChip(
                  count: board.countOf(DueStatus.toConfigure), label: 'À régler'),
            ),
          ],
        ),
        const SizedBox(height: AuroraSpacing.blockGap),
        AuroraSegmentedControl<_DueFilter>(
          segments: const [
            AuroraSegment(value: _DueFilter.all, label: 'Tout'),
            AuroraSegment(value: _DueFilter.maintenance, label: 'Entretien'),
            AuroraSegment(value: _DueFilter.documents, label: 'Documents'),
          ],
          value: _filter,
          onChanged: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: AuroraSpacing.blockGap),
        if (hero != null) ...[
          _UrgentHeroCard(entry: hero, vehicleId: widget.vehicleId),
          const SizedBox(height: AuroraSpacing.blockGap),
        ],
        for (final e in urgentRest) ...[
          _UrgentRow(entry: e, vehicleId: widget.vehicleId),
          const SizedBox(height: 12),
        ],
        if (watching.isNotEmpty) ...[
          Text('À surveiller', style: AuroraText.sectionLabel(aurora.muted)),
          const SizedBox(height: 12),
          for (var i = 0; i < watching.length; i++) ...[
            if (i > 0) const SizedBox(height: 9),
            _WatchRow(entry: watching[i], vehicleId: widget.vehicleId),
          ],
        ],
        if (hero == null && urgentRest.isEmpty && watching.isEmpty)
          AuroraEmptyState(
            title: 'Rien à signaler',
            message: predictions.isEmpty && documents.isEmpty
                ? "Rien n'est encore suivi pour ce véhicule."
                : 'Toutes les échéances suivies sont à jour.',
            actionLabel: predictions.isEmpty && documents.isEmpty
                ? "Ajouter un type d'entretien"
                : null,
            onAction: predictions.isEmpty && documents.isEmpty
                ? () => showAddMaintenanceTypeSheet(context, widget.vehicleId)
                : null,
          ),
      ],
    );
  }
}

PhosphorIconData _iconFor(DueEntry e) => e.isMaintenance
    ? auroraIconForMaintenance(e.label)
    : auroraIconForDocument(e.document!.docType);

void _openEditor(BuildContext context, DueEntry e, String vehicleId) {
  if (e.isMaintenance) {
    showAddMaintenanceTypeSheet(context, vehicleId, existing: e.prediction!.type);
  } else {
    showAddDocumentSheet(context, vehicleId, existing: e.document);
  }
}

class _UrgentHeroCard extends ConsumerWidget {
  const _UrgentHeroCard({required this.entry, required this.vehicleId});
  final DueEntry entry;
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuroraDarkCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AuroraColors.accentChipOnDark(),
                  borderRadius: BorderRadius.circular(AuroraRadii.iconChipLarge),
                ),
                child: const Icon(PhosphorIconsFill.shieldWarning, size: 19, color: AuroraColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Urgent',
                        style: TextStyle(color: AuroraColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
                    Text(entry.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AuroraText.cardTitle(AuroraColors.onDark, size: 18)),
                    Text('${Fmt.relative(entry.dueDate)} · ${Fmt.dayMonth(entry.dueDate)}',
                        style: TextStyle(color: AuroraColors.onDarkSecondary(), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(AuroraRadii.progressBar),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  Container(color: AuroraColors.onDarkProgressTrack()),
                  AuroraAnimateOnce(
                    builder: (context, factor) => FractionallySizedBox(
                      widthFactor: entry.progress.clamp(0.0, 1.0) * factor,
                      child: Container(color: AuroraColors.accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AuroraPrimaryButton(
                  label: entry.isMaintenance ? 'Marquer comme fait' : 'Renouveler',
                  height: 44,
                  fontSize: 13,
                  onTap: () => _resolve(context, ref),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AuroraOutlineButton(
                  label: 'Reporter',
                  height: 44,
                  fontSize: 13,
                  onTap: () => _postpone(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _resolve(BuildContext context, WidgetRef ref) {
    if (entry.isMaintenance) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuroraNewEntryScreen(
            vehicleId: vehicleId,
            defaultTitle: entry.label,
            defaultMaintenanceTypeId: entry.prediction!.type.id,
            linkedLabel: entry.label,
          ),
        ),
      );
    } else {
      showAddDocumentSheet(context, vehicleId, existing: entry.document);
    }
  }

  Future<void> _postpone(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(postponeProvider.notifier).postpone(entry.id);
    messenger.showSnackBar(SnackBar(
      backgroundColor: AuroraColors.ink,
      content: const Text('Reporté d\'une semaine.', style: TextStyle(color: AuroraColors.onDark)),
      action: SnackBarAction(
        label: 'OK',
        textColor: AuroraColors.accent,
        onPressed: () {},
      ),
    ));
  }
}

class _UrgentRow extends StatelessWidget {
  const _UrgentRow({required this.entry, required this.vehicleId});
  final DueEntry entry;
  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    return AuroraListRow(
      icon: _iconFor(entry),
      title: entry.label,
      chipTint: AuroraColors.accentTint14,
      subtitle: entry.remainingKm != null && entry.remainingKm! <= 0
          ? 'dépassé'
          : Fmt.relative(entry.dueDate),
      radius: 22,
      padding: const EdgeInsets.all(14),
      trailingWidget: const _StatusPill(label: 'Urgent'),
      onTap: () => _openEditor(context, entry, vehicleId),
    );
  }
}

class _WatchRow extends StatelessWidget {
  const _WatchRow({required this.entry, required this.vehicleId});
  final DueEntry entry;
  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final isToConfigure = entry.status == DueStatus.toConfigure;
    return AuroraListRow(
      icon: _iconFor(entry),
      title: entry.label,
      neutral: isToConfigure,
      subtitle: isToConfigure ? 'Intervalle non configuré' : Fmt.relative(entry.dueDate),
      trailingWidget: isToConfigure
          ? _ReglerPill(onTap: () => _openEditor(context, entry, vehicleId))
          : const AuroraRowChevron(),
      onTap: () => _openEditor(context, entry, vehicleId),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AuroraColors.accentTint16,
        borderRadius: BorderRadius.circular(AuroraRadii.pill),
      ),
      child: Text(label,
          style: const TextStyle(color: AuroraColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _ReglerPill extends StatelessWidget {
  const _ReglerPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AuroraRadii.pill),
          border: Border.all(color: AuroraColors.accent),
        ),
        child: const Text('Régler',
            style: TextStyle(color: AuroraColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
