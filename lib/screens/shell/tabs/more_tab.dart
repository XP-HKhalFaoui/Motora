import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_text.dart';
import '../../../core/theme.dart';
import '../../garages/garages_screen.dart';
import '../../reports/reports_screen.dart';
import '../../settings/settings_screen.dart';
import '../../vehicle_detail/sections/documents_section.dart';
import '../../vehicle_detail/sections/fuel_section.dart';
import '../../vehicle_detail/sections/mileage_section.dart';
import '../section_screen.dart';

/// "Plus" tab — everything that doesn't earn a permanent slot.
///
/// This is the redesign's safety net. Seven destinations used to have a
/// single entry point each, and those entry points were the vehicle hub
/// and the old home screen. Anything not promoted to a tab is listed
/// here, or it would simply become unreachable.
class MoreTab extends ConsumerWidget {
  const MoreTab({super.key, required this.vehicleId});

  /// Null when the account has no vehicle: the vehicle-scoped rows are
  /// hidden rather than opening screens with nothing to show.
  final String? vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final id = vehicleId;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        if (id != null) ...[
          _label(context, 'CE VÉHICULE'),
          _Group(children: [
            _Row(
              icon: Icons.query_stats,
              color: p.primary,
              label: 'Rapports',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReportsScreen(vehicleId: id)),
              ),
            ),
            _Row(
              icon: Icons.local_gas_station,
              color: p.entryFuel,
              label: 'Carburant',
              onTap: () =>
                  _section(context, 'Carburant', FuelSection(vehicleId: id)),
            ),
            _Row(
              icon: Icons.speed,
              color: p.entryMileage,
              label: 'Kilométrage',
              onTap: () => _section(
                  context, 'Kilométrage', MileageSection(vehicleId: id)),
            ),
            _Row(
              icon: Icons.description,
              color: p.entryDocument,
              label: 'Documents',
              onTap: () => _section(
                  context, 'Documents', DocumentsSection(vehicleId: id)),
            ),
          ]),
          const SizedBox(height: 22),
        ],
        _label(context, 'GÉNÉRAL'),
        _Group(children: [
          _Row(
            icon: Icons.store_mall_directory,
            color: p.entryMaintenance,
            label: 'Mes garages',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GaragesScreen()),
            ),
          ),
          _Row(
            icon: Icons.settings,
            color: p.textSecondary,
            label: 'Paramètres',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ]),
      ],
    );
  }

  void _section(BuildContext context, String title, Widget child) =>
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SectionScreen(title: title, child: child)),
      );

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text,
            style: AppText.sectionLabel(context.palette.textSecondary)),
      );
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
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, indent: 60, color: p.border),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, size: 17, color: p.onEntryBadge),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.chevron_right, size: 20, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}
