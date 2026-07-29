import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/notification_provider.dart';
import '../../providers/shell_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../history/history_screen.dart';
import '../home/vehicle_form_screen.dart';
import '../notifications/notifications_screen.dart';
import '../vehicle/vehicle_tab.dart';
import 'quick_add_dial.dart';
import 'tabs/due_tab.dart';
import 'tabs/more_tab.dart';
import 'vehicle_selector.dart';

/// Top-level shell: four destinations around a centre FAB, with the
/// current vehicle chosen from the app bar.
///
/// This replaces the car-first hub, and is what the design spec asked for
/// in the first place ("bottom navigation Material à 5 entrées avec
/// encoche centrale pour le FAB").
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
  bool _dialOpen = false;

  @override
  void initState() {
    super.initState();
    // main() calls NotificationService.init() without a handler, so this
    // assignment is the only thing that makes a tap do anything.
    NotificationService.instance.onOpenVehicle = _openVehicle;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final launched = NotificationService.instance.takeLaunchVehicleId();
      if (launched != null) _openVehicle(launched);
    });
  }

  /// A reminder is always about an échéance or a document, so select its
  /// vehicle and land on Échéances. This used to push the hub with
  /// `initialSection: 1`; with tabs it is a selection, not a route.
  void _openVehicle(String vehicleId) {
    if (!mounted) return;
    ref.read(selectedVehicleIdProvider.notifier).state = vehicleId;
    ref.read(shellTabProvider.notifier).state = ShellTab.due;
    // A pushed screen would otherwise hide the tab we just switched to.
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tab = ref.watch(shellTabProvider);
    final vehicleId = ref.watch(effectiveSelectedVehicleIdProvider);
    final reminders = ref.watch(remindersProvider).value ?? const [];

    ref.listen(remindersProvider, (_, next) {
      final list = next.value;
      if (list != null) {
        ref.read(reminderSchedulerProvider).sync(list);
      }
    });

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        titleSpacing: 12,
        title: const VehicleSelector(),
        actions: [
          _BellButton(
            hasAlerts: reminders.isNotEmpty,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          if (vehicleId == null)
            const _NoVehicle()
          else
            IndexedStack(
              index: tab.index,
              children: [
                VehicleTab(vehicleId: vehicleId),
                HistoryScreen(vehicleId: vehicleId, embedded: true),
                DueTab(vehicleId: vehicleId),
                MoreTab(vehicleId: vehicleId),
              ],
            ),
          if (_dialOpen)
            QuickAddOverlay(
              vehicleId: vehicleId,
              onClose: () => setState(() => _dialOpen = false),
            ),
        ],
      ),
      floatingActionButton: QuickAddFab(
        open: _dialOpen,
        onToggle: () => setState(() => _dialOpen = !_dialOpen),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        current: tab,
        dueBadge: reminders.isNotEmpty,
        onSelect: (t) => ref.read(shellTabProvider.notifier).state = t,
      ),
    );
  }
}

class _NoVehicle extends StatelessWidget {
  const _NoVehicle();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const EmptyState(
          icon: Icons.directions_car_outlined,
          message: 'Aucun véhicule.\nCommencez par en ajouter un.',
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
          ),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Ajouter un véhicule'),
        ),
      ],
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.hasAlerts, required this.onTap});
  final bool hasAlerts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: hasAlerts ? 'Alertes, échéances en attente' : 'Alertes',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_rounded,
                  size: 22, color: p.textSecondary),
              if (hasAlerts)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.danger,
                      border: Border.all(color: p.background, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
