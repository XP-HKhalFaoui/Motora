import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/admin_document.dart';
import 'striped_placeholder.dart';

/// Document administratif card: scan thumbnail (or placeholder) on the
/// left, type/status/expiry on the right — screen 06.
class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.doc,
    this.onTap,
  });

  final AdminDocument doc;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final days = doc.daysToExpiry;
    final urgency = doc.isExpired
        ? 1.0
        : (1 - (days / (Thresholds.daysAlert * 2))).clamp(0.0, 1.0);
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
                SizedBox(
                  width: 76,
                  child: hasFile
                      ? const StripedPlaceholder(label: 'scan')
                      : Container(
                          color: p.background,
                          child: Icon(Icons.add_a_photo_outlined,
                              color: p.textMuted, size: 22),
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
                              child: Text(_statusLabel(days, hasFile),
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

  String _statusLabel(int days, bool hasFile) {
    if (doc.isExpired) return 'EXPIRÉ';
    if (!hasFile) return 'À FAIRE';
    if (days < Thresholds.daysAlert) return 'EXPIRE $days J';
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
      default:
        return Icons.description_outlined;
    }
  }
}
