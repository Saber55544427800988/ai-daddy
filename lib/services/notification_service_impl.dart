import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Facebook Messenger-style notification service.
/// Heads-up pop-up notifications with sound, works even when app is closed.
class NotificationService {
  static final NotificationService instance = NotificationService._init();

  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  FlutterLocalNotificationsPlugin get _notifications {
    _notificationsPlugin ??= FlutterLocalNotificationsPlugin();
    return _notificationsPlugin!;
  }

  bool _isInitialized = false;

  /// Unique channel ID — v3 to force fresh channel creation with correct settings.
  /// Android caches channel settings, so old channels keep old (broken) config.
  static const _channelId = 'ai_daddy_v3';
  static const _channelName = 'AI Daddy Messages';
  static const _channelDesc = 'Pop-up notifications from AI Daddy';

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

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Delete ALL old cached channels so Android uses fresh settings
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      try { await androidPlugin.deleteNotificationChannel('ai_daddy_messages'); } catch (_) {}
      try { await androidPlugin.deleteNotificationChannel('ai_daddy_popup'); } catch (_) {}

      // Explicitly create the channel with MAX importance — this is the KEY
      // to getting heads-up pop-up notifications on Android.
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
      final deviceOffset = now.timeZoneOffset;
      for (final location in tz.timeZoneDatabase.locations.values) {
        if (location.currentTimeZone.offset == deviceOffset.inMilliseconds) {
          tz.setLocalLocation(location);
          return;
        }
      }
    } catch (_) {}
  }

  static void _onNotificationTap(NotificationResponse response) {}

  Future<bool> requestPermission() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
        return granted ?? false;
      }
    } catch (_) {}
    return true;
  }

  /// Build Android notification details — Messenger-style heads-up popup.
  AndroidNotificationDetails _androidDetails(String body) {
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
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
      // fullScreenIntent makes notification appear as heads-up popup
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
    );
  }

  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    threadIdentifier: 'ai_daddy_chat',
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  /// Schedule a notification at a specific time.
  /// Uses Android AlarmManager — works even when app is closed/killed.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await init();

    final delay = scheduledTime.difference(DateTime.now());

    // If time already passed, fire immediately
    if (delay.isNegative || delay.inSeconds <= 0) {
      await showNotification(id: id, title: title, body: body);
      return;
    }

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        NotificationDetails(android: _androidDetails(body), iOS: _iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tzTime,
          NotificationDetails(android: _androidDetails(body), iOS: _iosDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {}
    }
  }

  /// Show a notification immediately — heads-up popup with sound.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(android: _androidDetails(body), iOS: _iosDetails),
    );
  }

  Future<void> scheduleDailyReminders(
      String nickname, List<String> reminderTexts) async {
    for (int i = 0; i < 5; i++) {
      await cancel(100 + i);
    }
    final times = [8, 11, 14, 17, 21];
    for (int i = 0; i < reminderTexts.length && i < times.length; i++) {
      await scheduleDailyNotification(
        id: 100 + i,
        title: 'AI Daddy \u{1f499}',
        body: reminderTexts[i],
        hour: times[i],
        minute: 0,
      );
    }
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await init();
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: _androidDetails(body), iOS: _iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}
