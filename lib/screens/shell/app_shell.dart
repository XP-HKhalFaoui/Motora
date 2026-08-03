import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/aurora_theme.dart';
import '../../providers/aurora_shell_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/aurora/aurora_button.dart';
import '../../widgets/aurora/aurora_floating_nav.dart';
import '../../widgets/aurora/aurora_tab_chrome.dart';
import '../due/aurora_due_screen.dart';
import '../home/aurora_home_screen.dart';
import '../home/vehicle_form_screen.dart';
import '../ledger/aurora_ledger_screen.dart';
import '../reports/aurora_reports_screen.dart';

/// Top-level shell: the four Aurora tabs (Accueil / Échéances / Journal /
/// Rapports) behind the floating pill nav, per
/// `design_handoff_motora_aurora/README.md`. There is no shared app bar —
/// each tab owns its own header row inside its own scrolling content.
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
    // main() calls NotificationService.init() without a handler, so this
    // assignment is the only thing that makes a tap do anything.
    NotificationService.instance.onOpenVehicle = _openVehicle;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final launched = NotificationService.instance.takeLaunchVehicleId();
      if (launched != null) _openVehicle(launched);
    });
  }

  /// A reminder is always about an échéance or a document, so select its
  /// vehicle and land on Échéances.
  void _openVehicle(String vehicleId) {
    if (!mounted) return;
    ref.read(selectedVehicleIdProvider.notifier).state = vehicleId;
    ref.read(auroraShellTabProvider.notifier).state = AuroraNavTab.due;
    // A pushed screen would otherwise hide the tab we just switched to.
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(auroraShellTabProvider);
    final vehicleId = ref.watch(effectiveSelectedVehicleIdProvider);

    ref.listen(remindersProvider, (_, next) {
      final list = next.value;
      if (list != null) {
        ref.read(reminderSchedulerProvider).sync(list);
      }
    });

    return AuroraTabChrome(
      tab: tab,
      onSelectTab: (t) => ref.read(auroraShellTabProvider.notifier).state = t,
      vehicleId: vehicleId,
      body: vehicleId == null
          ? const _NoVehicle()
          : IndexedStack(
              index: tab.index,
              children: [
                AuroraHomeScreen(vehicleId: vehicleId),
                AuroraDueScreen(vehicleId: vehicleId),
                AuroraLedgerScreen(vehicleId: vehicleId),
                AuroraReportsScreen(vehicleId: vehicleId),
              ],
            ),
    );
  }
}

class _NoVehicle extends StatelessWidget {
  const _NoVehicle();

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Aucun véhicule',
                textAlign: TextAlign.center,
                style: AuroraText.cardTitle(aurora.textPrimary)),
            const SizedBox(height: 6),
            Text('Commencez par ajouter un véhicule.',
                textAlign: TextAlign.center,
                style: AuroraText.meta(aurora.muted)),
            const SizedBox(height: 20),
            AuroraPrimaryButton(
              label: 'Ajouter un véhicule',
              expand: false,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
