import 'package:flutter/material.dart';

/// Animates a 0..1 factor from 0 to 1 exactly once, over 700ms
/// easeOutCubic, then holds at 1 forever — never replaying on rebuild.
///
/// Multiply [builder]'s `factor` against whatever progress value you have
/// *at the time of building* (not a value captured once): while the
/// factor is ramping, the displayed progress ramps with it; once the
/// factor reaches 1, later changes to your progress value show
/// immediately with no animation, which is exactly the spec's "animate
/// 0 → target over 700ms easeOutCubic on first appearance only; never on
/// rebuild" rule for the progress ring and Due's progress bar.
class AuroraAnimateOnce extends StatefulWidget {
  const AuroraAnimateOnce({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 700),
  });

  final Widget Function(BuildContext context, double factor) builder;

  /// 700ms matches the progress ring/bar; charts use 600ms.
  final Duration duration;

  @override
  State<AuroraAnimateOnce> createState() => _AuroraAnimateOnceState();
}

class _AuroraAnimateOnceState extends State<AuroraAnimateOnce> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();
  late final Animation<double> _factor = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _factor,
      builder: (context, _) => widget.builder(context, _factor.value),
    );
  }
}
