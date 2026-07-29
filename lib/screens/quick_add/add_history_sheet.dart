import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/file_pick.dart';
import '../../core/theme.dart';
import '../../models/garage.dart';
import '../../models/maintenance_history.dart';
import '../../models/maintenance_type.dart';
import '../../providers/garage_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/vehicle_provider.dart';
import '../files/file_viewer_screen.dart';
import '../garages/garage_form_sheet.dart';

/// Bottom sheet to log a repair/intervention (screen 07 "Réparation") or,
/// with [isFuel], a fuel fill-up ("Plein") — same form, but fuel entries
/// capture liters instead of a linked maintenance type.
///
/// Pass [existing] to edit/delete it instead of creating a new one; its
/// own [MaintenanceHistory.isFuel] then decides the form's mode.
Future<void> showAddHistorySheet(
  BuildContext context,
  String vehicleId, {
  String defaultTitle = '',
  bool isFuel = false,
  MaintenanceHistory? existing,
  String? defaultMaintenanceTypeId,
}) {
  final p = context.palette;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AddHistorySheet(
      vehicleId: vehicleId,
      defaultTitle: defaultTitle,
      isFuel: isFuel,
      existing: existing,
      defaultMaintenanceTypeId: defaultMaintenanceTypeId,
    ),
  );
}

class _AddHistorySheet extends ConsumerStatefulWidget {
  const _AddHistorySheet({
    required this.vehicleId,
    required this.defaultTitle,
    required this.isFuel,
    this.existing,
    this.defaultMaintenanceTypeId,
  });
  final String vehicleId;
  final String defaultTitle;
  final bool isFuel;
  final MaintenanceHistory? existing;
  final String? defaultMaintenanceTypeId;

  @override
  ConsumerState<_AddHistorySheet> createState() => _AddHistorySheetState();
}

