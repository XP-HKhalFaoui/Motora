import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_text.dart';
import '../../../core/theme.dart';
import '../../../models/admin_document.dart';
import '../../../providers/document_provider.dart';
import '../../../widgets/async_value_view.dart';
import '../../../widgets/document_card.dart';
import '../../admin_documents/add_document_sheet.dart';

/// "Docs" section of the vehicle hub: year pills, document cards and a
/// "scan a document" action, scoped to a single [vehicleId].
class DocumentsSection extends ConsumerStatefulWidget {
  const DocumentsSection({super.key, required this.vehicleId});
  final String vehicleId;

  @override
  ConsumerState<DocumentsSection> createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends ConsumerState<DocumentsSection> {
  int? _year;

  @override
  Widget build(BuildContext context) {
    return AsyncValueView(
      value: ref.watch(documentsProvider(widget.vehicleId)),
      onRetry: () => ref.invalidate(documentsProvider(widget.vehicleId)),
      data: (docs) => _Body(
        vehicleId: widget.vehicleId,
        docs: docs,
        selectedYear: _year,
        onYearSelected: (y) => setState(() => _year = y),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            side: BorderSide(color: p.border, width: 1.5),
          ),
        ),
      ],
    );
  }
}
