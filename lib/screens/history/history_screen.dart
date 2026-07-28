import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_text.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/maintenance_history.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/fuel_service.dart';
import '../../widgets/async_value_view.dart';
import '../quick_add/add_history_sheet.dart';

/// Historique réparations (screen 05): 2 stats + vertical timeline.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key, required this.vehicleId});
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final vehicle = ref.watch(vehicleByIdProvider(vehicleId));
    final historyAsync = ref.watch(maintenanceHistoryProvider(vehicleId));

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: p.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text('Historique · ${vehicle?.name ?? ''}',
                      overflow: TextOverflow.ellipsis,
                      style: AppText.screenTitle(p.textPrimary, size: 20)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AsyncValueView(
              value: historyAsync,
              onRetry: () =>
                  ref.invalidate(maintenanceHistoryProvider(vehicleId)),
              data: (history) => _Body(vehicleId: vehicleId, history: history),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.vehicleId, required this.history});
  final String vehicleId;
  final List<MaintenanceHistory> history;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final yearAgo = DateTime.now().subtract(const Duration(days: 365));
    final last12mo = history.where((h) => h.doneAt.isAfter(yearAgo));
    final total = last12mo.fold<double>(0, (s, h) => s + (h.cost ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child:
                  _StatTile(value: Fmt.money(total), label: '12 derniers mois'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child:
                  _StatTile(value: '${history.length}', label: 'interventions'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
                child: Text('Aucune intervention enregistrée.',
                    style: TextStyle(color: p.textMuted))),
          )
        else
          _Timeline(vehicleId: vehicleId, history: history),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.vehicleId, required this.history});
  final String vehicleId;
  final List<MaintenanceHistory> history;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final consumption = FuelService.consumptionByEntryId(history);
    return Padding(
      padding: const EdgeInsets.only(left: 26),
      child: Stack(
        children: [
          Positioned(
            left: -20,
            top: 6,
            bottom: 6,
            child: Container(width: 2, color: p.border),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: history.asMap().entries.map((entry) {
              final i = entry.key;
              final h = entry.value;
              return Padding(
                padding:
                    EdgeInsets.only(bottom: i == history.length - 1 ? 0 : 16),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: -26,
                      top: 6,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0 ? p.primary : p.surfaceElevated,
                          border: Border.all(color: p.background, width: 3),
                        ),
                      ),
                    ),
                    _HistoryCard(
                      vehicleId: vehicleId,
                      h: h,
                      consumptionPer100km: consumption[h.id],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard(
      {required this.vehicleId, required this.h, this.consumptionPer100km});
  final String vehicleId;
  final MaintenanceHistory h;
  final double? consumptionPer100km;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showAddHistorySheet(context, vehicleId, existing: h),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: p.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (h.isFuel) ...[
                    Icon(Icons.local_gas_station, size: 18, color: p.warn),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.title,
                            style: TextStyle(
                                color: p.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(
                          [
                            Fmt.date(h.doneAt),
                            if (h.km != null) Fmt.km(h.km),
                          ].whereType<String>().join(' · '),
                          style:
                              TextStyle(color: p.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (h.cost != null)
                    Text(Fmt.money(h.cost),
                        style: AppText.odometer(p.primary, size: 16)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (h.garageName != null)
                    _Chip(
                        icon: Icons.store,
                        label: h.garageName!,
                        color: p.textSecondary),
                  if (h.invoiceUrl != null)
                    _Chip(
                        icon: Icons.receipt_long,
                        label: 'Facture',
                        color: p.ok),
                  if (h.liters != null)
                    _Chip(
                        icon: Icons.local_gas_station,
                        label: '${h.liters!.toStringAsFixed(1)} L',
                        color: p.warn),
                  if (consumptionPer100km != null)
                    _Chip(
                        icon: Icons.speed,
                        label:
                            '${consumptionPer100km!.toStringAsFixed(1)} L/100km',
                        color: p.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
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
