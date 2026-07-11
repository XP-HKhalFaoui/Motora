import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/vehicle_provider.dart';
import '../maintenance/maintenance_tab.dart';
import '../admin_documents/documents_tab.dart';
import '../history/history_tab.dart';
import 'overview_tab.dart';
import 'update_km_sheet.dart';

/// Hub screen for one vehicle: overview + maintenance + history + documents.
class VehicleDetailScreen extends ConsumerWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(vehicleByIdProvider(vehicleId));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(vehicle?.name ?? 'Véhicule'),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: 'Aperçu'),
              Tab(text: 'Entretien'),
              Tab(text: 'Historique'),
              Tab(text: 'Documents'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showUpdateKmSheet(context, vehicleId),
          icon: const Icon(Icons.speed),
          label: const Text('Mettre à jour le km'),
        ),
        body: TabBarView(
          children: [
            OverviewTab(vehicleId: vehicleId),
            MaintenanceTab(vehicleId: vehicleId),
            HistoryTab(vehicleId: vehicleId),
            DocumentsTab(vehicleId: vehicleId),
          ],
        ),
      ),
    );
  }
}
