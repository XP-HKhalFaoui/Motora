import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_text.dart';
import '../../core/theme.dart';
import '../../models/admin_document.dart';
import '../../providers/document_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/document_card.dart';
import '../../widgets/vehicle_pill_selector.dart';
import 'add_document_sheet.dart';

/// Documents administratifs (screen 06): vehicle selector, year pills,
/// document cards, "Scanner un document" action.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  int? _year;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final vehicles = ref.watch(vehiclesProvider).value ?? const [];
    final vehicleId = ref.watch(effectiveSelectedVehicleIdProvider);
    final vehicle = vehicleId == null
        ? null
        : ref.watch(vehicleByIdProvider(vehicleId));

    return Container(
      color: p.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
          children: [
            Text('Documents${vehicle != null ? ' · ${vehicle.name}' : ''}',
                style: AppText.screenTitle(p.textPrimary)),
            const SizedBox(height: 16),
            VehiclePillSelector(vehicles: vehicles),
            if (vehicleId == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('Ajoutez un véhicule pour commencer.',
                      style: TextStyle(color: p.textMuted)),
                ),
              )
            else
              AsyncValueView(
                value: ref.watch(documentsProvider(vehicleId)),
                data: (docs) => _Body(
                  vehicleId: vehicleId,
                  docs: docs,
                  selectedYear: _year,
                  onYearSelected: (y) => setState(() => _year = y),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.vehicleId,
    required this.docs,
    required this.selectedYear,
    required this.onYearSelected,
  });

  final String vehicleId;
  final List<AdminDocument> docs;
  final int? selectedYear;
  final ValueChanged<int?> onYearSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final years = {DateTime.now().year, ...docs.map((d) => d.year)}.toList()
      ..sort((a, b) => b.compareTo(a));
    final year = selectedYear ?? years.first;
    final filtered = docs.where((d) => d.year == year).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: years.map((y) {
            final active = y == year;
            return GestureDetector(
              onTap: () => onYearSelected(y),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? p.primary : p.surface,
                  border: Border.all(color: active ? p.primary : p.border),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('$y',
                    style: AppText.technical(
                        active ? Colors.white : p.textSecondary, size: 14)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('Aucun document pour $year.',
                style: TextStyle(color: p.textMuted)),
          )
        else
          ...filtered.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DocumentCard(doc: d),
              )),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () => showAddDocumentSheet(context, vehicleId),
          icon: Icon(Icons.upload_file, color: p.textSecondary),
          label: const Text('Scanner un document'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
                color: p.border, style: BorderStyle.solid, width: 1.5),
          ),
        ),
      ],
    );
  }
}
