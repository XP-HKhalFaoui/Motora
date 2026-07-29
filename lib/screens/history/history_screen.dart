import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_text.dart';
import '../../core/constants.dart';
import '../../core/entry_style.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/maintenance_history.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/fuel_service.dart';
import '../../services/history_filter.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/ledger_row.dart';
import '../files/file_viewer_screen.dart';
import '../quick_add/add_history_sheet.dart';

/// Historique réparations (screen 05): search + filters over a vertical
/// timeline of every intervention and fill-up.
///
/// The list is a SliverList.builder: it used to build every card eagerly
/// through `children: history.map(...)`, which after a few years of
/// fill-ups means hundreds of widgets constructed to show ten.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({
    super.key,
    required this.vehicleId,
    this.embedded = false,
  });

  final String vehicleId;

  /// True when shown as a bottom-bar tab: the shell already supplies the
  /// app bar and there is nothing to go back to.
  final bool embedded;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _search = TextEditingController();
  var _filter = const HistoryFilter();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final vehicle = ref.watch(vehicleByIdProvider(widget.vehicleId));
    final historyAsync =
        ref.watch(maintenanceHistoryProvider(widget.vehicleId));

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => AsyncValueView(
            value: historyAsync,
            onRetry: () =>
                ref.invalidate(maintenanceHistoryProvider(widget.vehicleId)),
            data: (_) => const SizedBox(),
          ),
          data: (history) {
            final filtered = _filter.apply(history);
            final garages = history
                .map((h) => h.garageName)
                .whereType<String>()
                .toSet()
                .toList()
              ..sort();
            final consumption = FuelService.consumptionByEntryId(history);
            final total = filtered.fold<double>(0, (s, h) => s + (h.cost ?? 0));
            final rows = _flatten(filtered);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!widget.embedded) ...[
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back,
                                    color: p.textSecondary),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Expanded(
                                child: Text(
                                    'Historique · ${vehicle?.name ?? ''}',
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.screenTitle(p.textPrimary,
                                        size: 20)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                        _SearchField(
                          controller: _search,
                          onChanged: (v) => setState(
                              () => _filter = _filter.copyWith(query: v)),
                        ),
                        const SizedBox(height: 12),
                        _Filters(
                          filter: _filter,
                          garages: garages,
                          onChanged: (f) => setState(() => _filter = f),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatTile(
                                value: Fmt.money(total),
                                label: _filter.isEmpty
                                    ? 'coût total'
                                    : 'coût filtré',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatTile(
                                value: '${filtered.length}',
                                label:
                                    filtered.length == 1 ? 'entrée' : 'entrées',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: EmptyState(
                        icon: history.isEmpty
                            ? Icons.build_outlined
                            : Icons.search_off,
                        message: history.isEmpty
                            ? 'Aucune intervention enregistrée.'
                            : 'Aucun résultat pour cette recherche.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 20, 32),
                    sliver: SliverList.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, i) {
                        final row = rows[i];
                        if (row.header != null) {
                          return LedgerMonthHeader(label: row.header!);
                        }
                        return _EntryRow(
                          vehicleId: widget.vehicleId,
                          entry: row.entry!,
                          consumptionPer100km: consumption[row.entry!.id],
                          isLast: i == rows.length - 1,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A timeline item: either a month header or an entry. Flattening the two
/// into one list keeps the SliverList lazy — grouping into nested lists
/// would have meant building every month up front.
class _Row {
  const _Row.header(String this.header) : entry = null;
  const _Row.entry(MaintenanceHistory this.entry) : header = null;

  final String? header;
  final MaintenanceHistory? entry;
}

List<_Row> _flatten(List<MaintenanceHistory> entries) {
  final rows = <_Row>[];
  DateTime? currentMonth;
  for (final e in entries) {
    final month = DateTime(e.doneAt.year, e.doneAt.month);
    if (currentMonth == null || month != currentMonth) {
      rows.add(_Row.header(Fmt.monthHeader(month)));
      currentMonth = month;
    }
    rows.add(_Row.entry(e));
  }
  return rows;
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: p.textPrimary),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Rechercher une intervention, un garage…',
        prefixIcon: Icon(Icons.search, color: p.textMuted, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Effacer',
                icon: Icon(Icons.close, color: p.textMuted, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.filter,
    required this.garages,
    required this.onChanged,
  });

  final HistoryFilter filter;
  final List<String> garages;
  final ValueChanged<HistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _Pill(
            label: 'Entretien',
            selected: filter.kind == HistoryKind.maintenance,
            onTap: () => onChanged(filter.copyWith(
              kind: filter.kind == HistoryKind.maintenance
                  ? HistoryKind.all
                  : HistoryKind.maintenance,
            )),
          ),
          _Pill(
            label: 'Carburant',
            selected: filter.kind == HistoryKind.fuel,
            onTap: () => onChanged(filter.copyWith(
              kind: filter.kind == HistoryKind.fuel
                  ? HistoryKind.all
                  : HistoryKind.fuel,
            )),
          ),
          _Pill(
            label: 'Dépenses',
            selected: filter.kind == HistoryKind.expense,
            onTap: () => onChanged(filter.copyWith(
              kind: filter.kind == HistoryKind.expense
                  ? HistoryKind.all
                  : HistoryKind.expense,
            )),
          ),
          _Pill(
            label: '12 mois',
            selected: filter.period == HistoryPeriod.last12Months,
            onTap: () => onChanged(filter.copyWith(
              period: filter.period == HistoryPeriod.last12Months
                  ? HistoryPeriod.all
                  : HistoryPeriod.last12Months,
            )),
          ),
          _Pill(
            label: 'Cette année',
            selected: filter.period == HistoryPeriod.thisYear,
            onTap: () => onChanged(filter.copyWith(
              period: filter.period == HistoryPeriod.thisYear
                  ? HistoryPeriod.all
                  : HistoryPeriod.thisYear,
            )),
          ),
          for (final garage in garages)
            _Pill(
              label: garage,
              selected: filter.garageName == garage,
              onTap: () => onChanged(filter.copyWith(
                garageName: filter.garageName == garage ? null : garage,
              )),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? p.primary : p.surface,
        borderRadius: BorderRadius.circular(99),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(color: selected ? p.primary : p.border),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(label,
                style: TextStyle(
                    color: selected ? p.onPrimary : p.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

/// One entry, as a dense ledger row.
class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.vehicleId,
    required this.entry,
    required this.isLast,
    this.consumptionPer100km,
  });

  final String vehicleId;
  final MaintenanceHistory entry;
  final bool isLast;
  final double? consumptionPer100km;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = entryStyleFor(p, entry);

    final subtitle = [
      if (entry.isExpense && entry.category != null)
        ExpenseCategories.label(entry.category!),
      if (entry.garageName != null) entry.garageName!,
    ].join(' · ');

    return LedgerRow(
      icon: style.icon,
      color: style.color,
      title: entry.title,
      subtitle: subtitle.isEmpty ? null : subtitle,
      meta: entry.km == null ? null : Fmt.km(entry.km),
      date: Fmt.dayMonth(entry.doneAt),
      trailing: entry.cost == null ? null : Fmt.money(entry.cost),
      trailingColor: p.textPrimary,
      trailingBelow: consumptionPer100km == null
          ? null
          : '${consumptionPer100km!.toStringAsFixed(1)} L/100km',
      isLast: isLast,
      onTap: () => showAddHistorySheet(context, vehicleId, existing: entry),
      badges: [
        if (entry.liters != null)
          _Chip(
              icon: Icons.local_gas_station,
              label: '${entry.liters!.toStringAsFixed(1)} L'
                  '${entry.isFullTank ? '' : ' (appoint)'}',
              color: p.entryFuel),
        if (entry.invoiceUrl != null)
          _Chip(
            icon: Icons.receipt_long,
            label: 'Facture',
            color: p.ok,
            onTap: () => FileViewerScreen.open(
              context,
              bucket: Buckets.invoices,
              reference: entry.invoiceUrl!,
              title: entry.title,
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final body = Padding(
      padding:
          EdgeInsets.symmetric(horizontal: 9, vertical: onTap == null ? 5 : 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          if (onTap != null) ...[
            const SizedBox(width: 3),
            Icon(Icons.chevron_right, size: 14, color: color),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return Container(
        decoration: BoxDecoration(
          color: p.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: body,
      );
    }
    return Material(
      color: p.background,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: body),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.screenTitle(p.textPrimary, size: 20)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: p.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
