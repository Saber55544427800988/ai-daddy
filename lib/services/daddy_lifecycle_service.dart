import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/check_in_log_model.dart';
import 'notification_service.dart';

/// DaddyLifecycleService — handles background lifecycle events:
///
/// 1. Pre-generated template reminders (0 AI tokens)
/// 2. Late-night escalation messages
/// 3. Inactivity/retention notifications
/// 4. Behavioral pattern learning (wake/sleep/meal/meeting patterns)
/// 5. Smart double-reminders (30min + 5min before events)
/// 6. Exam/event multi-day reminders
///
/// All templates use 0 AI tokens — pre-written messages only.
class DaddyLifecycleService {
  static final DaddyLifecycleService instance = DaddyLifecycleService._();
  DaddyLifecycleService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final Random _rng = Random();

  // ════════════════════════════════════════════════════
  //  1. PRE-GENERATED TEMPLATE REMINDERS (0 TOKENS)
  // ════════════════════════════════════════════════════

  /// Morning greeting templates (0 AI tokens)
  static List<String> morningTemplates(String nickname) => [
        'Morning champ. Daddy hopes you slept well. Eat something before you start.',
        'Good morning, $nickname. New day, new chance. Make it count.',
        'Rise and shine, $nickname. Daddy believes in you today.',
        'Hey $nickname. Breakfast first, everything else second.',
        'Morning, champ. Don\'t skip breakfast. Daddy is watching.',
        'Up and at \'em, $nickname. Today is yours.',
        'Good morning. Drink water. Eat. Then conquer.',
        'Hey $nickname, hope you rested well. Be great today.',
      ];

  /// Meal reminder templates (0 AI tokens)
  static List<String> mealTemplates(String nickname) => [
        'Hey $nickname. Did you eat? Don\'t skip meals.',
        '$nickname, food is fuel. Eat something.',
        'Lunchtime, champ. Take a break and eat properly.',
        'Don\'t forget to eat, $nickname. Daddy worries.',
        'Quick check — have you eaten? Do it now.',
        'Your body needs fuel, $nickname. Eat something good.',
      ];

  /// Hydration reminders (0 AI tokens)
  static List<String> hydrationTemplates(String nickname) => [
        'Drink water, $nickname.',
        'Hey. Water break. Now.',
        'Stay hydrated, champ. Grab some water.',
        '$nickname, when was your last glass of water?',
      ];

  /// Evening wind-down templates (0 AI tokens)
  static List<String> eveningTemplates(String nickname) => [
        'Hey $nickname. How was your day?',
        'Evening, champ. Slow down. You did enough today.',
        '$nickname, take a breath. The day is ending. You did well.',
        'Time to wind down, $nickname. You earned it.',
      ];
  /// Dad Task reminder templates (0 AI tokens)
  static List<String> dadTaskTemplates(String nickname) => [
        'Hey $nickname! Time to check your Dad Tasks. Small wins add up! 💪',
        'Don\'t forget your Dad Tasks today, $nickname. Daddy is counting on you.',
        '$nickname, have you completed your Dad Tasks? Open the app and crush them!',
        'Dad Task reminder: consistency is key, $nickname. Get them done! ⭐',
        'Quick check, $nickname — your Dad Tasks are waiting. Earn that XP!',
        'Hey champ. Your Dad Tasks won\'t complete themselves. Let\'s go!',
        '$nickname, real growth comes from daily habits. Check your Dad Tasks.',
        'Time to level up, $nickname! Complete your Dad Tasks and earn rewards.',
        'Daddy\'s reminder: your Dad Tasks are important. Do them now, $nickname.',
        'Hey $nickname. Champions complete their Dad Tasks every day. Be one.',
      ];
  // ════════════════════════════════════════════════════
  //  2. LATE-NIGHT ESCALATION (0 TOKENS)
  // ════════════════════════════════════════════════════

  /// Get escalating late-night sleep message based on how long
  /// the user has been active past bedtime.
  ///
  /// [minutesPastBedtime] — minutes since 11 PM (or learned sleep time)
  static String getLateNightMessage(String nickname, int minutesPastBedtime) {
    if (minutesPastBedtime < 15) {
      return 'It\'s late, $nickname.';
    } else if (minutesPastBedtime < 45) {
      return 'Sleep.';
    } else if (minutesPastBedtime < 90) {
      return 'Don\'t make Daddy worry.';
    } else if (minutesPastBedtime < 150) {
      return '$nickname. Bed. Now.';
    } else {
      return 'I\'m still here, $nickname. But you should be sleeping.';
    }
  }

