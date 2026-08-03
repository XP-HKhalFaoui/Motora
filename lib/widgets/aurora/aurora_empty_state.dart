import 'package:flutter/material.dart';

import '../../core/aurora_theme.dart';

/// The spec's empty-state pattern, reused across every list: a 15/500
/// line, a 12/muted explainer, and an optional single accent text
/// action. No illustrations.
class AuroraEmptyState extends StatelessWidget {
  const AuroraEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: AuroraText.listRowTitle(aurora.textPrimary, size: 15)),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: AuroraText.meta(aurora.muted)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!,
                  style: AuroraText.sectionLabel(AuroraColors.accent, size: 13)),
            ),
          ],
        ],
      ),
    );
  }
}
