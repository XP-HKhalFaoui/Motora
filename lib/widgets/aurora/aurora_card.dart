import 'package:flutter/material.dart';

import '../../core/aurora_theme.dart';

/// The soft white card: fill [AuroraPalette.card], soft or raised shadow
/// in light mode, a 1px hairline border instead in dark mode (stock
/// Nocturne drops shadows for depth-via-border).
class AuroraCard extends StatelessWidget {
  const AuroraCard({
    super.key,
    required this.child,
    this.radius = AuroraRadii.standardCard,
    this.padding = const EdgeInsets.all(AuroraSpacing.cardPaddingLarge),
    this.raised = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// false = "card soft" shadow (list rows, most cards); true = "card
  /// raised" (next-due card, field card, mileage/reports cards).
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: aurora.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: aurora.useCardShadows
            ? (raised ? AuroraShadows.cardRaised : AuroraShadows.cardSoft)
            : null,
        border: aurora.useCardShadows
            ? null
            : Border.all(color: AuroraColors.darkHairlineBorder),
      ),
      child: child,
    );
  }
}

/// The dark hero card — fill [AuroraColors.ink] in light mode (the "dark
/// card" that sits inside an otherwise-light screen: Due's urgent card,
/// Ledger's totals card). In dark mode the whole ground is already ink,
/// so this collapses onto the regular card tone per the spec's inversion
/// recipe — there is no separate "extra dark" tone in stock Nocturne.
class AuroraDarkCard extends StatelessWidget {
  const AuroraDarkCard({
    super.key,
    required this.child,
    this.radius = AuroraRadii.largeCard,
    this.padding = const EdgeInsets.all(AuroraSpacing.cardPaddingLarge),
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: aurora.heroCardFill,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: aurora.useCardShadows ? AuroraShadows.darkCard : null,
        border: aurora.useCardShadows
            ? null
            : Border.all(color: AuroraColors.darkHairlineBorder),
      ),
      child: child,
    );
  }
}
