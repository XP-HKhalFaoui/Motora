import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/aurora_theme.dart';

class AuroraSegment<T> {
  const AuroraSegment({required this.value, required this.label, this.icon});
  final T value;
  final String label;
  final PhosphorIconData? icon;
}

/// The pill segmented control: white pill container, equal segments.
///
/// Two selected-fill conventions coexist in the spec for the same widget
/// shape — Due's 3-way filter selects with fill [AuroraColors.ink] / text
/// onDark, while New-entry's type selector selects with fill
/// [AuroraColors.accent] / text ink. Both are literal, so the colors are
/// parameters rather than a single hardcoded convention.
class AuroraSegmentedControl<T> extends StatelessWidget {
  const AuroraSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.selectedFill = AuroraColors.ink,
    this.selectedText = AuroraColors.onDark,
    this.fontSize = 13,
  });

  final List<AuroraSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final Color selectedFill;
  final Color selectedText;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: aurora.card,
        borderRadius: BorderRadius.circular(AuroraRadii.pill),
        boxShadow: aurora.useCardShadows ? AuroraShadows.cardSoft : null,
        border: aurora.useCardShadows
            ? null
            : Border.all(color: AuroraColors.darkHairlineBorder),
      ),
      child: Row(
        children: [
          for (final s in segments)
            Expanded(
              child: _Segment(
                segment: s,
                selected: s.value == value,
                selectedFill: selectedFill,
                selectedText: selectedText,
                fontSize: fontSize,
                onTap: () => onChanged(s.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.selected,
    required this.selectedFill,
    required this.selectedText,
    required this.fontSize,
    required this.onTap,
  });

  final AuroraSegment<T> segment;
  final bool selected;
  final Color selectedFill;
  final Color selectedText;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    final textColor = selected ? selectedText : aurora.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: segment.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AuroraRadii.pill),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 9),
          // The segment's own fill doubles as its tap target (unlike a
          // standalone filter chip, there's no separate "visual" to keep
          // compact around), so the accessibility minimum grows the
          // whole segment rather than an invisible zone around it.
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: selected ? selectedFill : Colors.transparent,
            borderRadius: BorderRadius.circular(AuroraRadii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (segment.icon != null) ...[
                Icon(segment.icon,
                    size: fontSize + 2,
                    color: textColor),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  segment.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    fontFamily: AuroraText.bodyValue(textColor).fontFamily,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