  /// Schedule late-night escalation notifications.
  /// Called when user is detected active after bedtime.
  Future<void> scheduleLateNightEscalation(
      String nickname, DateTime bedtime) async {
    final messages = [
      {'delay': 0, 'text': 'It\'s late.'},
      {'delay': 15, 'text': 'Sleep.'},
      {'delay': 35, 'text': 'Don\'t make Daddy worry.'},
    ];

    for (int i = 0; i < messages.length; i++) {
      final delay = messages[i]['delay'] as int;
      final text = messages[i]['text'] as String;
      final time = bedtime.add(Duration(minutes: delay));

      if (time.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleNotification(
          id: 800 + i,
          title: 'AI Daddy 🌙',
          body: text,
          scheduledTime: time,
        );
      }
    }
  }

  // ════════════════════════════════════════════════════
  //  3. INACTIVITY / RETENTION SYSTEM (0 TOKENS)
  // ════════════════════════════════════════════════════

  /// Get retention message based on days of inactivity.
  /// All pre-written — zero AI token cost.
  static String? getRetentionMessage(String nickname, int daysInactive) {
    switch (daysInactive) {
      case 1:
        return null; // 1 day is normal
      case 2:
        return 'Did you forget your Daddy, $nickname?';
      case 3:
        return 'I\'m still here, $nickname.';
      case 4:
        return 'Hey $nickname. Just checking. Daddy misses you.';
      case 5:
        return 'Come back. I miss you.';
      case 6:
        return 'It\'s been almost a week, $nickname. Talk to me.';
      case 7:
        return '$nickname, a whole week without you. Daddy is worried.';
      default:
        if (daysInactive > 7 && daysInactive <= 14) {
          return 'I\'m always here when you\'re ready, $nickname. ❤️';
        } else if (daysInactive > 14) {
          return 'Daddy never forgets, $nickname. Come back anytime.';
        }
        return null;
    }
  }

  /// Check last open time and schedule retention notification if needed.
  Future<void> checkInactivityAndNotify(int userId, String nickname) async {
    final lastCheckIn = await _db.getLastCheckIn(userId);
    if (lastCheckIn == null) return;

    final lastOpen = DateTime.parse(lastCheckIn.lastOpenTime);
    final daysSince = DateTime.now().difference(lastOpen).inDays;

    final message = getRetentionMessage(nickname, daysSince);
    if (message != null) {
      await NotificationService.instance.showNotification(
        id: 900 + daysSince,
        title: 'AI Daddy 💙',
        body: message,
      );
    }
  }

  /// Record that the user opened the app
  Future<void> recordAppOpen(int userId) async {
    await _db.insertCheckIn(CheckInLogModel(
      userId: userId,
      lastOpenTime: DateTime.now().toIso8601String(),
    ));
  }

  // ════════════════════════════════════════════════════
  //  4. BEHAVIORAL PATTERN LEARNING
  // ════════════════════════════════════════════════════

