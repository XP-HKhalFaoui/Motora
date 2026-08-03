import 'package:flutter/material.dart';

import '../../core/aurora_theme.dart';

/// A moving highlight sweep, per spec: "shimmer the card silhouettes at
/// their real radii (`#F0EEFA` → `#F8F8FD`), never a centred spinner over
/// an empty screen."
class AuroraShimmer extends StatefulWidget {
  const AuroraShimmer({super.key, required this.child});
  final Widget child;

  @override
  State<AuroraShimmer> createState() => _AuroraShimmerState();
}

class _AuroraShimmerState extends State<AuroraShimmer> with SingleTickerProviderStateMixin {
  late final _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dx = _controller.value * 3 - 1.5;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1 + dx, 0),
            end: Alignment(1 + dx, 0),
            colors: const [
              AuroraColors.accentTint14,
              AuroraColors.bgTop,
              AuroraColors.accentTint14,
            ],
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single shimmering placeholder shaped like a real card — same radius,
/// no other detail.
class AuroraSkeletonCard extends StatelessWidget {
  const AuroraSkeletonCard({
    super.key,
    this.height = 74,
    this.radius = AuroraRadii.listRow,
  });

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AuroraShimmer(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AuroraColors.accentTint14,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// A vertical stack of [AuroraSkeletonCard]s — the whole-list loading
/// silhouette.
class AuroraSkeletonList extends StatelessWidget {
  const AuroraSkeletonList({super.key, this.count = 4, this.height = 74, this.gap = 9});

  final int count;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) SizedBox(height: gap),
          AuroraSkeletonCard(height: height),
        ],
      ],
    );
  }
}
