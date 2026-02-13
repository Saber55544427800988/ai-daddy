import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../widgets/in_app_notification.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Constants
// ──────────────────────────────────────────────────────────────────────────────
const _alarmPortName = 'ai_daddy_alarm_port';
const _pendingPrefsKey = 'ai_daddy_pending_notifs';

// ──────────────────────────────────────────────────────────────────────────────
// Top-level callback for android_alarm_manager_plus.
// Runs in a BACKGROUND ISOLATE — must be top-level & self-contained.
// ──────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
void _alarmCallback(int alarmId) async {
  debugPrint('[AI Daddy Alarm] fired id=$alarmId');

  // Try to forward to main isolate first (app in foreground)
  final port = IsolateNameServer.lookupPortByName(_alarmPortName);
  if (port != null) {
    port.send(alarmId);
    debugPrint('[AI Daddy Alarm] forwarded to main isolate');
    return;
  }

  // Main isolate dead → show notification directly from background
  debugPrint('[AI Daddy Alarm] main isolate dead, showing directly');
  try {
    tz_data.initializeTimeZones();

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // Read saved pending data
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingPrefsKey) ?? '{}';
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final data = map[alarmId.toString()];

    final title = data?['title'] as String? ?? 'AI Daddy \u{1f499}';
    final body =
        data?['body'] as String? ?? 'Hey! You have a reminder \u{1f499}';

    await plugin.show(
      alarmId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ai_daddy_v6',
          'AI Daddy Messages',
          channelDescription: 'Messenger-style notifications from AI Daddy',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('daddy_sound'),
          fullScreenIntent: true,
          category: AndroidNotificationCategory.message,
          visibility: NotificationVisibility.public,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF00BFFF),
        ),
      ),
    );

    // Clean up
    map.remove(alarmId.toString());
    await prefs.setString(_pendingPrefsKey, jsonEncode(map));
    debugPrint('[AI Daddy Alarm] direct notification shown');
  } catch (e) {
    debugPrint('[AI Daddy Alarm] ERROR: $e');
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Notification Service
// ──────────────────────────────────────────────────────────────────────────────

class NotificationService {
  static final NotificationService instance = NotificationService._init();

  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  FlutterLocalNotificationsPlugin get _notifications {
    _notificationsPlugin ??= FlutterLocalNotificationsPlugin();
    return _notificationsPlugin!;
  }

  bool _isInitialized = false;
  final List<Timer> _timers = [];
  ReceivePort? _alarmPort;

  /// Channel v6 — fresh channel with custom sound
  static const _channelId = 'ai_daddy_v6';
  static const _channelName = 'AI Daddy Messages';
  static const _channelDesc = 'Messenger-style notifications from AI Daddy';
  static const _customSound =
      RawResourceAndroidNotificationSound('daddy_sound');

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
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (_) {},
    );

    // Delete ALL old cached channels
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      for (final old in [
        'ai_daddy_messages',
        'ai_daddy_popup',
        'ai_daddy_v3',
        'ai_daddy_v4',
        'ai_daddy_v5',
      ]) {
        try {
          await androidPlugin.deleteNotificationChannel(old);
        } catch (_) {}
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

    // Initialize android_alarm_manager_plus
    try {
      await AndroidAlarmManager.initialize();
    } catch (e) {
      debugPrint('[AI Daddy] AlarmManager init: $e');
    }

    // Set up ReceivePort for alarm callbacks from background isolate
    _setupAlarmPort();

    _isInitialized = true;
    await requestPermission();
    debugPrint('[AI Daddy] Notification service initialized');
  }

  // ── ReceivePort for alarm callbacks ──────────────────────────────────────

  void _setupAlarmPort() {
    try {
      IsolateNameServer.removePortNameMapping(_alarmPortName);
      _alarmPort?.close();

      _alarmPort = ReceivePort();
      IsolateNameServer.registerPortWithName(
          _alarmPort!.sendPort, _alarmPortName);

      _alarmPort!.listen((message) {
        if (message is int) {
          debugPrint('[AI Daddy] Alarm port received id=$message');
          _handleAlarmFromPort(message);
        }
      });
      debugPrint('[AI Daddy] Alarm port registered');
    } catch (e) {
      debugPrint('[AI Daddy] Alarm port error: $e');
    }
  }

  Future<void> _handleAlarmFromPort(int alarmId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingPrefsKey) ?? '{}';
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final data = map[alarmId.toString()];

      final title = data?['title'] as String? ?? 'AI Daddy \u{1f499}';
      final body =
          data?['body'] as String? ?? 'Hey! You have a reminder \u{1f499}';

      await showNotification(id: alarmId, title: title, body: body);

      // Clean up
      map.remove(alarmId.toString());
      await prefs.setString(_pendingPrefsKey, jsonEncode(map));
    } catch (e) {
      debugPrint('[AI Daddy] Alarm port handler error: $e');
      // Fallback — show a generic notification
      try {
        await showNotification(
          id: alarmId,
          title: 'AI Daddy \u{1f499}',
          body: 'Hey! You have a reminder \u{1f499}',
        );
      } catch (_) {}
    }
  }

  // ── Timezone ────────────────────────────────────────────────────────────

  void _setLocalTimezone() {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offset.inMilliseconds) {
          tz.setLocalLocation(loc);
          debugPrint('[AI Daddy] Timezone: ${loc.name}');
          return;
        }
      }
      debugPrint('[AI Daddy] No exact tz match; using default');
    } catch (e) {
      debugPrint('[AI Daddy] Timezone error: $e');
    }
  }

  // ── Permissions ─────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    try {
      final p = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (p != null) {
        final ok = await p.requestNotificationsPermission();
        try {
          await p.requestExactAlarmsPermission();
        } catch (_) {}
        debugPrint('[AI Daddy] Notification permission: $ok');
        return ok ?? false;
      }
    } catch (e) {
      debugPrint('[AI Daddy] Permission error: $e');
    }
    return true;
  }

  // ── Notification details ────────────────────────────────────────────────

  /// Simple, reliable notification details (no MessagingStyle — always works)
  AndroidNotificationDetails _simpleDetails(String body) {
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
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ticker: body,
      autoCancel: true,
      color: const Color(0xFF00BFFF),
      colorized: true,
    );
  }

  /// Messenger-style notification details — fancy chat bubble look
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

  // ── Persist pending notifications (survives app kill) ───────────────────

  Future<void> _savePending(int id, String title, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingPrefsKey) ?? '{}';
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map[id.toString()] = {'title': title, 'body': body};
      await prefs.setString(_pendingPrefsKey, jsonEncode(map));
    } catch (e) {
      debugPrint('[AI Daddy] Save pending error: $e');
    }
  }

  Future<void> _removePending(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingPrefsKey) ?? '{}';
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map.remove(id.toString());
      await prefs.setString(_pendingPrefsKey, jsonEncode(map));
    } catch (_) {}
  }

  // ── Schedule ────────────────────────────────────────────────────────────

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
    debugPrint(
        '[AI Daddy] Schedule id=$id delay=${delay.inSeconds}s body=$body');

    // Already passed → fire now
    if (delay.isNegative || delay.inSeconds <= 0) {
      debugPrint('[AI Daddy] Time passed, firing now');
      await showNotification(id: id, title: title, body: body);
      return;
    }

    // Persist for alarm callback (survives app kill)
    await _savePending(id, title, body);

    // ── METHOD 1: Timer (works while app is in memory) ──
    final timer = Timer(delay, () {
      debugPrint('[AI Daddy] Timer fired id=$id');
      showNotification(id: id, title: title, body: body);
      _removePending(id);
    });
    _timers.add(timer);

    // ── METHOD 2: zonedSchedule (flutter_local_notifications) ──
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    debugPrint('[AI Daddy] zonedSchedule tzTime=$tzTime tz=${tz.local.name}');
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        NotificationDetails(android: _simpleDetails(body), iOS: _ios),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('[AI Daddy] zonedSchedule exact OK');
    } catch (e) {
      debugPrint('[AI Daddy] zonedSchedule exact FAIL: $e');
      // Fallback to inexact
      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tzTime,
          NotificationDetails(android: _simpleDetails(body), iOS: _ios),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        debugPrint('[AI Daddy] zonedSchedule inexact OK');
      } catch (e2) {
        debugPrint('[AI Daddy] zonedSchedule inexact FAIL: $e2');
      }
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
      debugPrint('[AI Daddy] AlarmManager oneShot OK');
    } catch (e) {
      debugPrint('[AI Daddy] AlarmManager error: $e');
    }
  }

  // ── Show notification ───────────────────────────────────────────────────

  /// Show notification immediately — system notification + in-app overlay.
  /// Uses MessagingStyle first, falls back to simple on failure.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    debugPrint('[AI Daddy] showNotification id=$id body=$body');

    // --- System notification ---
    bool systemShown = false;

    // Try MessagingStyle (fancy chat look)
    try {
      await _notifications.show(
        id,
        title,
        body,
        NotificationDetails(android: _messengerDetails(body), iOS: _ios),
      );
      systemShown = true;
      debugPrint('[AI Daddy] MessagingStyle OK');
    } catch (e) {
      debugPrint('[AI Daddy] MessagingStyle FAIL: $e');
    }

    // Fallback: simple notification (always works)
    if (!systemShown) {
      try {
        await _notifications.show(
          id,
          title,
          body,
          NotificationDetails(android: _simpleDetails(body), iOS: _ios),
        );
        systemShown = true;
        debugPrint('[AI Daddy] Simple notification OK');
      } catch (e) {
        debugPrint('[AI Daddy] Simple notification FAIL: $e');
      }
    }

    // Ultra-fallback: bare minimum (no custom sound, no extras)
    if (!systemShown) {
      try {
        await _notifications.show(
          id,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'ai_daddy_v6',
              'AI Daddy Messages',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
        debugPrint('[AI Daddy] Ultra-fallback notification OK');
      } catch (e) {
        debugPrint('[AI Daddy] ALL notification methods FAILED: $e');
      }
    }

    // --- In-app overlay popup (slides from side to center) ---
    try {
      InAppNotification.instance.show(title: title, body: body);
    } catch (e) {
      debugPrint('[AI Daddy] InApp overlay error: $e');
    }
  }

  // ── Daily reminders ─────────────────────────────────────────────────────

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
    var d =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (d.isBefore(now)) d = d.add(const Duration(days: 1));
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        d,
        NotificationDetails(android: _simpleDetails(body), iOS: _ios),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('[AI Daddy] scheduleDailyNotification error: $e');
    }
  }

  // ── Cancel ──────────────────────────────────────────────────────────────

  Future<void> cancelAll() async {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    await _notifications.cancelAll();
    // Clear persisted pending
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingPrefsKey);
    } catch (_) {}
  }

  Future<void> cancel(int id) async {
    await _removePending(id);
    await _notifications.cancel(id);
    try {
      await AndroidAlarmManager.cancel(id);
    } catch (_) {}
  }
}