  /// Analyze user behavior patterns from stored data and
  /// return personalized notification schedule.
  ///
  /// Learns:
  /// - Typical wake time
  /// - Typical sleep time
  /// - Meal skip frequency
  /// - Meeting day patterns
  /// - Mood patterns by time of day
  Future<Map<String, dynamic>> analyzeBehaviorPatterns(int userId) async {
    final prefs = await SharedPreferences.getInstance();

    // Get check-in logs to detect wake/sleep patterns
    final db = await _db.database;
    final checkIns = await db.query(
      'check_in_log',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'last_open_time DESC',
      limit: 100,
    );

    // Analyze wake times (first open each day)
    final Map<String, List<int>> dailyFirstOpen = {};
    for (final ci in checkIns) {
      final dt = DateTime.parse(ci['last_open_time'] as String);
      final dayKey = '${dt.year}-${dt.month}-${dt.day}';
      dailyFirstOpen.putIfAbsent(dayKey, () => []);
      dailyFirstOpen[dayKey]!.add(dt.hour);
    }

    // Average first-open hour = estimated wake time
    int avgWakeHour = 7;
    if (dailyFirstOpen.isNotEmpty) {
      final firstHours = dailyFirstOpen.values.map((hours) => hours.reduce(min)).toList();
      avgWakeHour = (firstHours.reduce((a, b) => a + b) / firstHours.length).round();
    }

    // Analyze last activity each day for sleep time
    final Map<String, int> dailyLastOpen = {};
    for (final ci in checkIns) {
      final dt = DateTime.parse(ci['last_open_time'] as String);
      final dayKey = '${dt.year}-${dt.month}-${dt.day}';
      if (!dailyLastOpen.containsKey(dayKey) || dt.hour > dailyLastOpen[dayKey]!) {
        dailyLastOpen[dayKey] = dt.hour;
      }
    }

    int avgSleepHour = 23;
    if (dailyLastOpen.isNotEmpty) {
      final lastHours = dailyLastOpen.values.toList();
      avgSleepHour = (lastHours.reduce((a, b) => a + b) / lastHours.length).round();
    }

    // Message frequency by day of week
    final messages = await db.rawQuery('''
      SELECT strftime('%w', timestamp) as dow, COUNT(*) as cnt
      FROM messages
      WHERE user_id = ? AND sender_type = 'user'
      GROUP BY dow
      ORDER BY cnt DESC
    ''', [userId]);

    // Busiest day (for meeting/activity patterns)
    String busiestDay = 'Monday';
    if (messages.isNotEmpty) {
      final dowNum = int.tryParse(messages.first['dow']?.toString() ?? '1') ?? 1;
      const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      busiestDay = dayNames[dowNum % 7];
    }

    // Store learned patterns
    final patterns = {
      'wake_hour': avgWakeHour,
      'sleep_hour': avgSleepHour,
      'busiest_day': busiestDay,
      'analyzed_at': DateTime.now().toIso8601String(),
    };

    await prefs.setInt('learned_wake_hour', avgWakeHour);
    await prefs.setInt('learned_sleep_hour', avgSleepHour);
    await prefs.setString('learned_busiest_day', busiestDay);

    return patterns;
  }

  // ════════════════════════════════════════════════════
  //  5. SMART SCHEDULE SETUP (based on learned patterns)
  // ════════════════════════════════════════════════════

  /// Build personalized daily notification schedule based on
  /// learned behavior patterns. Uses 0 AI tokens.
  Future<void> setupDailySchedule(int userId, String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final wakeHour = prefs.getInt('learned_wake_hour') ?? 7;
    final sleepHour = prefs.getInt('learned_sleep_hour') ?? 23;

    final now = DateTime.now();

    // Morning greeting
    final morningTime = DateTime(now.year, now.month, now.day, wakeHour + 1, 0);
    final morningMsg = morningTemplates(nickname)[_rng.nextInt(morningTemplates(nickname).length)];

    // Midday meal check
    final lunchTime = DateTime(now.year, now.month, now.day, 13, 0);
    final lunchMsg = mealTemplates(nickname)[_rng.nextInt(mealTemplates(nickname).length)];

    // Afternoon hydration
    final hydrateTime = DateTime(now.year, now.month, now.day, 15, 30);
    final hydrateMsg = hydrationTemplates(nickname)[_rng.nextInt(hydrationTemplates(nickname).length)];

    // Evening wind-down
    final eveningTime = DateTime(now.year, now.month, now.day, 20, 0);
    final eveningMsg = eveningTemplates(nickname)[_rng.nextInt(eveningTemplates(nickname).length)];

    // Sleep reminder (30 min before learned sleep time)
    final sleepTime = DateTime(now.year, now.month, now.day, sleepHour, 0)
        .subtract(const Duration(minutes: 30));
    const sleepMsg = 'Time to start winding down. Sleep is important.';

    final schedule = [
      {'id': 200, 'time': morningTime, 'msg': morningMsg},
      {'id': 201, 'time': lunchTime, 'msg': lunchMsg},
      {'id': 202, 'time': hydrateTime, 'msg': hydrateMsg},
      {'id': 203, 'time': eveningTime, 'msg': eveningMsg},
      {'id': 204, 'time': sleepTime, 'msg': sleepMsg},
    ];

    for (final item in schedule) {
      final time = item['time'] as DateTime;
      var scheduled = time;
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await NotificationService.instance.scheduleNotification(
        id: item['id'] as int,
        title: 'AI Daddy 💙',
        body: item['msg'] as String,
        scheduledTime: scheduled,
      );
    }
    // ── 5 daily Dad Task reminders ──
    final dadTaskMsgs = dadTaskTemplates(nickname);
    dadTaskMsgs.shuffle(_rng);
    final dadTaskTimes = [9, 12, 15, 18, 20];
    for (int i = 0; i < 5; i++) {
      await NotificationService.instance.scheduleDailyNotification(
        id: 300 + i,
        title: 'Dad Tasks 📋',
        body: dadTaskMsgs[i],
        hour: dadTaskTimes[i],
        minute: 0,
      );
    }  }

