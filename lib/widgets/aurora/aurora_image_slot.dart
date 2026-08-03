import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/aurora_theme.dart';

/// A receipt/scan slot: 84×100 radius-16. Either the captured image (any
/// child, typically a `StorageImage`) or the add-affordance — a 1.5px
/// dashed `accentTint45` border, `accentTint06` fill, camera icon.
class AuroraImageSlot extends StatelessWidget {
  const AuroraImageSlot({
    super.key,
    this.width = 84,
    this.height = 100,
    this.image,
    this.onTap,
    this.semanticLabel,
  });

  final double width;
  final double height;

  /// When non-null, the slot shows this instead of the add-affordance.
  final Widget? image;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final filled = image != null;
    final content = filled
        ? ClipRRect(
            borderRadius: BorderRadius.circular(AuroraRadii.imageSlot),
            child: image,
          )
        : _DashedRRect(
            radius: AuroraRadii.imageSlot,
            color: AuroraColors.accentTint45,
            strokeWidth: 1.5,
            child: Container(
              decoration: BoxDecoration(
                color: AuroraColors.accentTint06,
                borderRadius: BorderRadius.circular(AuroraRadii.imageSlot),
              ),
              alignment: Alignment.center,
              child: const Icon(PhosphorIconsRegular.camera, size: 22, color: AuroraColors.accent),
            ),
          );

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AuroraRadii.imageSlot),
        child: SizedBox(width: width, height: height, child: content),
      ),
    );
  }
}

/// The 132-high, radius-26 vehicle-photo placeholder: a diagonal gradient
/// from [AuroraColors.accentTint24] to [AuroraColors.vehiclePlaceholderEnd]
/// at 120°.
class AuroraPhotoPlaceholder extends StatelessWidget {
  const AuroraPhotoPlaceholder({
    super.key,
    this.height = 132,
    this.radius = AuroraRadii.largeCard,
  });

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        // CSS 120deg -> unit direction vector: dx = sin(120°) = 0.866,
        // dy = -cos(120°) = 0.5.
        gradient: const LinearGradient(
          begin: Alignment(-0.866, -0.5),
          end: Alignment(0.866, 0.5),
          colors: [AuroraColors.accentTint24, AuroraColors.vehiclePlaceholderEnd],
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _DashedRRect extends StatelessWidget {
  const _DashedRRect({
    required this.radius,
    required this.color,
    required this.strokeWidth,
    required this.child,
  });

  final double radius;
  final Color color;
  final double strokeWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(radius: radius, color: color, strokeWidth: strokeWidth),
      child: child,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.radius, required this.color, required this.strokeWidth});

  final double radius;
  final Color color;
  final double strokeWidth;

  static const _dash = 5.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius || old.strokeWidth != strokeWidth;
}
