import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Notification service — reliable heads-up popup with sound.
///
/// Key design decisions:
/// 1. NO fullScreenIntent — Android 14+ auto-denies this for non-alarm apps,
///    which DOWNGRADES the notification to silent. Heads-up is achieved with
///    Importance.max + Priority.high alone.
/// 2. NO MessagingStyleInformation — causes silent failures on some OEMs.
///    Simple BigTextStyle is universally supported.
/// 3. Timer + zonedSchedule DUAL approach — Timer works while app is open,
///    zonedSchedule (AlarmManager) works when app is closed.
/// 4. Fresh channel ID (v4) — Android caches channel settings forever.
///    New ID forces Android to create channel with correct MAX importance.
class NotificationService {
  static final NotificationService instance = NotificationService._init();

  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  FlutterLocalNotificationsPlugin get _notifications {
    _notificationsPlugin ??= FlutterLocalNotificationsPlugin();
    return _notificationsPlugin!;
  }

  bool _isInitialized = false;
  final List<Timer> _timers = [];

  static const _channelId = 'ai_daddy_v4';
  static const _channelName = 'AI Daddy';
  static const _channelDesc = 'Reminders and messages from AI Daddy';

  NotificationService._init();

  Future<void> init() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    _setLocalTimezone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (_) {},
    );

    // Delete ALL old channels — Android caches their settings forever
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      for (final oldId in ['ai_daddy_messages', 'ai_daddy_popup', 'ai_daddy_v3']) {
        try { await androidPlugin.deleteNotificationChannel(oldId); } catch (_) {}
      }

      // Create fresh channel with MAX importance → triggers heads-up popup
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      await androidPlugin.createNotificationChannel(channel);
    }

    _isInitialized = true;
    await requestPermission();
  }

  void _setLocalTimezone() {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offset.inMilliseconds) {
          tz.setLocalLocation(loc);
          return;
        }
      }
    } catch (_) {}
  }

  Future<bool> requestPermission() async {
    try {
      final p = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (p != null) {
        final ok = await p.requestNotificationsPermission();
        try { await p.requestExactAlarmsPermission(); } catch (_) {}
        return ok ?? false;
      }
    } catch (_) {}
    return true;
  }

  /// Simple, reliable Android notification details.
  /// NO fullScreenIntent, NO MessagingStyle — these cause failures.
  /// Heads-up popup comes from Importance.max + Priority.high on the channel.
  AndroidNotificationDetails _details(String body) {
    return AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(body),
      icon: '@mipmap/ic_launcher',
      ticker: body,
      autoCancel: true,
      onlyAlertOnce: false,
    );
  }

  static const _ios = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    threadIdentifier: 'ai_daddy_chat',
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  /// Schedule a notification. Uses BOTH Timer (foreground) and
  /// zonedSchedule/AlarmManager (background) for maximum reliability.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await init();

    final delay = scheduledTime.difference(DateTime.now());

    // Already passed → fire now
    if (delay.isNegative || delay.inSeconds <= 0) {
      await showNotification(id: id, title: title, body: body);
      return;
    }

    // APPROACH 1: Timer — works reliably while app is in foreground/memory
    final timer = Timer(delay, () {
      showNotification(id: id, title: title, body: body);
    });
    _timers.add(timer);

    // APPROACH 2: AlarmManager via zonedSchedule — works when app is killed
    // Both approaches try to show the notification; the second one is harmless
    // if the first already fired (same ID = just updates the notification).
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    try {
      await _notifications.zonedSchedule(
        id, title, body, tzTime,
        NotificationDetails(android: _details(body), iOS: _ios),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {}
  }

  /// Show notification immediately — heads-up popup with sound.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    await _notifications.show(
      id, title, body,
      NotificationDetails(android: _details(body), iOS: _ios),
    );
  }

  Future<void> scheduleDailyReminders(
      String nickname, List<String> reminderTexts) async {
    for (int i = 0; i < 5; i++) { await cancel(100 + i); }
    final times = [8, 11, 14, 17, 21];
    for (int i = 0; i < reminderTexts.length && i < times.length; i++) {
      await scheduleDailyNotification(
        id: 100 + i, title: 'AI Daddy', body: reminderTexts[i],
        hour: times[i], minute: 0,
      );
    }
  }

  Future<void> scheduleDailyNotification({
    required int id, required String title, required String body,
    required int hour, required int minute,
  }) async {
    await init();
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (d.isBefore(now)) d = d.add(const Duration(days: 1));
    try {
      await _notifications.zonedSchedule(
        id, title, body, d,
        NotificationDetails(android: _details(body), iOS: _ios),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  Future<void> cancelAll() async { await _notifications.cancelAll(); }
  Future<void> cancel(int id) async { await _notifications.cancel(id); }
}
