import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/reminder.dart';
import '../services/notification_service.dart';
import '../services/prediction_service.dart';
import 'document_provider.dart';
import 'maintenance_provider.dart';
import 'settings_provider.dart';
import 'vehicle_provider.dart';

/// Builds the current list of due/upcoming reminders across all vehicles.
///
/// Pure: scheduling OS notifications is the job of [reminderSchedulerProvider],
/// driven by a `ref.listen` in the app shell. Doing it here meant a
/// `cancelAll()` plus a full re-schedule on every rebuild — and a half-failed
/// rebuild could leave the device with no reminders at all.
final remindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final vehicles = await ref.watch(vehiclesProvider.future);
  final settings = ref.watch(settingsProvider).value;
  final kmThreshold = settings?.kmAlertThreshold ?? Thresholds.kmAlert;
  final daysThreshold = settings?.daysAlertThreshold ?? Thresholds.daysAlert;

  final reminders = <Reminder>[];

  for (final v in vehicles) {
    // Maintenance predictions -> reminders.
    final preds = await ref.watch(predictionsProvider(v.id).future);
    for (final p in preds) {
      if (!PredictionService.needsAlert(p,
          kmThreshold: kmThreshold, daysThreshold: daysThreshold)) {
        continue;
      }
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

    // Admin documents -> reminders.
    final docs = await ref.watch(documentsProvider(v.id).future);
    for (final d in docs) {
      if (d.daysToExpiry < daysThreshold) {
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

final reminderSchedulerProvider =
    Provider<ReminderScheduler>(ReminderScheduler.new);

/// Mirrors the reminder list onto the OS notification schedule.
class ReminderScheduler {
  ReminderScheduler(this.ref);
  final Ref ref;

  /// Signature of the last successfully-synced list, so an unchanged
  /// rebuild doesn't cancel and re-create the whole schedule.
  String? _lastSynced;

  Future<void> sync(List<Reminder> reminders) async {
    final settings = ref.read(settingsProvider).value;
    final svc = NotificationService.instance;

    if (settings != null && !settings.pushEnabled) {
      if (_lastSynced != _disabled) {
        await svc.cancelAll();
        _lastSynced = _disabled;
      }
      return;
    }

    final days = settings?.daysAlertThreshold ?? Thresholds.daysAlert;
    final now = DateTime.now();
    final planned = [
      for (final r in reminders)
        (reminder: r, at: _notifyAt(r.when, days, now)),
    ];

    final signature = planned
        .map((p) => '${p.reminder.id}@${p.at.toIso8601String()}')
        .join('|');
    if (signature == _lastSynced) return;

    await svc.cancelAll();
    for (final p in planned) {
      await svc.schedule(
        // Derived from the reminder's own identity, so the same échéance
        // keeps the same OS notification across runs. The old loop index
        // reassigned ids to different reminders on every reschedule.
        id: p.reminder.id.hashCode & 0x7fffffff,
        title: p.reminder.title,
        body: p.reminder.body,
        when: p.at,
        payload: p.reminder.vehicleId,
      );
    }
    _lastSynced = signature;
  }

  static const _disabled = '<push-disabled>';

  /// When to actually notify for an échéance falling on [due].
  ///
  /// Normally: the morning the échéance enters the alert window. But a
  /// reminder only exists once it is *already* inside that window, so that
  /// moment is nearly always past — in which case we take the next 9am
  /// rather than firing instantly.
  static DateTime _notifyAt(DateTime due, int daysThreshold, DateTime now) {
    final entersWindow = due.subtract(Duration(days: daysThreshold));
    final atMorning =
        DateTime(entersWindow.year, entersWindow.month, entersWindow.day, 9);
    return atMorning.isAfter(now) ? atMorning : _nextMorning(now);
  }

  static DateTime _nextMorning(DateTime now) {
    final todayAt9 = DateTime(now.year, now.month, now.day, 9);
    return todayAt9.isAfter(now)
        ? todayAt9
        : DateTime(now.year, now.month, now.day + 1, 9);
  }
}
