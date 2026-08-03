import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/aurora_theme.dart';
import '../../models/maintenance_history.dart';
import '../../screens/admin_documents/add_document_sheet.dart';
import '../../screens/new_entry/aurora_new_entry_screen.dart';
import '../../screens/vehicle_detail/update_km_sheet.dart';

/// Aurora's quick-add modal sheet ("Ajouter") — five one-tap gestures,
/// reachable from a global action on any tab.
///
/// "Réparation"/"Plein de carburant"/"Dépense" push the full-screen
/// [AuroraNewEntryScreen]. "Relevé kilométrique" and "Document scanné"
/// still open their existing, not-yet-restyled sheets — km readings and
/// documents are their own dedicated flows, outside New-entry's three
/// ledger types.
Future<void> showAuroraQuickAddSheet(BuildContext context, String vehicleId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // White tinted 10% by accent at 72% opacity — the spec's scrim.
    // Approximates the spec's separate "page drops to 25% opacity" too:
    // over Aurora's light ground, a translucent near-white wash reads the
    // same as fading the content toward white. Precise entrance timing
    // (260ms easeOutCubic / 180ms scrim fade) is a step-5 behavior-pass
    // concern — this uses the platform's default sheet transition.
    barrierColor:
        Color.alphaBlend(AuroraColors.accent.withValues(alpha: .10), Colors.white)
            .withValues(alpha: .72),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => _QuickAddSheet(vehicleId: vehicleId),
  );
}

class _QuickAddSheet extends StatelessWidget {
  const _QuickAddSheet({required this.vehicleId});
  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AuroraColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: AuroraShadows.bottomSheet,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AuroraColors.hairlineStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Ajouter', style: AuroraText.cardTitle(AuroraColors.ink, size: 19)),
              const SizedBox(height: 2),
              Text("Cinq gestes, depuis n'importe quel écran",
                  style: AuroraText.meta(AuroraColors.muted)),
              const SizedBox(height: 16),
              _PromotedRow(
                icon: PhosphorIconsFill.gauge,
                title: 'Relevé kilométrique',
                subtitle: 'Saisie ou photo du compteur',
                onTap: () {
                  Navigator.pop(context);
                  showUpdateKmSheet(context, vehicleId);
                },
              ),
              const SizedBox(height: 9),
              _PlainRow(
                icon: PhosphorIconsFill.wrench,
                title: 'Réparation',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuroraNewEntryScreen(vehicleId: vehicleId),
                    ),
                  );
                },
              ),
              const SizedBox(height: 9),
              _PlainRow(
                icon: PhosphorIconsFill.gasPump,
                title: 'Plein de carburant',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuroraNewEntryScreen(
                        vehicleId: vehicleId,
                        kind: HistoryEntryKind.fuel,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 9),
              _PlainRow(
                icon: PhosphorIconsFill.currencyEur,
                title: 'Dépense',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuroraNewEntryScreen(
                        vehicleId: vehicleId,
                        kind: HistoryEntryKind.expense,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 9),
              _PlainRow(
                icon: PhosphorIconsFill.fileText,
                title: 'Document scanné',
                onTap: () {
                  Navigator.pop(context);
                  showAddDocumentSheet(context, vehicleId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromotedRow extends StatelessWidget {
  const _PromotedRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final PhosphorIconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AuroraRadii.smallCard),
        boxShadow: AuroraShadows.accentButton,
      ),
      child: Material(
        color: AuroraColors.accent,
        borderRadius: BorderRadius.circular(AuroraRadii.smallCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AuroraRadii.smallCard),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AuroraColors.ink.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(AuroraRadii.iconChipLarge),
                  ),
                  child: Icon(icon, size: 19, color: AuroraColors.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: AuroraColors.ink, fontSize: 15, fontWeight: FontWeight.w600)),
                      Text(subtitle,
                          style: TextStyle(color: AuroraColors.ink.withValues(alpha: .8), fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(PhosphorIconsRegular.arrowRight, size: 18, color: AuroraColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlainRow extends StatelessWidget {
  const _PlainRow({required this.icon, required this.title, required this.onTap});
  final PhosphorIconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AuroraColors.accentTint08,
      borderRadius: BorderRadius.circular(AuroraRadii.smallCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AuroraRadii.smallCard),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AuroraColors.card,
                  borderRadius: BorderRadius.all(Radius.circular(AuroraRadii.iconChipLarge)),
                ),
                child: Icon(icon, size: 18, color: AuroraColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: AuroraColors.ink, fontSize: 15, fontWeight: FontWeight.w500)),
              ),
              const Icon(PhosphorIconsRegular.caretRight, size: 16, color: AuroraColors.iconMutedOnWhite),
            ],
          ),
        ),
      ),
    );
  }
}
