import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/reminder.dart';
import '../services/notification_service.dart';
import '../services/prediction_service.dart';
import 'document_provider.dart';
import 'maintenance_provider.dart';
import 'vehicle_provider.dart';

/// Builds the current list of due/upcoming reminders across all vehicles,
/// and (re)schedules matching local notifications.
final remindersProvider =
    FutureProvider<List<Reminder>>((ref) async {
  final vehicles = await ref.watch(vehiclesProvider.future);
  final reminders = <Reminder>[];

  for (final v in vehicles) {
    // Maintenance predictions -> reminders.
    final preds = await ref.watch(predictionsProvider(v.id).future);
    for (final p in preds) {
      if (PredictionService.needsAlert(p)) {
        reminders.add(Reminder(
          id: 'maint_${p.type.id}',
          vehicleId: v.id,
          vehicleName: v.name,
          title: '${p.type.label} — ${v.name}',
          body: _maintBody(p.remainingKm, p.dueDate),
          when: p.dueDate ?? DateTime.now(),
          kind: ReminderKind.maintenance,
        ));
      }
    }

    // Admin documents -> reminders.
    final docs = await ref.watch(documentsProvider(v.id).future);
    for (final d in docs) {
      if (d.daysToExpiry < Thresholds.daysAlert) {
        reminders.add(Reminder(
          id: 'doc_${d.id}',
          vehicleId: v.id,
          vehicleName: v.name,
          title: '${DocTypes.label(d.docType)} ${d.year} — ${v.name}',
          body: d.isExpired
              ? 'Expiré depuis ${-d.daysToExpiry} j'
              : 'Expire dans ${d.daysToExpiry} j',
          when: d.expiryDate,
          kind: ReminderKind.document,
        ));
      }
    }
  }

  reminders.sort((a, b) => a.when.compareTo(b.when));

  // Re-schedule local notifications to mirror the reminder list.
  await _reschedule(reminders);
  return reminders;
});

String _maintBody(int? remainingKm, DateTime? dueDate) {
  final parts = <String>[];
  if (remainingKm != null) {
    parts.add(remainingKm < 0
        ? 'dépassé de ${-remainingKm} km'
        : 'dans $remainingKm km');
  }
  if (dueDate != null) {
    final days = dueDate.difference(DateTime.now()).inDays;
    parts.add(days < 0 ? 'échéance dépassée' : 'échéance dans $days j');
  }
  return parts.isEmpty ? 'Échéance proche' : parts.join(' · ');
}

Future<void> _reschedule(List<Reminder> reminders) async {
  final svc = NotificationService.instance;
  await svc.cancelAll();
  for (var i = 0; i < reminders.length; i++) {
    final r = reminders[i];
    // Notify 30 days before expiry, but never in the past.
    final notifyAt = r.when.subtract(const Duration(days: Thresholds.daysAlert));
    await svc.schedule(
      id: i + 1,
      title: r.title,
      body: r.body,
      when: notifyAt,
    );
  }
}
