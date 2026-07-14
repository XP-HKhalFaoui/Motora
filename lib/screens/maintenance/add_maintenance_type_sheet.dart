import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/maintenance_type.dart';
import '../../providers/maintenance_provider.dart';

/// Bottom sheet to create or edit a maintenance type (e.g. "Vidange
/// moteur", "Plaquettes avant") for a vehicle — screen 04 "Entretien".
/// Pass [existing] to edit/delete it instead of creating a new one.
Future<void> showAddMaintenanceTypeSheet(
  BuildContext context,
  String vehicleId, {
  MaintenanceType? existing,
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
        _AddMaintenanceTypeSheet(vehicleId: vehicleId, existing: existing),
  );
}

class _AddMaintenanceTypeSheet extends ConsumerStatefulWidget {
  const _AddMaintenanceTypeSheet({required this.vehicleId, this.existing});
  final String vehicleId;
  final MaintenanceType? existing;

  @override
  ConsumerState<_AddMaintenanceTypeSheet> createState() =>
      _AddMaintenanceTypeSheetState();
}

/// Common French car-maintenance intervals, offered as quick-fill presets.
class _Preset {
  const _Preset(this.label, {this.intervalKm, this.intervalMonths});
  final String label;
  final int? intervalKm;
  final int? intervalMonths;
}

const _presets = [
  _Preset('Vidange moteur', intervalKm: 7000),
  _Preset('Kit chaîne / distribution', intervalKm: 50000),
  _Preset('Pneus', intervalKm: 40000, intervalMonths: 24),
];

class _AddMaintenanceTypeSheetState
    extends ConsumerState<_AddMaintenanceTypeSheet> {
  late final _label = TextEditingController(text: widget.existing?.label ?? '');
  late final _intervalKm = TextEditingController(
      text: widget.existing?.intervalKm?.toString() ?? '');
  late final _intervalMonths = TextEditingController(
      text: widget.existing?.intervalMonths?.toString() ?? '');
  late final _lastDoneKm = TextEditingController(
      text: widget.existing?.lastDoneKm?.toString() ?? '');
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  void _applyPreset(_Preset preset) {
    setState(() {
      _label.text = preset.label;
      _intervalKm.text = preset.intervalKm?.toString() ?? '';
      _intervalMonths.text = preset.intervalMonths?.toString() ?? '';
    });
  }

  @override
  void dispose() {
    for (final c in [_label, _intervalKm, _intervalMonths, _lastDoneKm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_label.text.trim().isEmpty) {
      setState(() => _error = 'Le nom est requis.');
      return;
    }
    final intervalKm = int.tryParse(_intervalKm.text.trim());
    final intervalMonths = int.tryParse(_intervalMonths.text.trim());
    if (intervalKm == null && intervalMonths == null) {
      setState(() => _error = 'Indiquez un intervalle en km et/ou en mois.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final controller = ref.read(maintenanceControllerProvider);
      if (_isEdit) {
        await controller.updateType(widget.vehicleId, widget.existing!.id, {
          'label': _label.text.trim(),
          'interval_km': intervalKm,
          'interval_months': intervalMonths,
          'last_done_km': int.tryParse(_lastDoneKm.text.trim()),
        });
      } else {
        await controller.addType(MaintenanceType(
          id: '',
          vehicleId: widget.vehicleId,
          label: _label.text.trim(),
          intervalKm: intervalKm,
          intervalMonths: intervalMonths,
          lastDoneKm: int.tryParse(_lastDoneKm.text.trim()),
        ));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer ${widget.existing!.label} ?'),
        content: const Text(
            'Cette action supprime aussi son historique de progression. '
            'Elle est irréversible.'),
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
      await ref
          .read(maintenanceControllerProvider)
          .deleteType(widget.vehicleId, widget.existing!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur : $e';
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
          Text(
              _isEdit
                  ? "Modifier le type d'entretien"
                  : "Nouveau type d'entretien",
              style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Ex. Vidange moteur, Plaquettes avant, Batterie…',
              style: TextStyle(color: p.textMuted, fontSize: 12.5)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets
                .map((preset) => GestureDetector(
                      onTap: () => _applyPreset(preset),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: p.background,
                          border: Border.all(color: p.border),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(preset.label,
                            style: TextStyle(
                                color: p.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _label,
            autofocus: !_isEdit,
            style: TextStyle(color: p.textPrimary),
            decoration: const InputDecoration(labelText: 'Nom'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _intervalKm,
                keyboardType: TextInputType.number,
                style: TextStyle(color: p.textPrimary),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    labelText: 'Intervalle', suffixText: 'km'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _intervalMonths,
                keyboardType: TextInputType.number,
                style: TextStyle(color: p.textPrimary),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    labelText: 'Intervalle', suffixText: 'mois'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _lastDoneKm,
            keyboardType: TextInputType.number,
            style: TextStyle(color: p.textPrimary),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
                labelText: 'Dernier relevé (optionnel)', suffixText: 'km'),
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
