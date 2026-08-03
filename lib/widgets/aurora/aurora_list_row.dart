import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/aurora_theme.dart';

/// The dense list row every screen reuses: an icon chip, a title with an
/// optional meta line, and an optional trailing amount (or an arbitrary
/// trailing widget — a chevron, an "Urgent"/"Régler" pill).
///
/// Two chip styles per spec: "accent" (tint13/14 fill + accent Fill icon —
/// fuel, maintenance, most rows) and "neutral" (neutralChip fill + muted
/// icon — toll/parking-style expenses, "Plaquettes de frein").
class AuroraListRow extends StatefulWidget {
  const AuroraListRow({
    super.key,
    required this.icon,
    required this.title,
    this.neutral = false,
    this.chipTint = AuroraColors.accentTint13,
    this.chipSize = 34,
    this.subtitle,
    this.metaText,
    this.trailingText,
    this.trailingSubtext,
    this.trailingWidget,
    this.dateText,
    this.radius = AuroraRadii.listRow,
    this.padding = const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    this.onTap,
  });

  final PhosphorIconData icon;
  final String title;

  /// True for non-accent categories (toll, parking) — neutralChip fill,
  /// muted icon instead of tint fill + accent icon.
  final bool neutral;
  final Color chipTint;
  final double chipSize;

  final String? subtitle;

  /// e.g. "24 juil. · 128 300 km · 6,2 L/100" — already combined by the
  /// caller, since the exact parts vary per screen.
  final String? metaText;

  /// Right-aligned amount (14/600 tabular) with an optional second line
  /// (11, muted) — e.g. consumption under a fuel entry's cost.
  final String? trailingText;
  final String? trailingSubtext;

  /// Overrides [trailingText] entirely — a chevron, a status pill, etc.
  final Widget? trailingWidget;

  final String? dateText;

  final double radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  State<AuroraListRow> createState() => _AuroraListRowState();
}

class _AuroraListRowState extends State<AuroraListRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: widget.chipSize,
          height: widget.chipSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.neutral ? AuroraColors.neutralChip : widget.chipTint,
            borderRadius: BorderRadius.circular(AuroraRadii.iconChipLarge),
          ),
          child: Icon(
            widget.icon,
            size: 17,
            color: widget.neutral ? aurora.muted : AuroraColors.accent,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AuroraText.listRowTitle(aurora.textPrimary)),
                  ),
                  if (widget.dateText != null) ...[
                    const SizedBox(width: 8),
                    Text(widget.dateText!, style: AuroraText.meta(aurora.muted)),
                  ],
                ],
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(widget.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AuroraText.meta(aurora.muted)),
              ],
              if (widget.metaText != null) ...[
                const SizedBox(height: 2),
                Text(widget.metaText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AuroraText.meta(aurora.muted)),
              ],
            ],
          ),
        ),
        if (widget.trailingWidget != null) ...[
          const SizedBox(width: 8),
          widget.trailingWidget!,
        ] else if (widget.trailingText != null) ...[
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(widget.trailingText!,
                  style: AuroraText.tabularValue(aurora.textPrimary, size: 14)),
              if (widget.trailingSubtext != null)
                Text(widget.trailingSubtext!, style: AuroraText.meta(aurora.muted, size: 11)),
            ],
          ),
        ],
      ],
    );

    // Press feedback per spec: scale to 0.985 with the shadow reduced one
    // step, 120ms. Driven by InkWell's own highlight state rather than a
    // second GestureDetector, so there's only one gesture arena.
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: aurora.card,
        borderRadius: BorderRadius.circular(widget.radius),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: widget.onTap == null
              ? null
              : (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(widget.radius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: aurora.useCardShadows
                  ? (_pressed ? AuroraShadows.filterChip : AuroraShadows.cardSoft)
                  : null,
              border: aurora.useCardShadows
                  ? null
                  : Border.all(color: AuroraColors.darkHairlineBorder),
            ),
            child: row,
          ),
        ),
      ),
    );
  }
}

/// The plain trailing chevron used on "À surveiller" rows that just open
/// a detail sheet rather than showing an amount.
class AuroraRowChevron extends StatelessWidget {
  const AuroraRowChevron({super.key});

  @override
  Widget build(BuildContext context) => Icon(
        PhosphorIconsRegular.caretRight,
        size: 16,
        color: context.aurora.iconMutedOnWhite,
      );
}
