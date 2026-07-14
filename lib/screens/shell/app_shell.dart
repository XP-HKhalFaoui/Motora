import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../admin_documents/documents_screen.dart';
import '../home/home_screen.dart';
import '../maintenance/maintenance_screen.dart';
import '../notifications/notifications_screen.dart';
import '../quick_add/quick_add_sheet.dart';

/// Top-level shell: Accueil / Entretien / Docs / Alertes behind a bottom
/// nav with a center FAB (Ajout rapide), per §5 "Chrome Android". Vehicle
/// detail, history and settings are pushed on top of this, not part of it.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    MaintenanceScreen(),
    DocumentsScreen(),
    NotificationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasAlerts = (ref.watch(remindersProvider).value ?? const []).isNotEmpty;

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _pages),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: BottomNavBar(
                currentIndex: _index,
                showAlertBadge: hasAlerts,
                onTap: (i) => setState(() => _index = i),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 44,
            child: Center(
              child: _QuickAddFab(
                onTap: () => showQuickAddSheet(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAddFab extends StatelessWidget {
  const _QuickAddFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.accent,
      borderRadius: BorderRadius.circular(20),
      elevation: 10,
      shadowColor: p.accent.withValues(alpha: .6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: 60,
          height: 60,
          child: Icon(
            Icons.add_rounded,
            size: 30,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A0F08)
                : Colors.white,
          ),
        ),
      ),
    );
  }
}
