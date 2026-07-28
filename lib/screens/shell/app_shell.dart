import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
import '../home/home_screen.dart';
import '../quick_add/quick_add_sheet.dart';
import '../vehicle_detail/vehicle_hub_screen.dart';

/// Top-level shell. The app is car-first with a single global screen — the
/// Accueil "garage" — so there is no bottom nav: Alertes and Réglages are
/// reached from the header, a vehicle's maintenance / documents / km live
/// inside its hub (pushed on top), and the only persistent chrome is the
/// Ajout-rapide FAB.
///
/// The shell also owns the two side effects that need a live navigator:
/// keeping the OS notification schedule in sync with [remindersProvider],
/// and opening the vehicle behind a tapped reminder.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    NotificationService.instance.onOpenVehicle = _openVehicle;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final launched = NotificationService.instance.takeLaunchVehicleId();
      if (launched != null) _openVehicle(launched);
    });
  }

  void _openVehicle(String vehicleId) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        // Land on Entretien: every reminder is about an échéance or a
        // document, not the overview.
        builder: (_) =>
            VehicleHubScreen(vehicleId: vehicleId, initialSection: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    ref.listen(remindersProvider, (_, next) {
      final reminders = next.value;
      if (reminders != null) {
        ref.read(reminderSchedulerProvider).sync(reminders);
      }
    });

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
