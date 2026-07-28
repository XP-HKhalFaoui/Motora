import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Local reminders via flutter_local_notifications (section 4.3).
///
/// Reminders are recomputed and re-scheduled whenever the reminder list
/// changes (see `ReminderScheduler`); there is no server component.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Vehicle id carried by a notification the user tapped while the app was
  /// not running. Consumed once by the shell on first frame.
  String? _launchVehicleId;

  /// Called when the user taps a reminder while the app is running.
  void Function(String vehicleId)? _onOpenVehicle;

  static const _channel = AndroidNotificationChannel(
    'carnet_auto_reminders',
    'Rappels entretien',
    description: 'Échéances d\'entretien et documents administratifs',
    importance: Importance.high,
  );

  Future<void> init({void Function(String vehicleId)? onOpenVehicle}) async {
    if (_ready) return;
    _onOpenVehicle = onOpenVehicle;

    // tz.local stays UTC on purpose: we never schedule a "wall clock" time
    // in a named zone, only absolute instants. A Dart local DateTime such
    // as DateTime(y, m, d, 9) already resolves to the right instant for
    // that date's UTC offset, TZDateTime.from preserves that instant, and
    // UILocalNotificationDateInterpretation.absoluteTime tells the plugin
    // to honour it — so no device-timezone lookup is needed.
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _onOpenVehicle?.call(payload);
        }
      },
    );

    // A tap that launched the app cold doesn't go through the callback
    // above; it arrives here instead.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final payload = launch?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) _launchVehicleId = payload;
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await requestPermissions();
    _ready = true;
  }

  /// Registers the tap handler after [init] (the app shell knows how to
  /// navigate; main() does not).
  set onOpenVehicle(void Function(String vehicleId) handler) =>
      _onOpenVehicle = handler;

  /// Returns — once — the vehicle whose notification launched the app.
  String? takeLaunchVehicleId() {
    final id = _launchVehicleId;
    _launchVehicleId = null;
    return id;
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

  /// Schedules one reminder for [when].
  ///
  /// A time in the past is **skipped**, not fired immediately. The previous
  /// behaviour rewrote it to `now + 5s`, which — because every reminder is
  /// by construction already inside its alert window — turned the whole
  /// list into a burst of notifications on each app launch.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    if (!_ready) await init();
    if (!when.isAfter(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
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
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
