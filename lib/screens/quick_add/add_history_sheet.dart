import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/file_pick.dart';
import '../../core/theme.dart';
import '../../models/maintenance_history.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/service_providers.dart';

/// Bottom sheet to log a repair/intervention (screen 07 "Réparation" and
/// "Plein" — the latter reuses this form with a generic title and no
/// linked maintenance type, since the schema has no dedicated fuel table).
Future<void> showAddHistorySheet(
  BuildContext context,
  String vehicleId, {
  String defaultTitle = '',
}) {
  final p = context.palette;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        _AddHistorySheet(vehicleId: vehicleId, defaultTitle: defaultTitle),
  );
}

class _AddHistorySheet extends ConsumerStatefulWidget {
  const _AddHistorySheet({required this.vehicleId, required this.defaultTitle});
  final String vehicleId;
  final String defaultTitle;

  @override
  ConsumerState<_AddHistorySheet> createState() => _AddHistorySheetState();
}

class _AddHistorySheetState extends ConsumerState<_AddHistorySheet> {
  late final _title = TextEditingController(text: widget.defaultTitle);
  final _km = TextEditingController();
  final _cost = TextEditingController();
  final _garage = TextEditingController();
  DateTime _doneAt = DateTime.now();
  File? _invoice;
  bool _saving = false;
  String? _error;

  Future<void> _pickInvoice() async {
    final file = await pickAttachment(context);
    if (file != null) setState(() => _invoice = file);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _doneAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _doneAt = picked);
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Le titre est requis.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? invoiceUrl;
      if (_invoice != null) {
        invoiceUrl = await ref.read(supabaseServiceProvider).uploadFile(
              bucket: Buckets.invoices,
              file: _invoice!,
              filename: buildUploadName('history-${widget.vehicleId}', _invoice!),
            );
      }
      await ref.read(maintenanceControllerProvider).addHistory(MaintenanceHistory(
            id: '',
            vehicleId: widget.vehicleId,
            title: _title.text.trim(),
            km: int.tryParse(_km.text.trim()),
            cost: double.tryParse(_cost.text.trim().replaceAll(',', '.')),
            garageName: _garage.text.trim().isEmpty ? null : _garage.text.trim(),
            doneAt: _doneAt,
            invoiceUrl: invoiceUrl,
          ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                  color: p.border, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          Text('Nouvelle intervention',
              style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            style: TextStyle(color: p.textPrimary),
            decoration: const InputDecoration(labelText: 'Titre'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _km,
                keyboardType: TextInputType.number,
                style: TextStyle(color: p.textPrimary),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Km', suffixText: 'km'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cost,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: p.textPrimary),
                decoration: const InputDecoration(labelText: 'Coût', suffixText: '€'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _garage,
            style: TextStyle(color: p.textPrimary),
            decoration: const InputDecoration(labelText: 'Garage (optionnel)'),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date'),
              child: Text('${_doneAt.day}/${_doneAt.month}/${_doneAt.year}',
                  style: TextStyle(color: p.textPrimary)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickInvoice,
            icon: Icon(
                _invoice == null ? Icons.receipt_long : Icons.check_circle,
                color: _invoice == null ? p.textMuted : p.ok),
            label: Text(_invoice == null ? 'Ajouter une facture' : 'Facture ajoutée'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: p.danger)),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
