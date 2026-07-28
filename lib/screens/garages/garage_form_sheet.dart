import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../models/garage.dart';
import '../../providers/garage_provider.dart';

/// Bottom sheet to create or edit a garage (repair shop). Returns the
/// created/updated [Garage] via [Navigator.pop] so callers (e.g. the repair
/// sheet's inline "+ garage") can immediately select it.
Future<Garage?> showGarageFormSheet(BuildContext context, {Garage? existing}) {
  final p = context.palette;
  return showModalBottomSheet<Garage>(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _GarageFormSheet(existing: existing),
  );
}

class _GarageFormSheet extends ConsumerStatefulWidget {
  const _GarageFormSheet({this.existing});
  final Garage? existing;

  @override
  ConsumerState<_GarageFormSheet> createState() => _GarageFormSheetState();
}

class _GarageFormSheetState extends ConsumerState<_GarageFormSheet> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  late final _address =
      TextEditingController(text: widget.existing?.address ?? '');
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Le nom est requis.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    String? clean(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    try {
      final ctrl = ref.read(garageControllerProvider);
      if (_isEdit) {
        await ctrl.update(widget.existing!.id, {
          'name': _name.text.trim(),
          'phone': clean(_phone),
          'address': clean(_address),
          'note': clean(_note),
        });
        if (mounted) {
          Navigator.pop(
            context,
            Garage(
              id: widget.existing!.id,
              name: _name.text.trim(),
              phone: clean(_phone),
              address: clean(_address),
              note: clean(_note),
            ),
          );
        }
      } else {
        final created = await ctrl.add(Garage(
          id: '',
          name: _name.text.trim(),
          phone: clean(_phone),
          address: clean(_address),
          note: clean(_note),
        ));
        if (mounted) Navigator.pop(context, created);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e);
          _saving = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer "${widget.existing!.name}" ?'),
        content: const Text(
            'Le garage sera retiré des interventions liées (leur nom reste '
            'affiché). Cette action est irréversible.'),
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
      await ref.read(garageControllerProvider).remove(widget.existing!.id);
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
          Text(_isEdit ? 'Modifier le garage' : 'Nouveau garage',
              style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: !_isEdit,
            style: TextStyle(color: p.textPrimary),
            decoration: InputDecoration(
              labelText: 'Nom',
              prefixIcon: Icon(Icons.store_mall_directory_outlined,
                  color: p.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: p.textPrimary),
            decoration: InputDecoration(
              labelText: 'Téléphone (optionnel)',
              prefixIcon: Icon(Icons.phone_outlined, color: p.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            style: TextStyle(color: p.textPrimary),
            decoration: InputDecoration(
              labelText: 'Adresse (optionnel)',
              prefixIcon: Icon(Icons.place_outlined, color: p.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 2,
            style: TextStyle(color: p.textPrimary),
            decoration: const InputDecoration(labelText: 'Note (optionnel)'),
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
