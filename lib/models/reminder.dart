enum ReminderKind { maintenance, document }

/// A UI-facing reminder derived from predictions / documents.
class Reminder {
  final String id;
  final String vehicleId;
  final String vehicleName;
  final String title;
  final String body;
  final DateTime when;
  final ReminderKind kind;

  const Reminder({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.title,
    required this.body,
    required this.when,
    required this.kind,
  });

  bool get isOverdue => when.isBefore(DateTime.now());
}
