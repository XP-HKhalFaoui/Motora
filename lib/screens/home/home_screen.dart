import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/vehicle.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/async_value_view.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';
import '../vehicle_detail/vehicle_detail_screen.dart';
import 'vehicle_form_screen.dart';
import 'alerts_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final reminders = ref.watch(remindersProvider);
    final alertCount = reminders.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes véhicules'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: alertCount > 0,
              label: Text('$alertCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openVehicleForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Véhicule'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(vehiclesProvider.notifier).refresh();
          ref.invalidate(remindersProvider);
        },
        child: AsyncValueView<List<Vehicle>>(
          value: vehiclesAsync,
          onRetry: () => ref.read(vehiclesProvider.notifier).refresh(),
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    icon: Icons.directions_car_outlined,
                    message:
                        'Aucun véhicule.\nAppuyez sur « Véhicule » pour commencer.',
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                const AlertsBanner(),
                ...vehicles.map((v) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _VehicleTile(vehicle: v),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openVehicleForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => VehicleDetailScreen(vehicleId: vehicle.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.directions_car,
                    color: AppColors.accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (vehicle.brand != null) vehicle.brand,
                        if (vehicle.model != null) vehicle.model,
                        if (vehicle.plateNumber != null) vehicle.plateNumber,
                      ].whereType<String>().join(' · '),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Fmt.km(vehicle.currentKm),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 2),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
