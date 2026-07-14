import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Diagonal-stripe placeholder used wherever a real photo/scan isn't
/// available yet (vehicle photos, document thumbnails, onboarding
/// illustration) — see PROMPT-claude-code.md §5.
class StripedPlaceholder extends StatelessWidget {
  const StripedPlaceholder({
    super.key,
    this.borderRadius = 0,
    this.label,
    this.icon,
  });

  final double borderRadius;
  final String? label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CustomPaint(
        painter: _StripePainter(base: p.surface, alt: p.surfaceElevated),
        child: Center(
          child: icon != null
              ? Icon(icon, color: p.textMuted, size: 26)
              : label != null
                  ? Text(
                      label!,
                      style: TextStyle(
                        color: p.textMuted,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    )
                  : null,
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  _StripePainter({required this.base, required this.alt});
  final Color base;
  final Color alt;

  static const _stripe = 9.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final paint = Paint()..color = alt;
    final path = Path();
    final span = size.width + size.height;
    for (double x = -size.height; x < span; x += _stripe * 2) {
      path.moveTo(x, 0);
      path.lineTo(x + _stripe, 0);
      path.lineTo(x + _stripe + size.height, size.height);
      path.lineTo(x + size.height, size.height);
      path.close();
    }
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StripePainter oldDelegate) =>
      oldDelegate.base != base || oldDelegate.alt != alt;
}
