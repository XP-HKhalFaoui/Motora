import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/aurora_theme.dart';

/// The 38×38 rounded-14 white icon chip used in every screen's app-bar row
/// (car-profile, bell, sliders, funnel, export, close). Sits inside a
/// 44×44 tap target per the accessibility pass.
class AuroraAppBarChip extends StatelessWidget {
  const AuroraAppBarChip({
    super.key,
    required this.icon,
    this.onTap,
    required this.semanticLabel,
    this.iconColor,
    this.showDot = false,
  });

  final PhosphorIconData icon;

  /// Null for a purely decorative chip (e.g. Home's leading car-profile
  /// icon, which the spec never assigns a tap behavior to).
  final VoidCallback? onTap;
  final String semanticLabel;
  final Color? iconColor;

  /// The 7px accent dot with a 2px ring — e.g. unread reminders on the
  /// bell chip.
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: aurora.card,
                      borderRadius: BorderRadius.circular(AuroraRadii.iconChipLarge),
                      boxShadow: aurora.useCardShadows ? AuroraShadows.cardSoft : null,
                      border: aurora.useCardShadows
                          ? null
                          : Border.all(color: AuroraColors.darkHairlineBorder),
                    ),
                    child: Icon(icon, size: 19, color: iconColor ?? AuroraColors.accent),
                  ),
                  if (showDot)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AuroraColors.accent,
                          border: Border.all(color: aurora.card, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
