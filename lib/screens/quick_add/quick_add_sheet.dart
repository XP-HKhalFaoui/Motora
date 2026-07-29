import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/maintenance_history.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../admin_documents/add_document_sheet.dart';
import '../vehicle_detail/update_km_sheet.dart';
import 'add_history_sheet.dart';

/// Ajout rapide (screen 07): 2×2 grid over a dimmed background, on the
/// currently-selected vehicle.
Future<void> showQuickAddSheet(BuildContext context) {
  final p = context.palette;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.surface,
    barrierColor: Colors.black.withValues(alpha: .55),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _QuickAddSheet(),
  );
}

class _QuickAddSheet extends ConsumerStatefulWidget {
  const _QuickAddSheet();

  @override
  ConsumerState<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<_QuickAddSheet> {
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final vehicles = ref.watch(vehiclesProvider).value ?? const [];
    // Honour an explicit pick within the sheet; otherwise fall back to the
    // app-wide selection (last-opened hub, or the first vehicle).
    final fallback = ref.watch(effectiveSelectedVehicleIdProvider);
    final vehicleId = (_picked != null && vehicles.any((v) => v.id == _picked))
        ? _picked
        : fallback;
    final vehicle =
        vehicleId == null ? null : ref.watch(vehicleByIdProvider(vehicleId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: p.border, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          Text('Ajout rapide',
              style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          if (vehicle != null)
            Text.rich(
              TextSpan(
                style: TextStyle(color: p.textSecondary, fontSize: 13),
                children: [
                  const TextSpan(text: 'Sur '),
                  TextSpan(
                      text: vehicle.name,
                      style: TextStyle(
                          color: p.textPrimary, fontWeight: FontWeight.w700)),
                  TextSpan(text: ' · ${Fmt.km(vehicle.currentKm)}'),
                ],
              ),
            )
          else
            Text('Ajoutez un véhicule pour commencer.',
                style: TextStyle(color: p.textMuted, fontSize: 13)),
          // Vehicle picker — only when there's more than one car to choose.
          if (vehicles.length > 1) ...[
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final v in vehicles)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _picked = v.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: v.id == vehicleId ? p.primary : p.background,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                                color:
                                    v.id == vehicleId ? p.primary : p.border),
                          ),
                          child: Text(
                            v.name,
                            style: TextStyle(
                              color: v.id == vehicleId
                                  ? p.onPrimary
                                  : p.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (vehicleId != null)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _QuickAddTile(
                  icon: Icons.speed,
                  color: p.primary,
                  title: 'Relevé km',
                  subtitle: 'Mettre à jour',
                  onTap: () {
                    Navigator.pop(context);
                    showUpdateKmSheet(context, vehicleId);
                  },
                ),
                _QuickAddTile(
                  icon: Icons.build,
                  color: p.accent,
                  title: 'Réparation',
                  subtitle: 'Intervention + facture',
                  onTap: () {
                    Navigator.pop(context);
                    showAddHistorySheet(context, vehicleId);
                  },
                ),
                _QuickAddTile(
                  icon: Icons.document_scanner,
                  color: p.ok,
                  title: 'Document',
                  subtitle: 'Scanner un papier',
                  onTap: () {
                    Navigator.pop(context);
                    showAddDocumentSheet(context, vehicleId);
                  },
                ),
                _QuickAddTile(
                  icon: Icons.local_gas_station,
                  color: p.warn,
                  title: 'Plein',
                  subtitle: 'Carburant',
                  onTap: () {
                    Navigator.pop(context);
                    showAddHistorySheet(context, vehicleId,
                        defaultTitle: 'Plein / carburant',
                        kind: HistoryEntryKind.fuel);
                  },
                ),
                _QuickAddTile(
                  icon: Icons.receipt_long,
                  color: p.danger,
                  title: 'Dépense',
                  subtitle: 'Assurance, péage…',
                  onTap: () {
                    Navigator.pop(context);
                    showAddHistorySheet(context, vehicleId,
                        kind: HistoryEntryKind.expense);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _QuickAddTile extends StatelessWidget {
  const _QuickAddTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const Spacer(),
              Text(title,
                  style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(color: p.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
