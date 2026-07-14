import 'package:flutter/material.dart';

import '../core/theme.dart';

/// The 4-destination bottom bar with a center notch for the FAB, per
/// PROMPT-claude-code.md §5 "Chrome Android": Accueil · Entretien ·
/// [notch] · Docs · Alertes.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showAlertBadge = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showAlertBadge;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Accueil'),
    (icon: Icons.build_rounded, label: 'Entretien'),
    (icon: Icons.description_rounded, label: 'Docs'),
    (icon: Icons.notifications_rounded, label: 'Alertes'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 80,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 0),
      decoration: BoxDecoration(
        color: p.navBar,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          _navItem(context, 0),
          _navItem(context, 1),
          const Expanded(child: SizedBox()), // notch for the FAB
          _navItem(context, 2),
          _navItem(context, 3, badge: showAlertBadge),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, {bool badge = false}) {
    final p = context.palette;
    final item = _items[index];
    final active = index == currentIndex;
    final color = active ? p.primary : p.textMuted;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(item.icon, size: 24, color: color),
                if (badge)
                  Positioned(
                    top: -2,
                    right: -6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.danger,
                        border: Border.all(color: p.navBar, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
