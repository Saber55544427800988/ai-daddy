import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Real notification service for mobile platforms (Android/iOS).
class NotificationService {
  static final NotificationService instance = NotificationService._init();

  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  FlutterLocalNotificationsPlugin get _notifications {
    _notificationsPlugin ??= FlutterLocalNotificationsPlugin();
    return _notificationsPlugin!;
  }

  bool _isInitialized = false;

  NotificationService._init();

  Future<void> init() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    // Set local timezone to match device — critical for notifications
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
    _isInitialized = true;

    await requestPermission();
  }

  /// Set tz.local to the device's actual timezone
  void _setLocalTimezone() {
    try {
      final now = DateTime.now();
      final deviceOffset = now.timeZoneOffset;

      // Search timezone database for a location matching the device offset
      for (final location in tz.timeZoneDatabase.locations.values) {
        if (location.currentTimeZone.offset == deviceOffset.inMilliseconds) {
          tz.setLocalLocation(location);
          return;
        }
      }
    } catch (_) {}
    // Fallback: use UTC if no match found
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    // App opens when notification is tapped — no extra action needed
  }

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

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await init();

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // Messenger-style notification with person info
    const person = Person(
      name: 'AI Daddy 💙',
      important: true,
    );

    final messagingStyle = MessagingStyleInformation(
      person,
      conversationTitle: 'AI Daddy',
      groupConversation: false,
      messages: [
        Message(body, DateTime.now(), person),
      ],
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'ai_daddy_messages',
          'AI Daddy Messages',
          channelDescription: 'Messages from AI Daddy',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('daddy_notification'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
          fullScreenIntent: true,
          category: AndroidNotificationCategory.message,
          visibility: NotificationVisibility.public,
          styleInformation: messagingStyle,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ticker: body,
          autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'daddy_notification.caf',
          threadIdentifier: 'ai_daddy_chat',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();

    // Messenger-style instant notification
    const person = Person(
      name: 'AI Daddy 💙',
      important: true,
    );

    final messagingStyle = MessagingStyleInformation(
      person,
      conversationTitle: 'AI Daddy',
      groupConversation: false,
      messages: [
        Message(body, DateTime.now(), person),
      ],
    );

    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'ai_daddy_messages',
          'AI Daddy Messages',
          channelDescription: 'Messages from AI Daddy',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('daddy_notification'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
          fullScreenIntent: true,
          category: AndroidNotificationCategory.message,
          visibility: NotificationVisibility.public,
          styleInformation: messagingStyle,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ticker: body,
          autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'daddy_notification.caf',
          threadIdentifier: 'ai_daddy_chat',
        ),
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
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Messenger-style daily notification
    const person = Person(
      name: 'AI Daddy 💙',
      important: true,
    );

    final messagingStyle = MessagingStyleInformation(
      person,
      conversationTitle: 'AI Daddy',
      groupConversation: false,
      messages: [
        Message(body, DateTime.now(), person),
      ],
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'ai_daddy_messages',
          'AI Daddy Messages',
          channelDescription: 'Messages from AI Daddy',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('daddy_notification'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
          fullScreenIntent: true,
          category: AndroidNotificationCategory.message,
          visibility: NotificationVisibility.public,
          styleInformation: messagingStyle,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ticker: body,
          autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'daddy_notification.caf',
          threadIdentifier: 'ai_daddy_chat',
        ),
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
