import 'package:flutter/material.dart';

import '../../core/aurora_theme.dart';

/// One of the Due screen's 4-up status counters. The first ("Urgent") is
/// [filled]: accent fill, white text, accent shadow — literally "white"
/// per spec, not [AuroraColors.ink]/onDark, since at 20/600 this qualifies
/// as WCAG large text (lower contrast floor). The other three are plain
/// white cards.
class AuroraCountChip extends StatelessWidget {
  const AuroraCountChip({
    super.key,
    required this.count,
    required this.label,
    this.filled = false,
  });

  final int count;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.chipPaddingH,
        vertical: AuroraSpacing.chipPaddingV,
      ),
      decoration: BoxDecoration(
        color: filled ? AuroraColors.accent : aurora.card,
        borderRadius: BorderRadius.circular(AuroraRadii.listRow),
        boxShadow: filled
            ? AuroraShadows.accentButton
            : (aurora.useCardShadows ? AuroraShadows.cardSoft : null),
        border: !filled && !aurora.useCardShadows
            ? Border.all(color: AuroraColors.darkHairlineBorder)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: AuroraText.tabularValue(
                  filled ? Colors.white : aurora.textPrimary, size: 20)),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AuroraText.meta(
                filled ? Colors.white.withValues(alpha: .9) : aurora.muted,
                size: 9),
          ),
        ],
      ),
    );
  }
}
