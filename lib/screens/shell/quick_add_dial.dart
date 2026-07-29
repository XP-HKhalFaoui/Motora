import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/maintenance_history.dart';
import '../admin_documents/add_document_sheet.dart';
import '../quick_add/add_history_sheet.dart';
import '../vehicle_detail/update_km_sheet.dart';

/// The centre FAB, expanding into the five things you can log.
///
/// Replaces the old quick-add bottom sheet: its built-in vehicle picker is
/// redundant now that the app bar carries one, and a speed dial puts the
/// five entry points one tap closer.
class QuickAddDial extends ConsumerStatefulWidget {
  const QuickAddDial({super.key, required this.vehicleId});

  /// Null when the account has no vehicle yet — the dial then does
  /// nothing rather than opening forms with nowhere to save.
  final String? vehicleId;

  @override
  ConsumerState<QuickAddDial> createState() => _QuickAddDialState();
}

class _QuickAddDialState extends ConsumerState<QuickAddDial>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  var _open = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _controller.forward() : _controller.reverse();
  }

  void _run(void Function(String vehicleId) action) {
    final id = widget.vehicleId;
    _toggle();
    if (id != null) action(id);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final actions =
        <({IconData icon, String label, Color color, VoidCallback onTap})>[
      (
        icon: Icons.speed,
        label: 'Relevé km',
        color: p.entryMileage,
        onTap: () => _run((id) => showUpdateKmSheet(context, id)),
      ),
      (
        icon: Icons.build,
        label: 'Réparation',
        color: p.entryMaintenance,
        onTap: () => _run((id) => showAddHistorySheet(context, id)),
      ),
      (
        icon: Icons.local_gas_station,
        label: 'Plein',
        color: p.entryFuel,
        onTap: () => _run((id) => showAddHistorySheet(context, id,
            defaultTitle: 'Plein / carburant', kind: HistoryEntryKind.fuel)),
      ),
      (
        icon: Icons.receipt_long,
        label: 'Dépense',
        color: p.entryExpense,
        onTap: () => _run((id) =>
            showAddHistorySheet(context, id, kind: HistoryEntryKind.expense)),
      ),
      (
        icon: Icons.document_scanner,
        label: 'Document',
        color: p.entryDocument,
        onTap: () => _run((id) => showAddDocumentSheet(context, id)),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final a in actions.reversed)
          SizeTransition(
            sizeFactor: _controller,
            axisAlignment: -1,
            child: FadeTransition(
              opacity: _controller,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DialAction(
                  icon: a.icon,
                  label: a.label,
                  color: a.color,
                  onTap: a.onTap,
                ),
              ),
            ),
          ),
        Semantics(
          button: true,
          label: _open ? 'Fermer le menu d\'ajout' : 'Ajouter une entrée',
          excludeSemantics: true,
          child: Material(
            color: p.primary,
            shape: const CircleBorder(),
            elevation: 6,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggle,
              child: SizedBox(
                width: 58,
                height: 58,
                child: AnimatedRotation(
                  turns: _open ? 0.125 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(Icons.add_rounded, size: 30, color: p.onPrimary),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DialAction extends StatelessWidget {
  const _DialAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.border),
              ),
              child: Text(label,
                  style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, size: 22, color: p.onEntryBadge),
            ),
          ],
        ),
      ),
    );
  }
}
