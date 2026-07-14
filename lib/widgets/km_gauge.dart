import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_text.dart';
import '../core/theme.dart';

/// Circular km gauge (screen 03 "Détail véhicule"): conic-gradient ring,
/// value + monthly average centered inside, per PROMPT-claude-code.md §5
/// ("anneau circulaire (conic gradient, ~206px)").
class KmGauge extends StatelessWidget {
  const KmGauge({
    super.key,
    required this.currentKm,
    this.subtitle,
    this.size = 206,
    this.progress = 0.62,
  });

  final int currentKm;
  final String? subtitle;
  final double size;

  /// Fraction (0..1) of the ring drawn in the primary color; decorative,
  /// mirrors the fixed ~62% sweep in the design mock.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(
          primary: p.primary,
          track: p.surfaceElevated,
          progress: progress.clamp(0.0, 1.0),
        ),
        child: Center(
          child: Container(
            width: size * .815,
            height: size * .815,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.background,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('KILOMÉTRAGE',
                    style: AppText.sectionLabel(p.textSecondary, size: 11)),
                const SizedBox(height: 4),
                Text(
                  _formatKm(currentKm),
                  style: AppText.odometer(p.textPrimary, size: 32),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: p.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatKm(int km) {
    final s = km.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.primary,
    required this.track,
    required this.progress,
  });

  final Color primary;
  final Color track;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    const start = -math.pi / 2;
    final sweep = math.pi * 2 * progress;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .085;
    final progressPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .085;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - trackPaint.strokeWidth / 2),
        0, math.pi * 2, false, trackPaint);
    if (progress > 0) {
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - progressPaint.strokeWidth / 2),
          start,
          sweep,
          false,
          progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.track != track ||
      oldDelegate.progress != progress;
}
