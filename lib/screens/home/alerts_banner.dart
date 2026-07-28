import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/reminder.dart';
import '../../providers/notification_provider.dart';
import '../notifications/notifications_screen.dart';

/// Slim priority-alert strip at the top of Accueil: one tappable line
/// summarising the most urgent reminder across all vehicles. Tapping it
/// switches the shell to the Alertes tab for the full list.
class AlertsBanner extends ConsumerWidget {
  const AlertsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];
    if (reminders.isEmpty) return const SizedBox.shrink();

    final sorted = [...reminders]..sort((a, b) => a.when.compareTo(b.when));
    final top = sorted.first;
    final anyOverdue = reminders.any((r) => r.isOverdue);
    final color = anyOverdue ? p.danger : p.warn;
    final n = reminders.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: .3)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(color: p.textPrimary, fontSize: 13.5),
                      children: [
                        TextSpan(
                          text: '$n alerte${n > 1 ? 's' : ''}',
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: '  ·  '),
                        TextSpan(
                          text: _shortTitle(top.title),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, color: p.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Reminder titles read "Vidange moteur — kanggo"; on the garage screen
  /// the vehicle is obvious from context, so drop the trailing " — name".
  String _shortTitle(String title) {
    final i = title.lastIndexOf(' — ');
    return i == -1 ? title : title.substring(0, i);
  }
}
