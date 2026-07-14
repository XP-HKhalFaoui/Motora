import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';

/// Create (or edit, when [existing] is provided) a vehicle.
class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.existing});
  final Vehicle? existing;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _brand = TextEditingController(text: widget.existing?.brand);
  late final _model = TextEditingController(text: widget.existing?.model);
  late final _year =
      TextEditingController(text: widget.existing?.year?.toString());
  late final _plate = TextEditingController(text: widget.existing?.plateNumber);
  late final _km =
      TextEditingController(text: '${widget.existing?.currentKm ?? 0}');
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    for (final c in [_name, _brand, _model, _year, _plate, _km]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await ref.read(vehiclesProvider.notifier).updateVehicle(widget.existing!.id, {
          'name': _name.text.trim(),
          'brand': _text(_brand),
          'model': _text(_model),
          'year': int.tryParse(_year.text.trim()),
          'plate_number': _text(_plate),
        });
      } else {
        final vehicle = Vehicle(
          id: '',
          userId: '',
          name: _name.text.trim(),
          brand: _text(_brand),
          model: _text(_model),
          year: int.tryParse(_year.text.trim()),
          plateNumber: _text(_plate),
          currentKm: int.tryParse(_km.text.trim()) ?? 0,
        );
        await ref.read(vehiclesProvider.notifier).add(vehicle);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
        setState(() => _saving = false);
      }
    }
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
          title: Text(_isEdit ? 'Modifier le véhicule' : 'Nouveau véhicule')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              style: TextStyle(color: p.textPrimary),
              decoration: const InputDecoration(
                  labelText: 'Nom *', hintText: 'Clio 4, Voiture femme…'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _brand,
                  style: TextStyle(color: p.textPrimary),
                  decoration: const InputDecoration(labelText: 'Marque'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _model,
                  style: TextStyle(color: p.textPrimary),
                  decoration: const InputDecoration(labelText: 'Modèle'),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _year,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: p.textPrimary),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Année'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _plate,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(color: p.textPrimary),
                  decoration:
                      const InputDecoration(labelText: 'Immatriculation'),
                ),
              ),
            ]),
            if (!_isEdit) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _km,
                keyboardType: TextInputType.number,
                style: TextStyle(color: p.textPrimary),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    const InputDecoration(labelText: 'Kilométrage actuel'),
              ),
            ],
            const SizedBox(height: 28),
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
      ),
    );
  }
}
