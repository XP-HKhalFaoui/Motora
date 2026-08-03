import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/aurora_theme.dart';

enum AuroraNavTab { home, due, ledger, reports }

/// The floating pill nav bar: `left:18, right:18, bottom:18`, height 64,
/// radius 32, fill ink, dark-card shadow. Four equal slots, no labels.
/// Active tab is a 44×44 accent circle with a Fill icon in ink; inactive
/// icons are regular weight at `onDark @ 55%`. The circle slides to the
/// newly-active slot in 220ms easeOutCubic, per spec.
///
/// Positioned, so it must be used as a child of a [Stack] over the
/// screen's scrollable body — never as a `Scaffold.bottomNavigationBar`
/// (the spec's bar floats over content, it doesn't push it up).
class AuroraFloatingNav extends StatelessWidget {
  const AuroraFloatingNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final AuroraNavTab current;
  final ValueChanged<AuroraNavTab> onSelect;

  static const _tabs = [
    (tab: AuroraNavTab.home, label: 'Accueil'),
    (tab: AuroraNavTab.due, label: 'Échéances'),
    (tab: AuroraNavTab.ledger, label: 'Journal'),
    (tab: AuroraNavTab.reports, label: 'Rapports'),
  ];

  static const _circleSize = 44.0;
  static const _barHeight = 64.0;

  static PhosphorIconData _icon(AuroraNavTab tab, bool active) {
    final style = active ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular;
    return switch (tab) {
      AuroraNavTab.home => PhosphorIcons.house(style),
      AuroraNavTab.due => PhosphorIcons.bellRinging(style),
      AuroraNavTab.ledger => PhosphorIcons.receipt(style),
      AuroraNavTab.reports => PhosphorIcons.chartLine(style),
    };
  }

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    final activeIndex = _tabs.indexWhere((t) => t.tab == current);

    return Positioned(
      left: 18,
      right: 18,
      bottom: 18,
      child: Container(
        height: _barHeight,
        decoration: BoxDecoration(
          color: aurora.heroCardFill,
          borderRadius: BorderRadius.circular(32),
          boxShadow: aurora.useCardShadows ? AuroraShadows.darkCard : null,
          border: aurora.useCardShadows
              ? null
              : Border.all(color: AuroraColors.darkHairlineBorder),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slotWidth = constraints.maxWidth / _tabs.length;
            return Stack(
              children: [
                // The sliding accent circle — pixel-positioned rather than
                // via Alignment, since Alignment(-1..1) maps to the whole
                // bar's edges, not to each slot's own centre.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: slotWidth * activeIndex + (slotWidth - _circleSize) / 2,
                  top: (_barHeight - _circleSize) / 2,
                  width: _circleSize,
                  height: _circleSize,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(color: AuroraColors.accent, shape: BoxShape.circle),
                  ),
                ),
                Row(
                  children: [
                    for (final t in _tabs)
                      Expanded(
                        child: _NavItem(
                          icon: _icon(t.tab, t.tab == current),
                          active: t.tab == current,
                          label: t.label,
                          onTap: () => onSelect(t.tab),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.active,
    required this.label,
    required this.onTap,
  });

  final PhosphorIconData icon;
  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Icon(
            icon,
            size: active ? 20 : 21,
            color: active ? AuroraColors.ink : AuroraColors.onDarkInactiveIcon(),
          ),
        ),
      ),
    );
  }
}
