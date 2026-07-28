import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/file_pick.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/admin_document.dart';
import '../../providers/document_provider.dart';
import '../../providers/service_providers.dart';
import '../files/file_viewer_screen.dart';

/// Bottom sheet to add an administrative document (screen 06 "Scanner un
/// document" / screen 07 "Document").
///
/// Pass [existing] to edit or delete it instead of creating a new one —
/// documents used to be append-only, with no way to fix a wrong expiry
/// date or remove one added by mistake.
Future<void> showAddDocumentSheet(
  BuildContext context,
  String vehicleId, {
  AdminDocument? existing,
}) {
  final p = context.palette;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AddDocumentSheet(vehicleId: vehicleId, existing: existing),
  );
}

class _AddDocumentSheet extends ConsumerStatefulWidget {
  const _AddDocumentSheet({required this.vehicleId, this.existing});
  final String vehicleId;
  final AdminDocument? existing;

  @override
  ConsumerState<_AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends ConsumerState<_AddDocumentSheet> {
  late String _docType = widget.existing?.docType ?? DocTypes.controleTechnique;
  late int _year = widget.existing?.year ?? DateTime.now().year;
  late DateTime _expiryDate = widget.existing?.expiryDate ??
      DateTime.now().add(const Duration(days: 365));
  late final String? _existingFile = widget.existing?.fileUrl;
  File? _file;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;
  bool get _hasFile => _file != null || _existingFile != null;

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
      var fileUrl = _existingFile;
      if (_file != null) {
        fileUrl = await ref.read(supabaseServiceProvider).uploadFile(
              bucket: Buckets.adminDocuments,
              file: _file!,
              filename:
                  buildUploadName('$_docType-${widget.vehicleId}', _file!),
            );
      }
      final doc = AdminDocument(
        id: widget.existing?.id ?? '',
        vehicleId: widget.vehicleId,
        docType: _docType,
        year: _year,
        issuedDate: widget.existing?.issuedDate,
        expiryDate: _expiryDate,
        fileUrl: fileUrl,
        status: fileUrl != null ? 'valid' : 'pending',
      );
      final controller = ref.read(documentControllerProvider);
      if (_isEdit) {
        await controller.update(doc);
      } else {
        await controller.add(doc);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer ce ${DocTypes.label(_docType).toLowerCase()} ?'),
        content: const Text(
            'Le document et son scan seront définitivement supprimés.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: TextStyle(color: p.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(documentControllerProvider).remove(
            widget.vehicleId,
            widget.existing!.id,
            fileUrl: _existingFile,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e);
          _saving = false;
        });
      }
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
    return SingleChildScrollView(
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
          Text(_isEdit ? 'Modifier le document' : 'Nouveau document',
              style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _docType,
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
              child: Text(Fmt.dateShort(_expiryDate),
                  style: TextStyle(color: p.textPrimary)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: Icon(_hasFile ? Icons.check_circle : Icons.upload_file,
                color: _hasFile ? p.ok : p.textMuted),
            label: Text(_file != null
                ? 'Nouveau fichier sélectionné'
                : _hasFile
                    ? 'Remplacer le scan'
                    : 'Scanner un document'),
          ),
          if (_existingFile != null && _file == null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => FileViewerScreen.open(
                context,
                bucket: Buckets.adminDocuments,
                reference: _existingFile,
                title: DocTypes.label(_docType),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Voir le scan'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: p.danger)),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: p.onPrimary))
                : const Icon(Icons.check),
            label: const Text('Enregistrer'),
          ),
          if (_isEdit) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _saving ? null : _delete,
              icon: Icon(Icons.delete_outline, color: p.danger),
              label: Text('Supprimer', style: TextStyle(color: p.danger)),
              style: OutlinedButton.styleFrom(
                  side: BorderSide(color: p.danger.withValues(alpha: .3))),
            ),
          ],
        ],
      ),
    );
  }
}
