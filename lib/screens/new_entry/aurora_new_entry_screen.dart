import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/aurora_theme.dart';
import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/file_pick.dart';
import '../../core/formatters.dart';
import '../../models/garage.dart';
import '../../models/maintenance_history.dart';
import '../../providers/garage_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/aurora/aurora_app_bar_chip.dart';
import '../../widgets/aurora/aurora_button.dart';
import '../../widgets/aurora/aurora_card.dart';
import '../../widgets/aurora/aurora_image_slot.dart';
import '../../widgets/aurora/aurora_segmented_control.dart';
import '../files/file_viewer_screen.dart';
import '../garages/garage_form_sheet.dart';

/// New entry — "Nouvelle entrée". The single full-screen form behind all
/// three ledger types, and the target of Due's "Marquer comme fait" /
/// "Renouveler" (which arrives pre-filled and linked via
/// [defaultMaintenanceTypeId] and shows [linkedLabel]'s banner).
///
/// No bottom nav, sticky footer — a pushed route, not a shell tab.
///
/// Pass [existing] to edit/delete it instead of creating a new one; its
/// kind can't then be changed (switching type mid-edit would strand
/// kind-specific fields already saved under the old one — the pre-Aurora
/// sheet had the same rule).
class AuroraNewEntryScreen extends ConsumerStatefulWidget {
  const AuroraNewEntryScreen({
    super.key,
    required this.vehicleId,
    this.kind = HistoryEntryKind.maintenance,
    this.existing,
    this.defaultTitle = '',
    this.defaultMaintenanceTypeId,
    this.linkedLabel,
  });

  final String vehicleId;
  final HistoryEntryKind kind;
  final MaintenanceHistory? existing;
  final String defaultTitle;
  final String? defaultMaintenanceTypeId;

  /// The maintenance type's label, for the "Lié à ..." banner shown when
  /// this form was opened from "Marquer comme fait". Null hides it.
  final String? linkedLabel;

  @override
  ConsumerState<AuroraNewEntryScreen> createState() => _AuroraNewEntryScreenState();
}

class _AuroraNewEntryScreenState extends ConsumerState<AuroraNewEntryScreen> {
  late HistoryEntryKind _kind = widget.existing?.kind ?? widget.kind;
  late final _title = TextEditingController(text: widget.existing?.title ?? widget.defaultTitle);
  late final _km = TextEditingController(text: widget.existing?.km?.toString() ?? '');
  late final _cost = TextEditingController(text: widget.existing?.cost?.toString() ?? '');
  late final _liters = TextEditingController(text: widget.existing?.liters?.toString() ?? '');
  late String? _garageId = widget.existing?.garageId;
  late String _category = widget.existing?.category ?? ExpenseCategories.autre;
  late bool _isFullTank = widget.existing?.isFullTank ?? true;
  late DateTime _doneAt = widget.existing?.doneAt ?? DateTime.now();
  File? _newInvoice;
  late final _existingInvoiceUrl = widget.existing?.invoiceUrl;
  // Read-only: the manual "link to a maintenance type" picker the
  // pre-Aurora sheet had is dropped per the spec's field list — linking
  // now only happens via "Marquer comme fait" (defaultMaintenanceTypeId)
  // or by having already been linked when editing.
  late final String? _maintenanceTypeId =
      widget.existing?.maintenanceTypeId ?? widget.defaultMaintenanceTypeId;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;
  bool get _isFuel => _kind == HistoryEntryKind.fuel;
  bool get _isExpense => _kind == HistoryEntryKind.expense;

