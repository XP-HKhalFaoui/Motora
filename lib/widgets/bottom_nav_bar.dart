import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../providers/shell_provider.dart';

/// The four-destination bottom bar with a centre notch for the FAB, per
/// PROMPT-claude-code.md §5 "Chrome Android".
///
/// This existed before, was deleted when the app moved to a per-vehicle
/// hub, and comes back with the Drivvo-style redesign — which is really a
/// return to what the design spec asked for.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.current,
    required this.onSelect,
    this.dueBadge = false,
  });

  final ShellTab current;
  final ValueChanged<ShellTab> onSelect;

  /// Red dot on Échéances when something needs attention.
  final bool dueBadge;

  static const _left = [
    (
      tab: ShellTab.vehicle,
      icon: Icons.directions_car_rounded,
      label: 'Véhicule'
    ),
    (
      tab: ShellTab.history,
      icon: Icons.receipt_long_rounded,
      label: 'Historique'
    ),
  ];
  static const _right = [
    (tab: ShellTab.due, icon: Icons.notifications_rounded, label: 'Échéances'),
    (tab: ShellTab.more, icon: Icons.more_horiz_rounded, label: 'Plus'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.navBar,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (final item in _left) Expanded(child: _item(context, item)),
              // Notch for the FAB.
              const SizedBox(width: 72),
              for (final item in _right)
                Expanded(
                  child: _item(context, item,
                      badge: item.tab == ShellTab.due && dueBadge),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    ({ShellTab tab, IconData icon, String label}) item, {
    bool badge = false,
  }) {
    final p = context.palette;
    final active = item.tab == current;
    final color = active ? p.primary : p.textMuted;

    return Semantics(
      button: true,
      selected: active,
      label: badge ? '${item.label}, échéances en attente' : item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onSelect(item.tab),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(item.icon, size: 22, color: color),
                if (badge)
                  Positioned(
                    top: -2,
                    right: -3,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.danger,
                        border: Border.all(color: p.navBar, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
