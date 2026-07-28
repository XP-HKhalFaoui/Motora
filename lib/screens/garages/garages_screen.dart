import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_text.dart';
import '../../core/theme.dart';
import '../../models/garage.dart';
import '../../providers/garage_provider.dart';
import '../../widgets/async_value_view.dart';
import 'garage_form_sheet.dart';

/// "Mes garages": the directory of the user's repair shops. Each card shows
/// contact details (tap-to-call / tap-to-map) and how many interventions
/// have been logged there.
class GaragesScreen extends ConsumerWidget {
  const GaragesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final garagesAsync = ref.watch(garagesProvider);
    final counts = ref.watch(garageCountsProvider).value ?? const {};

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: const Text('Mes garages')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showGarageFormSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Garage'),
      ),
      body: AsyncValueView(
        value: garagesAsync,
        onRetry: () => ref.invalidate(garagesProvider),
        data: (garages) {
          if (garages.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
              children: [
                Icon(Icons.store_mall_directory_outlined,
                    size: 48, color: p.textMuted),
                const SizedBox(height: 14),
                Text(
                  'Aucun garage enregistré.\nAjoutez vos mécaniciens pour les '
                  'lier à vos interventions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textMuted, height: 1.4),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: garages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final g = garages[i];
              return _GarageCard(garage: g, interventions: counts[g.id] ?? 0);
            },
          );
        },
      ),
    );
  }
}

class _GarageCard extends StatelessWidget {
  const _GarageCard({required this.garage, required this.interventions});
  final Garage garage;
  final int interventions;

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showGarageFormSheet(context, existing: garage),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: p.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.store_mall_directory,
                        color: p.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(garage.name,
                        style: AppText.screenTitle(p.textPrimary, size: 17)),
                  ),
                  Icon(Icons.chevron_right, color: p.textMuted, size: 20),
                ],
              ),
              if (garage.phone != null || garage.address != null) ...[
                const SizedBox(height: 12),
                if (garage.phone != null)
                  _ContactRow(
                    icon: Icons.phone_outlined,
                    text: garage.phone!,
                    color: p.primary,
                    onTap: () => _launch(
                        Uri(scheme: 'tel', path: garage.phone!.replaceAll(' ', ''))),
                  ),
                if (garage.address != null) ...[
                  if (garage.phone != null) const SizedBox(height: 8),
                  _ContactRow(
                    icon: Icons.place_outlined,
                    text: garage.address!,
                    color: p.textSecondary,
                    onTap: () => _launch(Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(garage.address!)}')),
                  ),
                ],
              ],
              if (garage.note != null) ...[
                const SizedBox(height: 10),
                Text(garage.note!,
                    style: TextStyle(color: p.textSecondary, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: p.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  interventions == 0
                      ? 'Aucune intervention'
                      : '$interventions intervention${interventions > 1 ? 's' : ''}',
                  style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.text,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: color,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