  @override
  void initState() {
    super.initState();
    // Validating an échéance opens this form pre-linked to the type — the
    // km field starts at the vehicle's current reading so the user just
    // confirms date / cost / garage.
    if (widget.existing == null && widget.defaultMaintenanceTypeId != null) {
      final km = ref.read(vehicleByIdProvider(widget.vehicleId))?.currentKm;
      if (km != null && km > 0) _km.text = km.toString();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _km.dispose();
    _cost.dispose();
    _liters.dispose();
    super.dispose();
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

  Future<void> _pickGarage() async {
    final garages = ref.read(garagesProvider).value ?? const <Garage>[];
    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: AuroraColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AuroraRadii.largeCard)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              title: Text('Aucun', style: AuroraText.listRowTitle(AuroraColors.ink)),
              onTap: () => Navigator.pop(sheetContext, ''),
            ),
            for (final g in garages)
              ListTile(
                title: Text(g.name, style: AuroraText.listRowTitle(AuroraColors.ink)),
                onTap: () => Navigator.pop(sheetContext, g.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _garageId = picked.isEmpty ? null : picked);
  }

  Future<void> _createGarage() async {
    final created = await showGarageFormSheet(context);
    if (created != null) setState(() => _garageId = created.id);
  }

  Future<void> _pickCategory() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AuroraColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AuroraRadii.largeCard)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final c in ExpenseCategories.all)
              ListTile(
                title: Text(ExpenseCategories.label(c), style: AuroraText.listRowTitle(AuroraColors.ink)),
                onTap: () => Navigator.pop(sheetContext, c),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _category = picked;
        if (_title.text.trim().isEmpty ||
            ExpenseCategories.all.any((c) => ExpenseCategories.label(c) == _title.text)) {
          _title.text = ExpenseCategories.label(picked);
        }
      });
    }
  }

  Future<void> _pickInvoice() async {
    final file = await pickAttachment(context);
    if (file != null) setState(() => _newInvoice = file);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AuroraColors.ink,
      content: Text(message, style: const TextStyle(color: AuroraColors.onDark)),
      action: SnackBarAction(label: 'OK', textColor: AuroraColors.accent, onPressed: () {}),
    ));
  }

  Future<void> _save() async {
    if (_isFuel) {
      if (_title.text.trim().isEmpty) _title.text = 'Plein de carburant';
    }
    if (_title.text.trim().isEmpty) {
      _showError('Le titre est requis.');
      return;
    }
    setState(() => _saving = true);
    try {
      var invoiceUrl = _existingInvoiceUrl;
      if (_newInvoice != null) {
        invoiceUrl = await ref.read(supabaseServiceProvider).uploadFile(
              bucket: Buckets.invoices,
              file: _newInvoice!,
              filename: buildUploadName('history-${widget.vehicleId}', _newInvoice!),
            );
      }

      String? garageName;
      if (_garageId != null) {
        final garages = ref.read(garagesProvider).value ?? const <Garage>[];
        for (final g in garages) {
          if (g.id == _garageId) {
            garageName = g.name;
            break;
          }
        }
      } else {
        garageName = widget.existing?.garageName;
      }

      final history = MaintenanceHistory(
        id: widget.existing?.id ?? '',
        vehicleId: widget.vehicleId,
        maintenanceTypeId: _kind == HistoryEntryKind.maintenance ? _maintenanceTypeId : null,
        title: _title.text.trim(),
        km: int.tryParse(_km.text.trim()),
        cost: double.tryParse(_cost.text.trim().replaceAll(',', '.')),
        garageName: _isFuel ? null : garageName,
        garageId: _isFuel ? null : _garageId,
        doneAt: _doneAt,
        invoiceUrl: invoiceUrl,
        kind: _kind,
        category: _isExpense ? _category : null,
        isFullTank: _isFuel ? _isFullTank : true,
        liters: _isFuel ? double.tryParse(_liters.text.trim().replaceAll(',', '.')) : null,
      );

      final controller = ref.read(maintenanceControllerProvider);
      if (_isEdit) {
        await controller.updateHistory(history);
      } else {
        await controller.addHistory(history);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showError(friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer "${widget.existing!.title}" ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(maintenanceControllerProvider)
          .deleteHistory(widget.vehicleId, widget.existing!.id, invoiceUrl: _existingInvoiceUrl);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showError(friendlyError(e));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuroraColors.bgTop,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.2079, -0.9781),
            end: Alignment(0.2079, 0.9781),
            colors: [AuroraColors.bgTop, AuroraColors.bgMid, AuroraColors.bgBottom],
            stops: [0, 0.58, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Row(
                  children: [
                    AuroraAppBarChip(
                      icon: PhosphorIconsRegular.x,
                      semanticLabel: 'Fermer',
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Nouvelle entrée',
                          style: AuroraText.cardTitle(AuroraColors.ink, size: 20)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuroraSegmentedControl<HistoryEntryKind>(
                        segments: const [
                          AuroraSegment(
                              value: HistoryEntryKind.maintenance,
                              label: 'Entretien',
                              icon: PhosphorIconsRegular.wrench),
                          AuroraSegment(
                              value: HistoryEntryKind.fuel,
                              label: 'Carburant',
                              icon: PhosphorIconsRegular.gasPump),
                          AuroraSegment(
                              value: HistoryEntryKind.expense,
                              label: 'Dépense',
                              icon: PhosphorIconsRegular.currencyEur),
                        ],
                        value: _kind,
                        onChanged: _isEdit ? (_) {} : (k) => setState(() => _kind = k),
                        selectedFill: AuroraColors.accent,
                        selectedText: AuroraColors.ink,
                        fontSize: 12,
                      ),
                      if (widget.linkedLabel != null && !_isEdit) ...[
                        const SizedBox(height: 14),
                        _LinkedBanner(label: widget.linkedLabel!),
                      ],
                      const SizedBox(height: 14),
                      _fieldCard(),
                      const SizedBox(height: 14),
                      _receiptCard(),
                      if (_isEdit) ...[
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: _saving ? null : _delete,
                            child: const Text('Supprimer cette entrée',
                                style: TextStyle(
                                  color: AuroraColors.muted,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AuroraColors.muted,
                                )),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldCard() {
    return AuroraCard(
      raised: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _isExpense ? _expenseFields() : _maintenanceOrFuelFields(),
      ),
    );
  }

  /// Dépense: Intitulé · Catégorie · Date · Coût — a flat sequence, no
  /// 2-up pairing (unlike Entretien/Carburant, which the spec explicitly
  /// calls out as "2-up" rows).
  List<Widget> _expenseFields() => [
        _textField(label: 'Intitulé', controller: _title),
        const SizedBox(height: 14),
        _categoryField(),
        const SizedBox(height: 14),
        _dateField(),
        const SizedBox(height: 14),
        _numberField(label: 'Coût', controller: _cost, suffix: Fmt.currencySuffix, decimal: true),
      ];

  /// Entretien: Intitulé (full) · [Date + Km] · [Coût + Garage] · "+
  /// Nouveau garage". Carburant: [Date + Km] · [Coût + Litres] · "Plein
  /// complet" — no Intitulé, no Garage.
  List<Widget> _maintenanceOrFuelFields() => [
        if (!_isFuel) ...[
          _textField(label: 'Intitulé', controller: _title),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(child: _dateField()),
            const SizedBox(width: 14),
            Expanded(child: _numberField(label: 'Kilométrage', controller: _km, suffix: 'km')),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
                child: _numberField(
                    label: 'Coût', controller: _cost, suffix: Fmt.currencySuffix, decimal: true)),
            const SizedBox(width: 14),
            Expanded(
              child: _isFuel
                  ? _numberField(label: 'Litres', controller: _liters, suffix: 'L', decimal: true)
                  : _garageField(),
            ),
          ],
        ),
        if (_isFuel) ...[
          const SizedBox(height: 10),
          _fullTankSwitch(),
        ] else ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _createGarage,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
              child: const Text('＋ Nouveau garage',
                  style: TextStyle(color: AuroraColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ];

  Widget _receiptCard() {
    final hasInvoice = _newInvoice != null || _existingInvoiceUrl != null;
    return AuroraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Justificatif',
              style: AuroraText.meta(AuroraColors.muted, size: 11).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 11),
          Row(
            children: [
              if (hasInvoice)
                AuroraImageSlot(
                  image: const ColoredBox(color: AuroraColors.accentTint32),
                  semanticLabel: 'Voir le justificatif',
                  onTap: _newInvoice != null
                      ? null
                      : () => FileViewerScreen.open(
                            context,
                            bucket: Buckets.invoices,
                            reference: _existingInvoiceUrl!,
                            title: _title.text.trim().isEmpty ? 'Justificatif' : _title.text.trim(),
                          ),
                ),
              if (hasInvoice) const SizedBox(width: 11),
              AuroraImageSlot(
                onTap: _pickInvoice,
                semanticLabel: hasInvoice ? 'Remplacer le justificatif' : 'Ajouter un justificatif',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      child: AuroraPrimaryButton(
        label: 'Enregistrer l\'entrée',
        onTap: _saving ? null : _save,
        busy: _saving,
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: AuroraText.meta(AuroraColors.muted, size: 11).copyWith(fontWeight: FontWeight.w600));

  InputDecoration _underlineDecoration({String? suffixText}) => InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: const UnderlineInputBorder(borderSide: BorderSide(color: AuroraColors.hairline)),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AuroraColors.hairline)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AuroraColors.accent, width: 1)),
        disabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AuroraColors.hairline)),
        suffixText: suffixText,
        suffixStyle: AuroraText.meta(AuroraColors.muted),
      );

  Widget _textField({required String label, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: AuroraText.bodyValue(AuroraColors.ink),
          decoration: _underlineDecoration(),
        ),
      ],
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    String? suffix,
    bool decimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          inputFormatters: decimal ? null : [FilteringTextInputFormatter.digitsOnly],
          style: AuroraText.bodyValue(AuroraColors.ink),
          decoration: _underlineDecoration(suffixText: suffix),
        ),
      ],
    );
  }

  Widget _dateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Date'),
        const SizedBox(height: 4),
        InkWell(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.only(bottom: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AuroraColors.hairline)),
            ),
            child: Text(Fmt.dateShort(_doneAt), style: AuroraText.bodyValue(AuroraColors.ink)),
          ),
        ),
      ],
    );
  }

  Widget _garageField() {
    final garages = ref.watch(garagesProvider).value ?? const <Garage>[];
    final name = garages.where((g) => g.id == _garageId).map((g) => g.name).firstOrNull ?? 'Aucun';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Garage'),
        const SizedBox(height: 4),
        InkWell(
          onTap: _pickGarage,
          child: Container(
            padding: const EdgeInsets.only(bottom: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AuroraColors.hairline)),
            ),
            child: Text(name, style: AuroraText.bodyValue(AuroraColors.ink)),
          ),
        ),
      ],
    );
  }

  Widget _categoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Catégorie'),
        const SizedBox(height: 4),
        InkWell(
          onTap: _pickCategory,
          child: Container(
            padding: const EdgeInsets.only(bottom: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AuroraColors.hairline)),
            ),
            child: Text(ExpenseCategories.label(_category), style: AuroraText.bodyValue(AuroraColors.ink)),
          ),
        ),
      ],
    );
  }

  Widget _fullTankSwitch() {
    return Row(
      children: [
        Expanded(
          child: Text('Plein complet',
              style: AuroraText.listRowTitle(AuroraColors.ink, size: 14)),
        ),
        Switch(
          value: _isFullTank,
          onChanged: (v) => setState(() => _isFullTank = v),
          activeThumbColor: AuroraColors.accent,
        ),
      ],
    );
  }
}

class _LinkedBanner extends StatelessWidget {
  const _LinkedBanner({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AuroraColors.accentTint12,
        borderRadius: BorderRadius.circular(AuroraRadii.smallCard),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(PhosphorIconsFill.linkSimple, size: 16, color: AuroraColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(color: AuroraColors.ink, fontSize: 12),
                children: [
                  const TextSpan(text: 'Lié à '),
                  TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const TextSpan(text: ' — l\'échéance sera remise à zéro.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
