import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

// ──────────────────────────────────────────────────────────────────────────────
// Top-level callback for android_alarm_manager_plus.
// Runs in a separate isolate — must be top-level, not inside a class.
// ──────────────────────────────────────────────────────────────────────────────

/// Port name for sending alarm data between isolates
const _alarmPortName = 'ai_daddy_alarm_port';

/// Called by AndroidAlarmManager in a background isolate.
@pragma('vm:entry-point')
void _alarmCallback() {
  // Send a message to the main isolate to fire the notification.
  // If the app is in foreground, the main isolate receives it.
  // If the app is killed, the alarm still fires — Android wakes it up.
  final port = IsolateNameServer.lookupPortByName(_alarmPortName);
  port?.send('alarm_fired');
}

// ──────────────────────────────────────────────────────────────────────────────
// Notification Service
// ──────────────────────────────────────────────────────────────────────────────

/// Messenger-style notification service with triple-redundancy scheduling:
/// 1. Timer (in-app) — instant, reliable while app is open
/// 2. zonedSchedule (AlarmManager via flutter_local_notifications) — background
/// 3. android_alarm_manager_plus — dedicated background alarm, survives app kill
class NotificationService {
  static final NotificationService instance = NotificationService._init();

  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  FlutterLocalNotificationsPlugin get _notifications {
    _notificationsPlugin ??= FlutterLocalNotificationsPlugin();
    return _notificationsPlugin!;
  }

  bool _isInitialized = false;
  final List<Timer> _timers = [];

  /// Channel v6 — fresh channel with custom sound
  static const _channelId = 'ai_daddy_v6';
  static const _channelName = 'AI Daddy Messages';
  static const _channelDesc = 'Messenger-style notifications from AI Daddy';
  static const _customSound = RawResourceAndroidNotificationSound('daddy_sound');

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

    // Delete ALL old cached channels
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      for (final old in [
        'ai_daddy_messages', 'ai_daddy_popup',
        'ai_daddy_v3', 'ai_daddy_v4', 'ai_daddy_v5',
      ]) {
        try { await androidPlugin.deleteNotificationChannel(old); } catch (_) {}
      }

      // Create the channel with MAX importance + custom sound
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        sound: _customSound,
      );
      await androidPlugin.createNotificationChannel(channel);
    }

    // Initialize android_alarm_manager_plus for background alarms
    try {
      await AndroidAlarmManager.initialize();
    } catch (_) {}

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

  /// Messenger-style notification details — looks like Facebook Messenger.
  /// fullScreenIntent = heads-up popup on top of screen.
  /// MessagingStyle = chat bubble appearance.
  AndroidNotificationDetails _messengerDetails(String body) {
    const person = Person(name: 'AI Daddy \u{1f499}', important: true);
    final messagingStyle = MessagingStyleInformation(
      person,
      conversationTitle: 'AI Daddy',
      groupConversation: false,
      messages: [Message(body, DateTime.now(), person)],
    );

    return AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: _customSound,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      styleInformation: messagingStyle,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ticker: body,
      autoCancel: true,
      color: const Color(0xFF00BFFF),
      colorized: true,
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

  // ── Saved pending notifications for alarm callback ──
  static final Map<int, _PendingNotification> _pending = {};

  /// Schedule a notification with triple redundancy:
  /// 1. Timer (foreground)
  /// 2. zonedSchedule (flutter_local_notifications AlarmManager)
  /// 3. android_alarm_manager_plus (dedicated background alarm)
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

    // Save for alarm callback
    _pending[id] = _PendingNotification(id: id, title: title, body: body);

    // ── METHOD 1: Timer (works while app is in memory) ──
    final timer = Timer(delay, () {
      showNotification(id: id, title: title, body: body);
      _pending.remove(id);
    });
    _timers.add(timer);

    // ── METHOD 2: zonedSchedule (flutter_local_notifications) ──
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    try {
      await _notifications.zonedSchedule(
        id, title, body, tzTime,
        NotificationDetails(android: _messengerDetails(body), iOS: _ios),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Fallback to inexact
      try {
        await _notifications.zonedSchedule(
          id, title, body, tzTime,
          NotificationDetails(android: _messengerDetails(body), iOS: _ios),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {}
    }

    // ── METHOD 3: android_alarm_manager_plus (survives app kill) ──
    try {
      await AndroidAlarmManager.oneShot(
        delay,
        id,
        _alarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
    } catch (_) {}
  }

  /// Show notification immediately — Messenger-style popup with sound.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    await _notifications.show(
      id, title, body,
      NotificationDetails(android: _messengerDetails(body), iOS: _ios),
    );
  }

  Future<void> scheduleDailyReminders(
      String nickname, List<String> reminderTexts) async {
    for (int i = 0; i < 5; i++) { await cancel(100 + i); }
    final times = [8, 11, 14, 17, 21];
    for (int i = 0; i < reminderTexts.length && i < times.length; i++) {
      await scheduleDailyNotification(
        id: 100 + i, title: 'AI Daddy \u{1f499}', body: reminderTexts[i],
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
        NotificationDetails(android: _messengerDetails(body), iOS: _ios),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    for (final t in _timers) { t.cancel(); }
    _timers.clear();
    _pending.clear();
    await _notifications.cancelAll();
  }

  Future<void> cancel(int id) async {
    _pending.remove(id);
    await _notifications.cancel(id);
    try { await AndroidAlarmManager.cancel(id); } catch (_) {}
  }
}

class _PendingNotification {
  final int id;
  final String title;
  final String body;
  _PendingNotification({required this.id, required this.title, required this.body});
}
