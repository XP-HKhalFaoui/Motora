import 'package:flutter/material.dart';

import '../../core/aurora_theme.dart';

/// Ledger's independent, multi-select filter chips (type / date range /
/// garage) — distinct from [AuroraSegmentedControl], whose segments are
/// mutually exclusive.
class AuroraFilterChip extends StatelessWidget {
  const AuroraFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    // The visual pill stays at its literal compact size (padding 6×11);
    // the tap target is padded out to the 44px accessibility minimum
    // around it, invisibly — same trick as AuroraAppBarChip's 38-in-44.
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AuroraRadii.pill),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AuroraColors.ink : aurora.card,
                  borderRadius: BorderRadius.circular(AuroraRadii.pill),
                  boxShadow: selected
                      ? null
                      : (aurora.useCardShadows ? AuroraShadows.filterChip : null),
                  border: !selected && !aurora.useCardShadows
                      ? Border.all(color: AuroraColors.darkHairlineBorder)
                      : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? AuroraColors.onDark : aurora.textPrimary,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    fontFamily: AuroraText.meta(aurora.textPrimary).fontFamily,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
