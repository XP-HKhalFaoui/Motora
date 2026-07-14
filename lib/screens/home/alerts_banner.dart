import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_text.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/reminder.dart';
import '../../providers/notification_provider.dart';

/// "N alertes prioritaires" card at the top of Accueil — screen 02.
class AlertsBanner extends ConsumerWidget {
  const AlertsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];
    if (reminders.isEmpty) return const SizedBox.shrink();

    final sorted = [...reminders]..sort((a, b) => a.when.compareTo(b.when));
    final top = sorted.take(3).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.accent.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: p.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                '${reminders.length} alerte${reminders.length > 1 ? 's' : ''} prioritaire${reminders.length > 1 ? 's' : ''}',
                style: TextStyle(
                    color: p.accent, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          ...top.map((r) => Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: p.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: r.isOverdue ? p.danger : p.warn,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: p.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(r.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: p.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      r.isOverdue ? 'en retard' : Fmt.relative(r.when),
                      textAlign: TextAlign.right,
                      style: AppText.technical(
                          r.isOverdue ? p.danger : p.warn, size: 13),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
