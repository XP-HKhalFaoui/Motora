import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/reminder.dart';
import '../../providers/notification_provider.dart';
import '../notifications/notifications_screen.dart';

/// Compact "what's urgent now" banner shown at the top of the home list.
class AlertsBanner extends ConsumerWidget {
  const AlertsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];
    if (reminders.isEmpty) return const SizedBox.shrink();

    final overdue = reminders.where((r) => r.isOverdue).length;
    final top = reminders.take(3).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2A1E), AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                overdue > 0
                    ? '$overdue échéance(s) dépassée(s)'
                    : '${reminders.length} échéance(s) à venir',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
                child: const Text('Tout voir'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...top.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      r.kind == ReminderKind.document
                          ? Icons.description_outlined
                          : Icons.build_outlined,
                      size: 16,
                      color: r.isOverdue ? AppColors.danger : AppColors.warn,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(r.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13))),
                    Text(r.body,
                        style: TextStyle(
                            fontSize: 12,
                            color: r.isOverdue
                                ? AppColors.danger
                                : AppColors.textMuted)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
