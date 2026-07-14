import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_text.dart';
import '../../core/theme.dart';
import '../../models/vehicle.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/async_value_view.dart';
import '../home/vehicle_form_screen.dart';

/// Paramètres (screen 09): profile, vehicles, alert thresholds,
/// preferences (unit + theme), sign out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final user = ref.watch(currentUserProvider);
    final vehicles = ref.watch(vehiclesProvider).value ?? const [];
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: const Text('Paramètres')),
      body: AsyncValueView(
        value: settingsAsync,
        data: (settings) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: p.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.surfaceElevated,
                    ),
                    child: Text(_initials(user?.email),
                        style: AppText.odometer(p.primary, size: 17)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.email?.split('@').first ?? '',
                            style: TextStyle(
                                color: p.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        Text(user?.email ?? '',
                            style: TextStyle(
                                color: p.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel('VÉHICULES'),
            _Group(children: [
              ...vehicles.map((v) => _Row(
                    icon: Icons.directions_car,
                    label: v.name,
                    trailing: v.plateNumber ?? '',
                    trailingAction: IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: p.danger),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDeleteVehicle(context, ref, v),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => VehicleFormScreen(existing: v)),
                    ),
                  )),
              _Row(
                icon: Icons.add_circle,
                iconColor: p.primary,
                label: 'Ajouter un véhicule',
                labelColor: p.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
                ),
              ),
            ]),
            const SizedBox(height: 22),
            _SectionLabel('ALERTES & SEUILS'),
            _Group(children: [
              _ValueRow(
                label: 'Seuil kilométrique',
                sublabel: 'Alerter sous ce reste',
                value: '${settings.kmAlertThreshold} km',
                onTap: () async {
                  final v = await _promptNumber(
                      context, 'Seuil kilométrique (km)', settings.kmAlertThreshold);
                  if (v != null) {
                    await ref.read(settingsProvider.notifier).setKmThreshold(v);
                  }
                },
              ),
              _ValueRow(
                label: 'Seuil échéance',
                sublabel: 'Papiers & visites',
                value: '${settings.daysAlertThreshold} jours',
                onTap: () async {
                  final v = await _promptNumber(context, 'Seuil échéance (jours)',
                      settings.daysAlertThreshold);
                  if (v != null) {
                    await ref.read(settingsProvider.notifier).setDaysThreshold(v);
                  }
                },
              ),
              _SwitchRow(
                label: 'Notifications push',
                value: settings.pushEnabled,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setPushEnabled(v),
              ),
            ]),
            const SizedBox(height: 22),
            _SectionLabel('PRÉFÉRENCES'),
            _Group(children: [
              _UnitRow(
                unit: settings.distanceUnit,
                onChanged: (u) =>
                    ref.read(settingsProvider.notifier).setDistanceUnit(u),
              ),
              _SwitchRow(
                label: 'Thème sombre',
                value: settings.themeMode == ThemeMode.dark,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).toggleDarkMode(v),
              ),
            ]),
            const SizedBox(height: 26),
            OutlinedButton.icon(
              onPressed: () => ref.read(authControllerProvider).signOut(),
              icon: Icon(Icons.logout, color: p.danger),
              label: Text('Se déconnecter', style: TextStyle(color: p.danger)),
              style: OutlinedButton.styleFrom(
                  side: BorderSide(color: p.danger.withValues(alpha: .3))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteVehicle(
      BuildContext context, WidgetRef ref, Vehicle v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer ${v.name} ?'),
        content: const Text(
            'Cette action supprime aussi tout son historique : relevés km, '
            'entretiens, réparations et documents. Elle est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer',
                style: TextStyle(color: context.palette.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(vehiclesProvider.notifier).remove(v.id);
    }
  }

  String _initials(String? email) {
    if (email == null || email.isEmpty) return '?';
    return email[0].toUpperCase();
  }

  Future<int?> _promptNumber(
      BuildContext context, String title, int initial) async {
    final controller = TextEditingController(text: '$initial');
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: AppText.sectionLabel(context.palette.textSecondary)),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++)
            Container(
              decoration: BoxDecoration(
                border: Border(
                    bottom: i == children.length - 1
                        ? BorderSide.none
                        : BorderSide(color: p.border)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: children[i],
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.iconColor,
    this.labelColor,
    this.trailing,
    this.trailingAction,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? labelColor;
  final String? trailing;
  final Widget? trailingAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor ?? p.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: labelColor ?? p.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
            if (trailing != null && trailing!.isNotEmpty)
              Text(trailing!,
                  style: TextStyle(color: p.textSecondary, fontSize: 12)),
            if (trailingAction != null) ...[
              const SizedBox(width: 8),
              trailingAction!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.sublabel,
    required this.value,
    this.onTap,
  });

  final String label;
  final String sublabel;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(sublabel,
                      style: TextStyle(color: p.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: p.background,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(value,
                  style: AppText.technical(p.primary, size: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: p.primary,
          ),
        ],
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({required this.unit, required this.onChanged});
  final DistanceUnit unit;
  final ValueChanged<DistanceUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Text('Unité de distance',
                style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: p.background,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                _unitTab(context, 'km', DistanceUnit.km),
                _unitTab(context, 'miles', DistanceUnit.miles),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitTab(BuildContext context, String label, DistanceUnit value) {
    final p = context.palette;
    final active = unit == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? p.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : p.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}
