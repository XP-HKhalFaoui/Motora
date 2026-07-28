import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../home/home_screen.dart';
import '../quick_add/quick_add_sheet.dart';

/// Top-level shell. The app is car-first with a single global screen — the
/// Accueil "garage" — so there is no bottom nav: Alertes and Réglages are
/// reached from the header, a vehicle's maintenance / documents / km live
/// inside its hub (pushed on top), and the only persistent chrome is the
/// Ajout-rapide FAB.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: const HomeScreen(),
      floatingActionButton: _QuickAddFab(
        onTap: () => showQuickAddSheet(context),
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