class _AddHistorySheetState extends ConsumerState<_AddHistorySheet> {
  late final _title = TextEditingController(
      text: widget.existing?.title ?? widget.defaultTitle);
  late final _km =
      TextEditingController(text: widget.existing?.km?.toString() ?? '');
  late final _cost =
      TextEditingController(text: widget.existing?.cost?.toString() ?? '');
  late final _liters =
      TextEditingController(text: widget.existing?.liters?.toString() ?? '');
  // Free-text station name — used for fuel fill-ups only. Repairs pick a
  // garage entity via [_garageId] instead.
  late final _garage =
      TextEditingController(text: widget.existing?.garageName ?? '');
  late String? _garageId = widget.existing?.garageId;
  late bool _isFullTank = widget.existing?.isFullTank ?? true;
  late DateTime _doneAt = widget.existing?.doneAt ?? DateTime.now();
  File? _newInvoice;
  late final _existingInvoiceUrl = widget.existing?.invoiceUrl;
  late String? _maintenanceTypeId =
      widget.existing?.maintenanceTypeId ?? widget.defaultMaintenanceTypeId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Validating an échéance ("marquer comme fait") opens this form
    // pre-linked to the type — prefill the km with the vehicle's current
    // reading so the user just confirms date / km / garage.
    if (widget.existing == null && widget.defaultMaintenanceTypeId != null) {
      final km = ref.read(vehicleByIdProvider(widget.vehicleId))?.currentKm;
      if (km != null && km > 0) _km.text = km.toString();
    }
  }

  bool get _isEdit => widget.existing != null;
  bool get _isFuel => widget.existing?.isFuel ?? widget.isFuel;

  // (garage picker lives in [_GaragePicker] below)

  Future<void> _pickInvoice() async {
    final file = await pickAttachment(context);
    if (file != null) setState(() => _newInvoice = file);
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
      var invoiceUrl = _existingInvoiceUrl;
      if (_newInvoice != null) {
        invoiceUrl = await ref.read(supabaseServiceProvider).uploadFile(
              bucket: Buckets.invoices,
              file: _newInvoice!,
              filename:
                  buildUploadName('history-${widget.vehicleId}', _newInvoice!),
            );
      }
      // Fuel keeps a free-text station; a repair links a garage entity and
      // denormalizes its name so history stays readable if it's deleted.
      String? garageName;
      String? garageId;
      if (_isFuel) {
        garageName = _garage.text.trim().isEmpty ? null : _garage.text.trim();
      } else {
        garageId = _garageId;
        if (_garageId != null) {
          final garages = ref.read(garagesProvider).value ?? const <Garage>[];
          for (final g in garages) {
            if (g.id == _garageId) {
              garageName = g.name;
              break;
            }
          }
        } else {
          garageName = widget.existing?.garageName; // preserve legacy text
        }
      }
      final history = MaintenanceHistory(
        id: widget.existing?.id ?? '',
        vehicleId: widget.vehicleId,
        maintenanceTypeId: _isFuel ? null : _maintenanceTypeId,
        title: _title.text.trim(),
        km: int.tryParse(_km.text.trim()),
        cost: double.tryParse(_cost.text.trim().replaceAll(',', '.')),
        garageName: garageName,
        garageId: garageId,
        doneAt: _doneAt,
        invoiceUrl: invoiceUrl,
        isFuel: _isFuel,
        isFullTank: _isFuel ? _isFullTank : true,
        liters: _isFuel
            ? double.tryParse(_liters.text.trim().replaceAll(',', '.'))
            : null,
      );
      final controller = ref.read(maintenanceControllerProvider);
      if (_isEdit) {
        await controller.updateHistory(history);
      } else {
        await controller.addHistory(history);
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
        title: Text('Supprimer "${widget.existing!.title}" ?'),
        content: const Text('Cette action est irréversible.'),
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
      await ref.read(maintenanceControllerProvider).deleteHistory(
          widget.vehicleId, widget.existing!.id,
          invoiceUrl: _existingInvoiceUrl);
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
    final hasInvoice = _newInvoice != null || _existingInvoiceUrl != null;
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
                  ? (_isFuel ? 'Modifier le plein' : "Modifier l'intervention")
                  : (_isFuel ? 'Nouveau plein' : 'Nouvelle intervention'),
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
          if (!_isFuel)
            Consumer(
              builder: (context, ref, _) {
                final types = ref
                        .watch(maintenanceTypesProvider(widget.vehicleId))
                        .value ??
                    const <MaintenanceType>[];
                if (types.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String?>(
                    initialValue: _maintenanceTypeId,
                    decoration: const InputDecoration(
                        labelText: "Lié à un type d'entretien (optionnel)"),
                    dropdownColor: p.surface,
                    style: TextStyle(color: p.textPrimary),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Aucun')),
                      ...types.map((t) =>
                          DropdownMenuItem(value: t.id, child: Text(t.label))),
                    ],
                    onChanged: (v) => setState(() {
                      _maintenanceTypeId = v;
                      if (v != null && _title.text.trim().isEmpty) {
                        _title.text = types.firstWhere((t) => t.id == v).label;
                      }
                    }),
                  ),
                );
              },
            ),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _km,
                keyboardType: TextInputType.number,
                style: TextStyle(color: p.textPrimary),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    const InputDecoration(labelText: 'Km', suffixText: 'km'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cost,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: p.textPrimary),
                decoration:
                    const InputDecoration(labelText: 'Coût', suffixText: '€'),
              ),
            ),
          ]),
          if (_isFuel) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _liters,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: p.textPrimary),
              decoration:
                  const InputDecoration(labelText: 'Litres', suffixText: 'L'),
            ),
            // Consumption is only measurable between two brimmed tanks; a
            // partial fill's litres are carried into the next full one.
            SwitchListTile(
              value: _isFullTank,
              onChanged: (v) => setState(() => _isFullTank = v),
              contentPadding: EdgeInsets.zero,
              title: Text('Plein complet',
                  style: TextStyle(color: p.textPrimary, fontSize: 14)),
              subtitle: Text(
                _isFullTank
                    ? 'Réservoir rempli à ras bord'
                    : "Appoint — compté dans le prochain plein complet",
                style: TextStyle(color: p.textMuted, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_isFuel)
            TextField(
              controller: _garage,
              style: TextStyle(color: p.textPrimary),
              decoration:
                  const InputDecoration(labelText: 'Station (optionnel)'),
            )
          else
            _GaragePicker(
              selectedId: _garageId,
              onChanged: (id) => setState(() => _garageId = id),
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
            icon: Icon(hasInvoice ? Icons.check_circle : Icons.receipt_long,
                color: hasInvoice ? p.ok : p.textMuted),
            label: Text(_newInvoice != null
                ? 'Nouvelle facture sélectionnée'
                : hasInvoice
                    ? 'Remplacer la facture'
                    : 'Ajouter une facture'),
          ),
          if (_existingInvoiceUrl != null && _newInvoice == null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => FileViewerScreen.open(
                context,
                bucket: Buckets.invoices,
                reference: _existingInvoiceUrl,
                title:
                    _title.text.trim().isEmpty ? 'Facture' : _title.text.trim(),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Voir la facture'),
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

/// Garage selector for a repair: a dropdown of the user's garages plus an
/// inline "＋" to create a new one (which is then auto-selected).
class _GaragePicker extends ConsumerWidget {
  const _GaragePicker({required this.selectedId, required this.onChanged});
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final garages = ref.watch(garagesProvider).value ?? const <Garage>[];
    // A legacy value that no longer maps to a garage would break the
    // Dropdown's assertion — guard against it.
    final value = garages.any((g) => g.id == selectedId) ? selectedId : null;

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String?>(
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Garage (optionnel)'),
            dropdownColor: p.surface,
            style: TextStyle(color: p.textPrimary),
            items: [
              const DropdownMenuItem(value: null, child: Text('Aucun')),
              ...garages.map(
                  (g) => DropdownMenuItem(value: g.id, child: Text(g.name))),
            ],
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Nouveau garage',
          icon: Icon(Icons.add_circle_outline, color: p.primary),
          onPressed: () async {
            final created = await showGarageFormSheet(context);
            if (created != null) onChanged(created.id);
          },
        ),
      ],
    );
  }
}
