import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/maintenance_history.dart';
import '../admin_documents/add_document_sheet.dart';
import '../quick_add/add_history_sheet.dart';
import '../vehicle_detail/update_km_sheet.dart';

/// One thing you can log from the centre FAB.
class QuickAddAction {
  const QuickAddAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.open,
  });

  final IconData icon;
  final String label;
  final Color color;
  final void Function(BuildContext context, String vehicleId) open;
}

List<QuickAddAction> quickAddActions(AppPalette p) => [
      QuickAddAction(
        icon: Icons.speed,
        label: 'Relevé km',
        color: p.entryMileage,
        open: showUpdateKmSheet,
      ),
      QuickAddAction(
        icon: Icons.build,
        label: 'Réparation',
        color: p.entryMaintenance,
        open: (context, id) => showAddHistorySheet(context, id),
      ),
      QuickAddAction(
        icon: Icons.local_gas_station,
        label: 'Plein',
        color: p.entryFuel,
        open: (context, id) => showAddHistorySheet(context, id,
            defaultTitle: 'Plein / carburant', kind: HistoryEntryKind.fuel),
      ),
      QuickAddAction(
        icon: Icons.receipt_long,
        label: 'Dépense',
        color: p.entryExpense,
        open: (context, id) =>
            showAddHistorySheet(context, id, kind: HistoryEntryKind.expense),
      ),
      QuickAddAction(
        icon: Icons.document_scanner,
        label: 'Document',
        color: p.entryDocument,
        open: showAddDocumentSheet,
      ),
    ];

/// The round centre button, and nothing else.
///
/// The expanded actions deliberately live in an overlay rather than
/// inside this widget: a Column takes the full width available on its
/// cross axis, so a dial built as the Scaffold's floatingActionButton
/// ended up as a full-width box — and centerDocked centring a full-width
/// box leaves the button wherever its alignment put it, which was hard
/// against the right edge, on top of the "Plus" label.
class QuickAddFab extends StatelessWidget {
  const QuickAddFab({super.key, required this.open, required this.onToggle});

  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: open ? "Fermer le menu d'ajout" : 'Ajouter une entrée',
      excludeSemantics: true,
      child: Material(
        color: p.primary,
        shape: const CircleBorder(),
        elevation: 6,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onToggle,
          child: SizedBox(
            width: 58,
            height: 58,
            child: AnimatedRotation(
              turns: open ? 0.125 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(Icons.add_rounded, size: 30, color: p.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// The expanded actions, shown over the body while the dial is open.
class QuickAddOverlay extends ConsumerWidget {
  const QuickAddOverlay({
    super.key,
    required this.vehicleId,
    required this.onClose,
  });

  final String? vehicleId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final actions = quickAddActions(p);

    return Stack(
      children: [
        // Tapping anywhere else closes, which is what a dial should do.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: ColoredBox(color: p.background.withValues(alpha: .82)),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final a in actions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _DialAction(
                    action: a,
                    onTap: () {
                      onClose();
                      final id = vehicleId;
                      if (id != null) a.open(context, id);
                    },
                  ),
                ),
              // Clears the FAB itself.
              const SizedBox(height: 58),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialAction extends StatelessWidget {
  const _DialAction({required this.action, required this.onTap});

  final QuickAddAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.border),
              ),
              child: Text(action.label,
                  style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: action.color, shape: BoxShape.circle),
              child: Icon(action.icon, size: 22, color: p.onEntryBadge),
            ),
          ],
        ),
      ),
    );
  }
}
