import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/aurora_theme.dart';
import '../../core/errors.dart';
import '../../models/vehicle.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/aurora/aurora_card.dart';
import '../garages/garages_screen.dart';
import '../home/vehicle_form_screen.dart';
import '../notifications/notifications_screen.dart';
import '../shell/section_screen.dart';
import '../vehicle_detail/sections/documents_section.dart';

/// Paramètres, restyled to Aurora and reshaped as a left-hand slide-out
/// drawer (per the "Car Service App" reference's menu pattern) rather
/// than a pushed full-screen route: a dark hero header (greeting +
/// email), a row of quick-action tiles, then grouped list sections — the
/// same content as the pre-Aurora `SettingsScreen`, adapted to what
/// Motora actually has (no ads/payments/analytics — vehicles, garages,
/// alert thresholds, documents instead).
///
/// Attached as `Scaffold.drawer` on the shared shell
/// (`AuroraTabChrome`), so it opens from any tab via a left-edge swipe or
/// `Scaffold.of(context).openDrawer()` (Due's sliders chip).
class AuroraSettingsDrawer extends ConsumerWidget {
  const AuroraSettingsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aurora = context.aurora;
    final user = ref.watch(currentUserProvider);
    final vehicles = ref.watch(vehiclesProvider).value ?? const <Vehicle>[];
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.value;
    final vehicleId = ref.watch(effectiveSelectedVehicleIdProvider);

