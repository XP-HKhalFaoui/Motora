import 'package:flutter/material.dart';

import '../../core/aurora_theme.dart';

/// The round quick-add trigger button.
///
/// Used to open a fanned-out dial of actions (now retired — the Aurora
/// redesign's quick-add is a modal sheet, see
/// `widgets/aurora/aurora_quick_add_sheet.dart`); the FAB itself is
/// reused as-is per the design spec's own allowance ("a FAB is acceptable
/// if the codebase already has one"), restyled to Aurora's accent fill /
/// ink glyph convention (same pairing as `AuroraPrimaryButton`) — this is
/// now exclusively an Aurora-context widget, so the legacy teal palette
/// no longer belongs here.
class QuickAddFab extends StatelessWidget {
  const QuickAddFab({super.key, required this.open, required this.onToggle});

  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: open ? "Fermer le menu d'ajout" : 'Ajouter une entrée',
      excludeSemantics: true,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AuroraShadows.accentButton,
        ),
        child: Material(
          color: AuroraColors.accent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onToggle,
            child: SizedBox(
              width: 58,
              height: 58,
              child: AnimatedRotation(
                turns: open ? 0.125 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(Icons.add_rounded, size: 30, color: AuroraColors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
