import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../providers/vehicle_provider.dart';

/// Bottom sheet to record a new odometer reading.
Future<void> showUpdateKmSheet(BuildContext context, String vehicleId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _UpdateKmSheet(vehicleId: vehicleId),
  );
}

class _UpdateKmSheet extends ConsumerStatefulWidget {
  const _UpdateKmSheet({required this.vehicleId});
  final String vehicleId;

  @override
  ConsumerState<_UpdateKmSheet> createState() => _UpdateKmSheetState();
}

class _UpdateKmSheetState extends ConsumerState<_UpdateKmSheet> {
  final _km = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _km.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(int currentKm) async {
    final value = int.tryParse(_km.text.trim());
    if (value == null) {
      setState(() => _error = 'Entrez un nombre valide');
      return;
    }
    if (value < currentKm) {
      setState(() =>
          _error = 'Le km doit être ≥ ${Fmt.km(currentKm)} (relevé actuel)');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(vehiclesProvider.notifier).addMileage(
            widget.vehicleId,
            value,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
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
    final vehicle = ref.watch(vehicleByIdProvider(widget.vehicleId));
    final currentKm = vehicle?.currentKm ?? 0;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Nouveau relevé kilométrique',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Relevé actuel : ${Fmt.km(currentKm)}',
              style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          TextField(
            controller: _km,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Kilométrage',
              prefixIcon: Icon(Icons.speed),
              suffixText: 'km',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Note (optionnel)',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _saving ? null : () => _save(currentKm),
            icon: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
