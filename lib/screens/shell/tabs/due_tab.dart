import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_text.dart';
import '../../../core/theme.dart';
import '../../../models/admin_document.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../core/constants.dart';
import '../../../widgets/document_card.dart';
import '../../admin_documents/add_document_sheet.dart';
import '../../vehicle_detail/sections/maintenance_section.dart';

/// "Échéances" tab — everything with a deadline, in one place.
///
/// The maintenance types that used to be a hub segment, plus the
/// administrative documents about to expire. Those two were on different
/// screens before, which meant nothing in the app ever answered "what is
/// coming up?" in a single view.
class DueTab extends ConsumerWidget {
  const DueTab({super.key, required this.vehicleId});
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final alertDays = ref.watch(settingsProvider).value?.daysAlertThreshold ??
        Thresholds.daysAlert;
    final docs = ref.watch(documentsProvider(vehicleId)).value ??
        const <AdminDocument>[];
    final expiring = docs.where((d) => d.daysToExpiry < alertDays).toList()
      ..sort((a, b) => a.daysToExpiry.compareTo(b.daysToExpiry));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        MaintenanceSection(vehicleId: vehicleId),
        if (expiring.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('DOCUMENTS À RENOUVELER',
              style: AppText.sectionLabel(p.textSecondary)),
          const SizedBox(height: 12),
          ...expiring.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DocumentCard(
                  doc: d,
                  onTap: () =>
                      showAddDocumentSheet(context, vehicleId, existing: d),
                ),
              )),
        ],
      ],
    );
  }
}
