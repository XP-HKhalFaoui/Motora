import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/aurora_icons.dart';
import '../../core/aurora_theme.dart';
import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/formatters.dart';
import '../../models/maintenance_history.dart';
import '../../providers/carnet_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../services/fuel_service.dart';
import '../../services/history_filter.dart';
import '../../widgets/aurora/aurora_app_bar_chip.dart';
import '../../widgets/aurora/aurora_card.dart';
import '../../widgets/aurora/aurora_empty_state.dart';
import '../../widgets/aurora/aurora_filter_chip.dart';
import '../../widgets/aurora/aurora_list_row.dart';
import '../../widgets/aurora/aurora_shimmer.dart';
import '../new_entry/aurora_new_entry_screen.dart';

/// Ledger — "Journal". Searchable, filterable history with running
/// totals. Body-only, same integration model as the other Aurora tabs.
class AuroraLedgerScreen extends ConsumerStatefulWidget {
  const AuroraLedgerScreen({super.key, required this.vehicleId});
  final String vehicleId;

  @override
  ConsumerState<AuroraLedgerScreen> createState() => _AuroraLedgerScreenState();
}

class _AuroraLedgerScreenState extends ConsumerState<AuroraLedgerScreen> {
  final _search = TextEditingController();
  var _filter = const HistoryFilter();
  bool _exporting = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(carnetExporterProvider).share(widget.vehicleId);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: AuroraColors.ink,
        content: Text(friendlyError(e), style: const TextStyle(color: AuroraColors.onDark)),
      ));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// "juillet 2026" -> "Juillet 2026" — the spec's own literal example is
  /// mixed-case; [Fmt.monthHeader] (shared with non-Aurora screens) always
  /// upper-cases, so this screen capitalizes locally instead of changing
  /// that shared helper.
  String _monthLabel(DateTime d) {
    final s = Fmt.monthHeader(d).toLowerCase();
    return s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    final historyAsync = ref.watch(maintenanceHistoryProvider(widget.vehicleId));
    final history = historyAsync.value ?? const <MaintenanceHistory>[];

    final filtered = _filter.apply(history);
    final garages = history.map((h) => h.garageName).whereType<String>().toSet().toList()..sort();
    final consumption = FuelService.consumptionByEntryId(history);
    final total = filtered.fold<double>(0, (s, h) => s + (h.cost ?? 0));
    final monthsSpan = _monthsSpan(filtered);
    final monthlyAverage = monthsSpan == 0 ? 0.0 : total / monthsSpan;

    final grouped = _groupByMonth(filtered);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AuroraSpacing.screenPaddingH, 12, AuroraSpacing.screenPaddingH, AuroraSpacing.bottomNavClearance),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Journal', style: AuroraText.screenTitle(aurora.textPrimary)),
            Row(
              children: [
                AuroraAppBarChip(
                  icon: PhosphorIconsRegular.funnel,
                  semanticLabel: 'Réinitialiser les filtres',
                  onTap: () => setState(() {
                    _filter = const HistoryFilter();
                    _search.clear();
                  }),
                ),
                const SizedBox(width: 8),
                _exporting
                    ? const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AuroraColors.accent),
                          ),
                        ),
                      )
                    : AuroraAppBarChip(
                        icon: PhosphorIconsRegular.export,
                        semanticLabel: "Exporter le carnet d'entretien",
                        onTap: _export,
                      ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AuroraSpacing.blockGap),
        _SearchField(
          controller: _search,
          onChanged: (v) => setState(() => _filter = _filter.copyWith(query: v)),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              AuroraFilterChip(
                label: 'Entretien',
                selected: _filter.kind == HistoryKind.maintenance,
                onTap: () => setState(() => _filter = _filter.copyWith(
                    kind: _filter.kind == HistoryKind.maintenance
                        ? HistoryKind.all
                        : HistoryKind.maintenance)),
              ),
              const SizedBox(width: 7),
              AuroraFilterChip(
                label: 'Carburant',
                selected: _filter.kind == HistoryKind.fuel,
                onTap: () => setState(() => _filter = _filter.copyWith(
                    kind: _filter.kind == HistoryKind.fuel ? HistoryKind.all : HistoryKind.fuel)),
              ),
              const SizedBox(width: 7),
              AuroraFilterChip(
                label: 'Dépenses',
                selected: _filter.kind == HistoryKind.expense,
                onTap: () => setState(() => _filter = _filter.copyWith(
                    kind: _filter.kind == HistoryKind.expense ? HistoryKind.all : HistoryKind.expense)),
              ),
              const SizedBox(width: 7),
              AuroraFilterChip(
                label: '12 mois',
                selected: _filter.period == HistoryPeriod.last12Months,
                onTap: () => setState(() => _filter = _filter.copyWith(
                    period: _filter.period == HistoryPeriod.last12Months
                        ? HistoryPeriod.all
                        : HistoryPeriod.last12Months)),
              ),
              const SizedBox(width: 7),
              AuroraFilterChip(
                label: 'Cette année',
                selected: _filter.period == HistoryPeriod.thisYear,
                onTap: () => setState(() => _filter = _filter.copyWith(
                    period:
                        _filter.period == HistoryPeriod.thisYear ? HistoryPeriod.all : HistoryPeriod.thisYear)),
              ),
              for (final g in garages) ...[
                const SizedBox(width: 7),
                AuroraFilterChip(
                  label: g,
                  selected: _filter.garageName == g,
                  onTap: () => setState(
                      () => _filter = _filter.copyWith(garageName: _filter.garageName == g ? null : g)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AuroraSpacing.blockGap),
        AuroraDarkCard(
          radius: AuroraRadii.standardCard,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total sur la période',
                        style: TextStyle(color: AuroraColors.onDarkSecondary(), fontSize: 11)),
                    const SizedBox(height: 4),
                    // FittedBox rather than a fixed font size: a large
                    // total (7 figures, DA suffix) squeezed against the
                    // entry-count/monthly-average column otherwise wraps
                    // the amount onto a second line mid-currency.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(Fmt.money(total), style: AuroraText.heroMetric(AuroraColors.onDark)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(filtered.length == 1 ? '1 entrée' : '${filtered.length} entrées',
                      style: TextStyle(color: AuroraColors.onDarkSecondary(), fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('${Fmt.money(monthlyAverage)}/mois',
                      style: const TextStyle(color: AuroraColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AuroraSpacing.blockGap),
        if (historyAsync.isLoading && history.isEmpty)
          const AuroraSkeletonList()
        else if (filtered.isEmpty)
          AuroraEmptyState(
            title: history.isEmpty ? 'Aucune intervention enregistrée' : 'Aucun résultat',
            message: history.isEmpty
                ? "Ajoutez une intervention, un plein ou une dépense depuis l'ajout rapide."
                : 'Essayez une autre recherche ou réinitialisez les filtres.',
            actionLabel: history.isEmpty ? null : 'Réinitialiser les filtres',
            onAction: history.isEmpty
                ? null
                : () => setState(() {
                      _filter = const HistoryFilter();
                      _search.clear();
                    }),
          )
        else
          for (final month in grouped.keys) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_monthLabel(month), style: AuroraText.sectionLabel(aurora.textPrimary)),
                  Text(
                    Fmt.money(grouped[month]!.fold<double>(0, (s, h) => s + (h.cost ?? 0))),
                    style: AuroraText.meta(aurora.muted, size: 12, tabular: true),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < grouped[month]!.length; i++) ...[
              if (i > 0) const SizedBox(height: 9),
              _EntryRow(
                entry: grouped[month]![i],
                consumptionPer100km: consumption[grouped[month]![i].id],
                vehicleId: widget.vehicleId,
              ),
            ],
            const SizedBox(height: AuroraSpacing.blockGap),
          ],
      ],
    );
  }

  /// Number of distinct calendar months [entries] spans (at least 1 when
  /// non-empty) — the denominator for "amount / month" in the totals card.
  int _monthsSpan(List<MaintenanceHistory> entries) {
    if (entries.isEmpty) return 0;
    var min = entries.first.doneAt, max = entries.first.doneAt;
    for (final e in entries) {
      if (e.doneAt.isBefore(min)) min = e.doneAt;
      if (e.doneAt.isAfter(max)) max = e.doneAt;
    }
    return (max.year - min.year) * 12 + (max.month - min.month) + 1;
  }

  /// Newest month first, entries within a month newest first.
  Map<DateTime, List<MaintenanceHistory>> _groupByMonth(List<MaintenanceHistory> entries) {
    final sorted = [...entries]..sort((a, b) => b.doneAt.compareTo(a.doneAt));
    final map = <DateTime, List<MaintenanceHistory>>{};
    for (final e in sorted) {
      final key = DateTime(e.doneAt.year, e.doneAt.month);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: BoxDecoration(
        color: aurora.card,
        borderRadius: BorderRadius.circular(AuroraRadii.pill),
        boxShadow: aurora.useCardShadows ? AuroraShadows.cardSoft : null,
        border: aurora.useCardShadows ? null : Border.all(color: AuroraColors.darkHairlineBorder),
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsRegular.magnifyingGlass, size: 18, color: AuroraColors.iconMutedOnWhite),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AuroraText.bodyValue(aurora.textPrimary).copyWith(fontSize: 13),
              decoration: const InputDecoration.collapsed(
                hintText: 'Rechercher une entrée…',
                hintStyle: TextStyle(color: AuroraColors.iconMutedOnWhite, fontSize: 13),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Icon(PhosphorIconsRegular.x, size: 16, color: AuroraColors.iconMutedOnWhite),
            ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.consumptionPer100km, required this.vehicleId});
  final MaintenanceHistory entry;
  final double? consumptionPer100km;
  final String vehicleId;

  static PhosphorIconData _icon(MaintenanceHistory h) {
    if (h.isFuel) return PhosphorIconsFill.gasPump;
    if (h.isExpense) return auroraIconForExpenseCategory(h.category ?? ExpenseCategories.autre);
    return auroraIconForMaintenance(h.title);
  }

  @override
  Widget build(BuildContext context) {
    final meta = [
      Fmt.dayMonth(entry.doneAt),
      if (entry.km != null) Fmt.km(entry.km),
      if (consumptionPer100km != null) '${consumptionPer100km!.toStringAsFixed(1)} L/100',
    ].join(' · ');

    return AuroraListRow(
      icon: _icon(entry),
      title: entry.title,
      neutral: entry.isExpense,
      metaText: meta,
      // The spec's Ledger row only calls for the trailing amount; a
      // receipt (when present) is reachable from the entry's own edit
      // screen rather than a second trailing indicator — AuroraListRow
      // has a single trailing slot (widget XOR amount), not both at once.
      trailingText: entry.cost == null ? null : Fmt.money(entry.cost),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuroraNewEntryScreen(vehicleId: vehicleId, existing: entry),
        ),
      ),
    );
  }
}
