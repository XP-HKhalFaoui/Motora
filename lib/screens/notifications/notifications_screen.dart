import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_text.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/reminder.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/async_value_view.dart';

/// Local, ephemeral "read" state — the schema has no `is_read` column, so
/// this resets on app restart (flagged as a simplification in the plan).
final _readIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Notifications (screen 08): "Aujourd'hui" / "Cette semaine" groups.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final remindersAsync = ref.watch(remindersProvider);
    final readIds = ref.watch(_readIdsProvider);

    return Container(
      color: p.background,
      child: SafeArea(
        bottom: false,
        child: AsyncValueView(
          value: remindersAsync,
          data: (reminders) {
            if (reminders.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
                children: [
                  Text('Rappels', style: AppText.screenTitle(p.textPrimary)),
                  const SizedBox(height: 60),
                  const EmptyState(
                    icon: Icons.notifications_none,
                    message: 'Aucun rappel pour le moment.',
                  ),
                ],
              );
            }

            final now = DateTime.now();
            final today = <Reminder>[];
            final week = <Reminder>[];
            final later = <Reminder>[];
            for (final r in reminders) {
              final days = r.when.difference(now).inDays;
              if (r.isOverdue || days <= 0) {
                today.add(r);
              } else if (days <= 7) {
                week.add(r);
              } else {
                later.add(r);
              }
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rappels', style: AppText.screenTitle(p.textPrimary)),
                    TextButton(
                      onPressed: () => ref.read(_readIdsProvider.notifier).state =
                          reminders.map((r) => r.id).toSet(),
                      child: const Text('Tout lire'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (today.isNotEmpty) ...[
                  _GroupLabel("AUJOURD'HUI"),
                  ...today.map((r) => _ReminderTile(
                      reminder: r, read: readIds.contains(r.id))),
                  const SizedBox(height: 22),
                ],
                if (week.isNotEmpty) ...[
                  _GroupLabel('CETTE SEMAINE'),
                  ...week.map((r) => _ReminderTile(
                      reminder: r, read: readIds.contains(r.id))),
                  const SizedBox(height: 22),
                ],
                if (later.isNotEmpty) ...[
                  _GroupLabel('PLUS TARD'),
                  ...later.map((r) => _ReminderTile(
                      reminder: r, read: readIds.contains(r.id))),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: AppText.sectionLabel(context.palette.textSecondary)),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.reminder, required this.read});
  final Reminder reminder;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = reminder.isOverdue ? p.danger : p.warn;
    final icon = reminder.kind == ReminderKind.document
        ? Icons.description_outlined
        : Icons.build_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: read ? p.surface : color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: read ? p.border : color.withValues(alpha: .3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(reminder.title,
                          style: TextStyle(
                              color: p.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                    Text(Fmt.relative(reminder.when),
                        style: TextStyle(color: p.textSecondary, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(reminder.body,
                    style: TextStyle(color: p.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          if (!read) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }
}
