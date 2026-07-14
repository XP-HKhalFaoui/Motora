import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Local reminders via flutter_local_notifications (section 4.3).
///
/// Reminders are recomputed and re-scheduled each time the app opens
/// (see [rescheduleAll]); there is no server component required.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channel = AndroidNotificationChannel(
    'carnet_auto_reminders',
    'Rappels entretien',
    description: 'Échéances d\'entretien et documents administratifs',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_ready) return;
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await _deviceTimeZone()));
    } catch (_) {
      // Fall back to UTC if the platform name isn't in the tz database.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await requestPermissions();
    _ready = true;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// A reminder to schedule.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_ready) await init();
    // Don't schedule dates in the past.
    final target = when.isBefore(DateTime.now())
        ? DateTime.now().add(const Duration(seconds: 5))
        : when;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(target, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();

  Future<String> _deviceTimeZone() async {
    // A light heuristic; on device the OS timezone is used by the plugin.
    // Kept simple to avoid an extra native dependency.
    if (kIsWeb) return 'UTC';
    final offset = DateTime.now().timeZoneName;
    return offset.isEmpty ? 'UTC' : 'UTC';
  }
}
