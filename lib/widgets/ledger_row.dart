import 'package:flutter/material.dart';

import '../core/app_text.dart';
import '../core/theme.dart';

/// A dense timeline row: coloured type badge, title, meta line, amount.
///
/// Replaces the card-per-entry layout. Cards gave every row a border, a
/// radius and 14dp of padding, which fit about five entries on a screen;
/// this fits twice as many, and the badge tells you what each one is
/// before you read a word of it.
///
/// Shared by the history timeline, the mileage log and the fill-up list,
/// which each had their own take on the same idea.
class LedgerRow extends StatelessWidget {
  const LedgerRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.leading,
    this.subtitle,
    this.meta,
    this.trailing,
    this.trailingColor,
    this.trailingBelow,
    this.date,
    this.badges = const [],
    this.onTap,
    this.showConnector = true,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final Color color;
  final String title;

  /// Replaces the icon badge — an odometer photo, for instance, which is
  /// the evidence behind a "certifié" reading and worth keeping visible.
  final Widget? leading;

  /// Place or category, under the title.
  final String? subtitle;

  /// Odometer reading, shown with its own glyph.
  final String? meta;

  /// The amount, right-aligned.
  final String? trailing;
  final Color? trailingColor;

  /// A second right-aligned line — consumption, for instance.
  final String? trailingBelow;

  final String? date;
  final List<Widget> badges;
  final VoidCallback? onTap;

  /// The dotted line joining consecutive badges.
  final bool showConnector;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return InkWell(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 52,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  ClipOval(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: leading ??
                          Container(
                            alignment: Alignment.center,
                            color: color,
                            child: Icon(icon, size: 20, color: p.onEntryBadge),
                          ),
                    ),
                  ),
                  if (showConnector && !isLast)
                    Expanded(
                      child: _DottedLine(color: p.border),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 14, 0, 14),
                decoration: isLast
                    ? null
                    : BoxDecoration(
                        border: Border(bottom: BorderSide(color: p.border)),
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: p.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (date != null) ...[
                          const SizedBox(width: 10),
                          Text(date!,
                              style: TextStyle(
                                  color: p.textMuted, fontSize: 12.5)),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: p.textSecondary, fontSize: 12.5)),
                    ],
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (meta != null)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.speed, size: 14, color: p.textMuted),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(meta!,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: p.textSecondary,
                                          fontSize: 12.5)),
                                ),
                              ],
                            ),
                          )
                        else
                          const Spacer(),
                        if (trailing != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(trailing!,
                                  style: AppText.odometer(
                                      trailingColor ?? p.textPrimary,
                                      size: 14)),
                              if (trailingBelow != null)
                                Text(trailingBelow!,
                                    style: TextStyle(
                                        color: p.textMuted, fontSize: 11)),
                            ],
                          ),
                      ],
                    ),
                    if (badges.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 6, children: badges),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Month separator — what makes a long timeline navigable.
class LedgerMonthHeader extends StatelessWidget {
  const LedgerMonthHeader({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(52, 18, 0, 8),
      child: Text(label, style: AppText.sectionLabel(p.textSecondary)),
    );
  }
}

class _DottedLine extends StatelessWidget {
  const _DottedLine({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(2, double.infinity),
      painter: _DottedPainter(color),
    );
  }
}

class _DottedPainter extends CustomPainter {
  _DottedPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 4.0;
    const gap = 4.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + dash).clamp(0, size.height)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedPainter old) => old.color != color;
}
