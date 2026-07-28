import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/admin_document.dart';
import '../providers/settings_provider.dart';
import 'storage_image.dart';

/// Document administratif card: scan thumbnail (or placeholder) on the
/// left, type/status/expiry on the right — screen 06.
class DocumentCard extends ConsumerWidget {
  const DocumentCard({
    super.key,
    required this.doc,
    this.onTap,
  });

  final AdminDocument doc;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final days = doc.daysToExpiry;
    // The user's own "alerte échéance" setting, not the compile-time
    // default — the Réglages screen let you change it but nothing read it.
    final alertDays = ref.watch(settingsProvider).value?.daysAlertThreshold ??
        Thresholds.daysAlert;
    final urgency = doc.isExpired
        ? 1.0
        : (1 - (days / (alertDays * 2))).clamp(0.0, 1.0);
    final color = statusColorFor(p, urgency);
    final hasFile = doc.fileUrl != null;

    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: .3))),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The real scan, not a placeholder. This used to render a
                // StripedPlaceholder labelled "scan" precisely *when* a file
                // existed, so the uploaded document was never once visible.
                SizedBox(
                  width: 76,
                  child: StorageImage(
                    bucket: Buckets.adminDocuments,
                    reference: doc.fileUrl,
                    fallback: Container(
                      color: p.background,
                      alignment: Alignment.center,
                      child: Icon(
                        hasFile
                            ? Icons.description_outlined
                            : Icons.add_a_photo_outlined,
                        color: p.textMuted,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(_iconFor(doc.docType), size: 20, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(DocTypes.label(doc.docType),
                                  style: TextStyle(
                                      color: p.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                  _statusLabel(days, hasFile, alertDays),
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Année ${doc.year}',
                            style: TextStyle(
                                color: p.textSecondary, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(
                          doc.isExpired
                              ? 'Expiré depuis le ${Fmt.dateShort(doc.expiryDate)}'
                              : 'Échéance ${Fmt.dateShort(doc.expiryDate)}',
                          style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(int days, bool hasFile, int alertDays) {
    if (doc.isExpired) return 'EXPIRÉ';
    if (!hasFile) return 'À FAIRE';
    if (days < alertDays) return 'EXPIRE $days J';
    return 'VALIDE';
  }

  IconData _iconFor(String type) {
    switch (type) {
      case DocTypes.vignette:
        return Icons.local_activity_outlined;
      case DocTypes.assurance:
        return Icons.verified_user_outlined;
      case DocTypes.controleTechnique:
        return Icons.fact_check_outlined;
      case DocTypes.carteGrise:
        return Icons.badge_outlined;
      default:
        return Icons.description_outlined;
    }
  }
}
