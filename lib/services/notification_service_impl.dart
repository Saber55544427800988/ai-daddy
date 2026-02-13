import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Facebook Messenger-style notification service.
/// Pop-up heads-up notifications with custom sound, works in background.
class NotificationService {
  static final NotificationService instance = NotificationService._init();

  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  FlutterLocalNotificationsPlugin get _notifications {
    _notificationsPlugin ??= FlutterLocalNotificationsPlugin();
    return _notificationsPlugin!;
  }

  bool _isInitialized = false;

  /// NEW channel ID — forces Android to create a fresh channel with correct settings.
  /// Old 'ai_daddy_messages' channel may be cached with wrong importance/sound.
  static const _channelId = 'ai_daddy_popup';
  static const _channelName = 'AI Daddy Notifications';
  static const _channelDesc = 'Pop-up messages from AI Daddy';

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

    // Delete old cached channel so Android picks up new settings
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      try {
        await androidPlugin.deleteNotificationChannel('ai_daddy_messages');
      } catch (_) {}
    }

    _isInitialized = true;
    await requestPermission();
  }

  /// Set tz.local to the device's actual timezone
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

  /// Messenger-style Android notification details with custom sound + heads-up popup.
  AndroidNotificationDetails _androidDetails(String body) {
    const person = Person(name: 'AI Daddy 💙', important: true);
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
      // Use default system notification sound (custom sounds crash on some devices)
      playSound: true,
      // Vibration pattern like Messenger
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
      // Heads-up pop-up
      fullScreenIntent: true,
      // Messenger-style appearance
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      styleInformation: messagingStyle,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ticker: body,
      autoCancel: true,
      // Colored notification
      color: const Color(0xFF00BFFF),
      colorized: true,
    );
  }

  /// iOS notification details
  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    threadIdentifier: 'ai_daddy_chat',
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  /// Schedule a notification at a specific time.
  /// Uses Android AlarmManager — works even when app is closed.
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
        NotificationDetails(
          android: _androidDetails(body),
          iOS: _iosDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Fallback: inexact alarm (still works in background, slight delay)
      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tzTime,
          NotificationDetails(
            android: _androidDetails(body),
            iOS: _iosDetails,
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {}
    }
  }

  /// Show a notification immediately — pop-up with sound.
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
      NotificationDetails(
        android: _androidDetails(body),
        iOS: _iosDetails,
      ),
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
        title: 'AI Daddy 💙',
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
      NotificationDetails(
        android: _androidDetails(body),
        iOS: _iosDetails,
      ),
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
