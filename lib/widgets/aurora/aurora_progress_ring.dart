import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/aurora_theme.dart';

/// The 72×72 progress ring on Home's next-due card: stroke 7, track
/// [AuroraColors.accentTint16], progress [AuroraColors.accent], round
/// caps, starting at 12 o'clock and sweeping clockwise.
///
/// Deliberately static — the spec's "animate 0 → target over 700ms
/// easeOutCubic on first appearance only" is a behavior-pass concern
/// (step 5); this widget just draws a given [progress].
class AuroraProgressRing extends StatelessWidget {
  const AuroraProgressRing({
    super.key,
    required this.progress,
    required this.value,
    required this.unit,
    this.size = 72,
    this.stroke = 7,
  });

  /// 0..1.
  final double progress;

  /// Centered number, e.g. "11".
  final String value;

  /// Centered unit below the number, e.g. "jours".
  final String unit;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          track: AuroraColors.accentTint16,
          color: AuroraColors.accent,
          stroke: stroke,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: AuroraText.cardTitle(aurora.textPrimary, size: 17)),
              Text(unit, style: AuroraText.meta(aurora.muted, size: 9)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.color,
    required this.stroke,
  });

  final double progress;
  final Color track;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.track != track || old.color != color || old.stroke != stroke;
}