    // A stock Drawer defaults to a fixed 304px width; widened here so it
    // reads like the reference's near-full-width slide-out, with a
    // narrow sliver of the tab behind it still visible on the right —
    // Flutter's own scrim-over-content is used for the dim rather than
    // the reference's scaled/rounded peek, which would need a bespoke
    // Scaffold-level transform for a navigation affordance, not one of
    // the spec's six pixel-exact screens.
    return Drawer(
      width: MediaQuery.sizeOf(context).width - 48,
      backgroundColor: aurora.groundStart,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: aurora.screenGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AuroraSpacing.screenPaddingH, 12, AuroraSpacing.screenPaddingH, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Scaffold.of(context).closeDrawer(),
                    icon: Icon(PhosphorIconsRegular.caretDown, color: aurora.textPrimary),
                  ),
                  Expanded(
                    child: Text('Paramètres', style: AuroraText.screenTitle(aurora.textPrimary)),
                  ),
                ],
              ),
              const SizedBox(height: AuroraSpacing.blockGap),
              _HeroHeader(email: user?.email),
              const SizedBox(height: AuroraSpacing.blockGap),
              _QuickActions(vehicleId: vehicleId),
              const SizedBox(height: 22),
              const _SectionLabel('MON COMPTE'),
              AuroraCard(
                child: Column(
                  children: [
                    for (final v in vehicles)
                      _Row(
                        icon: PhosphorIconsFill.carProfile,
                        label: v.name,
                        trailing: v.plateNumber,
                        trailingAction: IconButton(
                          icon: const Icon(PhosphorIconsRegular.trash, size: 20, color: Colors.red),
                          tooltip: 'Supprimer ${v.name}',
                          onPressed: () => _confirmDeleteVehicle(context, ref, v),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => VehicleFormScreen(existing: v)),
                        ),
                      ),
                    _Row(
                      icon: PhosphorIconsFill.plus,
                      label: 'Ajouter un véhicule',
                      accentLabel: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _SectionLabel('GARAGES'),
              AuroraCard(
                child: _Row(
                  icon: PhosphorIconsFill.wrench,
                  label: 'Mes garages',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GaragesScreen()),
                  ),
                ),
              ),
              if (settings != null) ...[
                const SizedBox(height: 22),
                const _SectionLabel('ALERTES & SEUILS'),
                AuroraCard(
                  child: Column(
                    children: [
                      _ValueRow(
                        icon: PhosphorIconsFill.gauge,
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
                        icon: PhosphorIconsFill.calendarCheck,
                        label: 'Seuil échéance',
                        sublabel: 'Papiers & visites',
                        value: '${settings.daysAlertThreshold} jours',
                        onTap: () async {
                          final v = await _promptNumber(
                              context, 'Seuil échéance (jours)', settings.daysAlertThreshold);
                          if (v != null) {
                            await ref.read(settingsProvider.notifier).setDaysThreshold(v);
                          }
                        },
                      ),
                      _SwitchRow(
                        icon: PhosphorIconsFill.bellRinging,
                        label: 'Notifications push',
                        value: settings.pushEnabled,
                        onChanged: (v) => ref.read(settingsProvider.notifier).setPushEnabled(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionLabel('PRÉFÉRENCES'),
                AuroraCard(
                  child: _SegmentRow<ThemeMode>(
                    label: 'Thème',
                    value: settings.themeMode,
                    options: const {
                      ThemeMode.system: 'Système',
                      ThemeMode.light: 'Clair',
                      ThemeMode.dark: 'Sombre',
                    },
                    onChanged: (m) => ref.read(settingsProvider.notifier).setThemeMode(m),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              const _SectionLabel('À PROPOS'),
              AuroraCard(
                child: _ValueRow(
                  icon: PhosphorIconsFill.info,
                  label: 'Version',
                  sublabel: 'Motora',
                  value: ref.watch(appVersionProvider).value ?? '…',
                  onTap: null,
                ),
              ),
              const SizedBox(height: 26),
              Center(
                child: TextButton(
                  onPressed: () => ref.read(sessionControllerProvider).signOut(),
                  child: const Text('Se déconnecter',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => _confirmDeleteAccount(context, ref),
                  child: Text('Supprimer mon compte',
                      style: TextStyle(
                        color: aurora.muted,
                        decoration: TextDecoration.underline,
                        decorationColor: aurora.muted,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(sessionControllerProvider).deleteAccount();
      navigator.popUntil((r) => r.isFirst);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  Future<void> _confirmDeleteVehicle(BuildContext context, WidgetRef ref, Vehicle v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer ${v.name} ?'),
        content: const Text(
            'Cette action supprime aussi tout son historique : relevés km, '
            'entretiens, réparations et documents. Elle est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(vehiclesProvider.notifier).remove(v.id);
    }
  }

  Future<int?> _promptNumber(BuildContext context, String title, int initial) async {
    final controller = TextEditingController(text: '$initial');
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, keyboardType: TextInputType.number, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.email});
  final String? email;

  @override
  Widget build(BuildContext context) {
    final name = (email == null || email!.isEmpty) ? '' : email!.split('@').first;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return AuroraDarkCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AuroraColors.accent),
            child: Text(initial,
                style: AuroraText.cardTitle(AuroraColors.ink, size: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bonjour $name', style: AuroraText.cardTitle(AuroraColors.onDark, size: 17)),
                const SizedBox(height: 2),
                Text(email ?? '', style: TextStyle(color: AuroraColors.onDarkSecondary(), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.vehicleId});
  final String? vehicleId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: PhosphorIconsFill.plus,
            label: 'Véhicule',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: PhosphorIconsFill.bell,
            label: 'Alertes',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: PhosphorIconsFill.wrench,
            label: 'Garages',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GaragesScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: PhosphorIconsFill.fileText,
            label: 'Documents',
            onTap: vehicleId == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SectionScreen(title: 'Documents', child: DocumentsSection(vehicleId: vehicleId!)),
                      ),
                    ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final PhosphorIconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AuroraRadii.smallCard),
      child: Opacity(
        opacity: enabled ? 1 : .4,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: aurora.card,
                borderRadius: BorderRadius.circular(AuroraRadii.smallCard),
                boxShadow: aurora.useCardShadows ? AuroraShadows.cardSoft : null,
                border: aurora.useCardShadows ? null : Border.all(color: AuroraColors.darkHairlineBorder),
              ),
              child: Icon(icon, size: 19, color: AuroraColors.accent),
            ),
            const SizedBox(height: 6),
            Text(label, style: AuroraText.meta(aurora.muted, size: 10)),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(text, style: AuroraText.sectionLabel(context.aurora.muted)),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.trailing,
    this.trailingAction,
    this.accentLabel = false,
    this.onTap,
  });

  final PhosphorIconData icon;
  final String label;
  final String? trailing;
  final Widget? trailingAction;
  final bool accentLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: accentLabel ? AuroraColors.accent : aurora.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    color: accentLabel ? AuroraColors.accent : aurora.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  )),
            ),
            if (trailing != null && trailing!.isNotEmpty)
              Text(trailing!, style: AuroraText.meta(aurora.muted)),
            if (trailingAction != null) ...[const SizedBox(width: 8), trailingAction!],
            if (onTap != null && trailingAction == null) ...[
              const SizedBox(width: 4),
              Icon(PhosphorIconsRegular.caretRight, size: 16, color: aurora.iconMutedOnWhite),
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
    this.icon,
    this.onTap,
  });
  final String label;
  final String sublabel;
  final String value;
  final PhosphorIconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: aurora.muted),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: aurora.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(sublabel, style: AuroraText.meta(aurora.muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AuroraColors.accentTint14,
                borderRadius: BorderRadius.circular(AuroraRadii.pill),
              ),
              child: Text(value, style: AuroraText.tabularValue(AuroraColors.accent, size: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.value, required this.onChanged, this.icon});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final PhosphorIconData? icon;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: aurora.muted),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(label,
                style:
                    TextStyle(color: aurora.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AuroraColors.accent),
        ],
      ),
    );
  }
}

class _SegmentRow<T> extends StatelessWidget {
  const _SegmentRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    // A row was too narrow once Settings became a drawer (~48px slimmer
    // than the full-page screen this was designed for): three segments'
    // worth of tap targets left the label almost no room and it wrapped
    // mid-word. Stacking the label above the (now full-width) segments
    // avoids fighting that width for good, regardless of screen size.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: aurora.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AuroraColors.neutralChip,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                for (final entry in options.entries)
                  Expanded(child: _tab(context, entry.value, entry.key)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, String label, T optionValue) {
    final active = value == optionValue;
    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: InkWell(
        onTap: () => onChanged(optionValue),
        borderRadius: BorderRadius.circular(7),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? AuroraColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(label,
              style: TextStyle(
                  color: active ? AuroraColors.onDark : context.aurora.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  static const _word = 'SUPPRIMER';
  final _controller = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _controller.text.trim().toUpperCase() == _word;

    return AlertDialog(
      title: const Text('Supprimer votre compte ?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vos véhicules, entretiens, relevés, documents, garages et '
            'fichiers seront définitivement effacés. Cette action est '
            'irréversible et ne peut pas être annulée.',
          ),
          const SizedBox(height: 16),
          const Text('Tapez « $_word » pour confirmer.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: _word),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: matches && !_busy
              ? () {
                  setState(() => _busy = true);
                  Navigator.pop(context, true);
                }
              : null,
          child: Text('Supprimer définitivement',
              style: TextStyle(color: matches ? Colors.red : Colors.grey)),
        ),
      ],
    );
  }
}
