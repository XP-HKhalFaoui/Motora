import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/file_pick.dart';
import '../../core/theme.dart';
import '../../models/admin_document.dart';
import '../../providers/document_provider.dart';
import '../../providers/service_providers.dart';

/// Bottom sheet to add an administrative document (screen 06 "Scanner un
/// document" / screen 07 "Document").
Future<void> showAddDocumentSheet(BuildContext context, String vehicleId) {
  final p = context.palette;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AddDocumentSheet(vehicleId: vehicleId),
  );
}

class _AddDocumentSheet extends ConsumerStatefulWidget {
  const _AddDocumentSheet({required this.vehicleId});
  final String vehicleId;

  @override
  ConsumerState<_AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends ConsumerState<_AddDocumentSheet> {
  String _docType = DocTypes.controleTechnique;
  int _year = DateTime.now().year;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  File? _file;
  bool _saving = false;
  String? _error;

  Future<void> _pickFile() async {
    final file = await pickAttachment(context);
    if (file != null) setState(() => _file = file);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? fileUrl;
      if (_file != null) {
        fileUrl = await ref.read(supabaseServiceProvider).uploadFile(
              bucket: Buckets.adminDocuments,
              file: _file!,
              filename: buildUploadName('$_docType-${widget.vehicleId}', _file!),
            );
      }
      await ref.read(documentControllerProvider).add(AdminDocument(
            id: '',
            vehicleId: widget.vehicleId,
            docType: _docType,
            year: _year,
            expiryDate: _expiryDate,
            fileUrl: fileUrl,
            status: fileUrl != null ? 'valid' : 'pending',
          ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expiryDate = picked);
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
          Text('Nouveau document',
              style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _docType,
            decoration: const InputDecoration(labelText: 'Type de document'),
            dropdownColor: p.surface,
            style: TextStyle(color: p.textPrimary),
            items: DocTypes.all
                .map((t) =>
                    DropdownMenuItem(value: t, child: Text(DocTypes.label(t))))
                .toList(),
            onChanged: (v) => setState(() => _docType = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: '$_year',
            keyboardType: TextInputType.number,
            style: TextStyle(color: p.textPrimary),
            decoration: const InputDecoration(labelText: 'Année'),
            onChanged: (v) => _year = int.tryParse(v) ?? _year,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickExpiryDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date d\'échéance'),
              child: Text(
                '${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}',
                style: TextStyle(color: p.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: Icon(
                _file == null ? Icons.upload_file : Icons.check_circle,
                color: _file == null ? p.textMuted : p.ok),
            label: Text(_file == null ? 'Scanner un document' : 'Fichier sélectionné'),
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