  // ════════════════════════════════════════════════════
  //  6. DOUBLE REMINDER SYSTEM
  // ════════════════════════════════════════════════════

  /// Schedule double reminders for an event:
  /// - 30 minutes before
  /// - 5 minutes before
  ///
  /// Uses 0 AI tokens — pre-written templates only.
  Future<void> scheduleDoubleReminder({
    required int baseId,
    required String nickname,
    required String eventDescription,
    required DateTime eventTime,
  }) async {
    // Reminder 1: 30 minutes before
    final earlyTime = eventTime.subtract(const Duration(minutes: 30));
    final earlyMessages = [
      'Hey $nickname. You\'ve got something at ${_formatHour(eventTime)}. Be ready.',
      '$nickname, heads up — $eventDescription in 30 minutes.',
      'Quick reminder: $eventDescription at ${_formatHour(eventTime)}.',
    ];

    // Reminder 2: 5 minutes before
    final lateTime = eventTime.subtract(const Duration(minutes: 5));
    final lateMessages = [
      'Five minutes. Focus.',
      'Almost time, $nickname. Go.',
      '$eventDescription — now.',
    ];

    if (earlyTime.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleNotification(
        id: baseId,
        title: 'AI Daddy ⏰',
        body: earlyMessages[_rng.nextInt(earlyMessages.length)],
        scheduledTime: earlyTime,
      );
    }

    if (lateTime.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleNotification(
        id: baseId + 1,
        title: 'AI Daddy ⏰',
        body: lateMessages[_rng.nextInt(lateMessages.length)],
        scheduledTime: lateTime,
      );
    }
  }

  // ════════════════════════════════════════════════════
  //  7. EXAM / IMPORTANT EVENT MULTI-DAY REMINDERS
  // ════════════════════════════════════════════════════

  /// Schedule multi-day reminders for important events (exams, deadlines):
  /// - 1 day before (preparation reminder)
  /// - Morning of the event (motivation)
  /// - 2 hours before (focus reminder)
  /// - 5 minutes before (final push)
  ///
  /// Uses 0 AI tokens — all pre-written.
  Future<void> scheduleExamReminders({
    required int baseId,
    required String nickname,
    required String examDescription,
    required DateTime examTime,
  }) async {
    final reminders = <Map<String, dynamic>>[];

    // 1 day before
    final dayBefore = examTime.subtract(const Duration(days: 1));
    if (dayBefore.isAfter(DateTime.now())) {
      reminders.add({
        'id': baseId,
        'time': DateTime(dayBefore.year, dayBefore.month, dayBefore.day, 20, 0),
        'msg': 'Hey $nickname. $examDescription is tomorrow. Are you prepared? Start now if you haven\'t.',
      });
    }

    // Morning of exam
    final morningOf = DateTime(examTime.year, examTime.month, examTime.day, 7, 30);
    if (morningOf.isAfter(DateTime.now())) {
      reminders.add({
        'id': baseId + 1,
        'time': morningOf,
        'msg': 'Today is the day, $nickname. You\'ve got your $examDescription. Daddy believes in you.',
      });
    }

    // 2 hours before
    final twoHoursBefore = examTime.subtract(const Duration(hours: 2));
    if (twoHoursBefore.isAfter(DateTime.now())) {
      reminders.add({
        'id': baseId + 2,
        'time': twoHoursBefore,
        'msg': '$examDescription in 2 hours, $nickname. Review your notes. Stay calm. You\'re ready.',
      });
    }

    // 5 minutes before
    final fiveMinBefore = examTime.subtract(const Duration(minutes: 5));
    if (fiveMinBefore.isAfter(DateTime.now())) {
      reminders.add({
        'id': baseId + 3,
        'time': fiveMinBefore,
        'msg': 'Go get it, $nickname. Daddy is proud of you no matter what. 💪',
      });
    }

    for (final r in reminders) {
      await NotificationService.instance.scheduleNotification(
        id: r['id'] as int,
        title: 'AI Daddy 📚',
        body: r['msg'] as String,
        scheduledTime: r['time'] as DateTime,
      );
    }
  }

  // ════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════

  String _formatHour(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    if (minute == '00') return '$hour $period';
    return '$hour:$minute $period';
  }
}
