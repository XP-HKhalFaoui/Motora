import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/admin_document.dart';

class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.doc,
    this.onTap,
    this.onOpenFile,
  });

  final AdminDocument doc;
  final VoidCallback? onTap;
  final VoidCallback? onOpenFile;

  @override
  Widget build(BuildContext context) {
    final days = doc.daysToExpiry;
    final urgency = doc.isExpired
        ? 1.0
        : (1 - (days / (Thresholds.daysAlert * 2))).clamp(0.0, 1.0);
    final color = statusColor(urgency.toDouble());

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFor(doc.docType), color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${DocTypes.label(doc.docType)} · ${doc.year}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Expire le ${Fmt.dateShort(doc.expiryDate)}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    doc.isExpired ? 'Expiré' : Fmt.relative(doc.expiryDate),
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                  if (doc.fileUrl != null && onOpenFile != null)
                    TextButton(
                      onPressed: onOpenFile,
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text('Voir scan'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case DocTypes.vignette:
        return Icons.local_offer_outlined;
      case DocTypes.assurance:
        return Icons.shield_outlined;
      case DocTypes.controleTechnique:
        return Icons.build_circle_outlined;
      default:
        return Icons.description_outlined;
    }
  }
}
