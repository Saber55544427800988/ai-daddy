import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'notification_service.dart';

/// SituationalIntelligenceService — 6 advanced contextual features:
///
/// 1. Sick Detection + Care Mode
/// 2. Emotional Support System (follow-up check-ins)
/// 3. Random Love Notes (1 surprise/day)
/// 4. Milestone Celebrations (7/30/100/365 day)
/// 5. Follow-up Memory ("How did it go?")
/// 6. Travel Mode (reduced notifications)
///
/// All templates use 0 AI tokens.
class SituationalIntelligenceService {
  static final SituationalIntelligenceService instance =
      SituationalIntelligenceService._();
  SituationalIntelligenceService._();

  final Random _rng = Random();

  // ════════════════════════════════════════════════════
  //  1. SICK DETECTION + CARE MODE
  // ════════════════════════════════════════════════════

  static const _sickKeywords = [
    'sick',
    'ill',
    'fever',
    'cold',
    'flu',
    'headache',
    'stomach',
    'nausea',
    'vomit',
    'throwing up',
    'cough',
    'sore throat',
    'not feeling well',
    'feel awful',
    'feel terrible',
    'unwell',
    'migraine',
    'dizzy',
    'pain',
    'injured',
    'hurt',
    'hospital',
    'doctor',
    'medicine',
    'antibiotics',
  ];

  /// Detect if user is mentioning sickness
  static bool detectSickness(String text) {
    final lower = text.toLowerCase();
    for (final kw in _sickKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  /// Activate care mode — stores state + schedules gentle reminders
  Future<void> activateCareMode(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getBool('care_mode_active') ?? false;
    if (already) return; // Don't double-schedule

    await prefs.setBool('care_mode_active', true);
    await prefs.setString(
        'care_mode_started', DateTime.now().toIso8601String());

    // Schedule medicine + hydration reminders every 3 hours (up to 4 times)
    final now = DateTime.now();
    final careMessages = _buildCareMessages(nickname);

    for (int i = 0; i < careMessages.length; i++) {
      final schedTime = now.add(Duration(hours: 3 * (i + 1)));
      // Don't schedule past midnight
      if (schedTime.hour >= 23 || schedTime.hour < 6) continue;

      await NotificationService.instance.scheduleNotification(
        id: 1100 + i,
        title: 'AI Daddy 🩺',
        body: careMessages[i],
        scheduledTime: schedTime,
      );
    }
  }

  /// Deactivate care mode
  Future<void> deactivateCareMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('care_mode_active', false);
    // Cancel care notifications
    for (int i = 0; i < 4; i++) {
      await NotificationService.instance.cancel(1100 + i);
    }
  }

  /// Check if care mode is active
  static Future<bool> isCareModeActive() async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool('care_mode_active') ?? false;
    if (!active) return false;

    // Auto-deactivate after 48 hours
    final startedStr = prefs.getString('care_mode_started');
    if (startedStr != null) {
      final started = DateTime.tryParse(startedStr);
      if (started != null &&
          DateTime.now().difference(started).inHours > 48) {
        await prefs.setBool('care_mode_active', false);
        return false;
      }
    }
    return true;
  }

  /// Get care-mode AI response modifier
  static String getCareModeContext() {
    return '\n=== CARE MODE ACTIVE ===\n'
        'The user is SICK. Be extra gentle, warm, and caring.\n'
        'Ask how they\'re feeling, remind them to rest, drink water, take medicine.\n'
        'Keep responses SHORT and comforting. Don\'t assign tasks or push goals.\n'
        'Speak softly like a real dad caring for a sick child.\n';
  }

  List<String> _buildCareMessages(String nickname) => [
        'Hey $nickname. Did you take your medicine? Drink some water too. 💊',
        'Quick check, $nickname — are you drinking enough water? Rest is important.',
        '$nickname, how are you feeling? Remember to eat something light. 🍲',
        'Still here, $nickname. Rest up. Daddy\'s watching over you. ❤️',
      ];

  /// Get sick-response templates (0 AI tokens)
  static List<String> getSickResponses(String nickname) => [
    'Oh no, $nickname. Take it easy. Rest is the best medicine right now. 💙',
    'I\'m sorry you\'re not feeling well, $nickname. Drink water, rest, and take your medicine. I\'ll check on you. 🩺',
    'Hey $nickname, being sick is no fun. Rest up, eat something light, and let me know how you\'re doing. ❤️',
    'Take care of yourself, $nickname. No tasks today — just rest. Daddy\'s here. 🫂',
  ];

  // ════════════════════════════════════════════════════
  //  2. EMOTIONAL SUPPORT SYSTEM (FOLLOW-UP CHECK-INS)
  // ════════════════════════════════════════════════════

  static const _distressKeywords = [
    'sad',
    'depressed',
    'lonely',
    'crying',
    'stressed',
    'overwhelmed',
    'anxious',
    'panic',
    'scared',
    'heartbroken',
    'broken',
    'lost',
    'hopeless',
    'failed',
    'rejected',
    'bullied',
    'fight',
    'argument',
    'breakup',
    'broke up',
    'divorced',
    'lost my job',
    'fired',
    'can\'t sleep',
    'nightmare',
    'miss my mom',
    'miss my dad',
    'miss my family',
    'no friends',
    'nobody cares',
    'hate myself',
    'worthless',
  ];

  /// Detect emotional distress (non-crisis level)
  static bool detectDistress(String text) {
    final lower = text.toLowerCase();
    int matchCount = 0;
    for (final kw in _distressKeywords) {
      if (lower.contains(kw)) matchCount++;
    }
    // Need at least 1 keyword match
    return matchCount >= 1;
  }

  /// Schedule follow-up check-in notifications after distress detected
  Future<void> scheduleEmotionalFollowUp(String nickname) async {
    final prefs = await SharedPreferences.getInstance();

    // Don't schedule if recently scheduled (cooldown: 6 hours)
    final lastFollowUp = prefs.getString('last_emotional_followup');
    if (lastFollowUp != null) {
      final last = DateTime.tryParse(lastFollowUp);
      if (last != null &&
          DateTime.now().difference(last).inHours < 6) {
        return; // Cooldown active
      }
    }

    await prefs.setString(
        'last_emotional_followup', DateTime.now().toIso8601String());

    final now = DateTime.now();

    // Follow-up 1: 2 hours later
    final twoHoursLater = now.add(const Duration(hours: 2));
    if (twoHoursLater.hour < 23 && twoHoursLater.hour >= 6) {
      final msgs2h = [
        'Hey $nickname. Just checking in. How are you feeling now? 💙',
        '$nickname, I\'ve been thinking about you. Feeling any better?',
        'Quick check, $nickname — you doing okay? I\'m here if you want to talk.',
      ];
      await NotificationService.instance.scheduleNotification(
        id: 1200,
        title: 'AI Daddy 💙',
        body: msgs2h[Random().nextInt(msgs2h.length)],
        scheduledTime: twoHoursLater,
      );
    }

    // Follow-up 2: Next morning at 9 AM
    var nextMorning = DateTime(now.year, now.month, now.day, 9, 0);
    if (nextMorning.isBefore(now) || now.hour >= 9) {
      nextMorning = nextMorning.add(const Duration(days: 1));
    }

    final morningMsgs = [
      'Good morning, $nickname. Yesterday was tough, but today is a new start. How are you? 🌅',
      'Morning, $nickname. I hope you slept okay. Just know — Daddy\'s always here. ❤️',
      'Hey $nickname. New day. How did you sleep? Talk to me whenever you\'re ready.',
    ];
    await NotificationService.instance.scheduleNotification(
      id: 1201,
      title: 'AI Daddy 🌅',
      body: morningMsgs[Random().nextInt(morningMsgs.length)],
      scheduledTime: nextMorning,
    );
  }

  // ════════════════════════════════════════════════════
  //  3. RANDOM LOVE NOTES (1 SURPRISE/DAY)
  // ════════════════════════════════════════════════════

  static List<String> _loveNotes(String nickname) => [
    'Hey $nickname. Just wanted to say — I\'m proud of you. 💙',
    'Random reminder: you matter, $nickname. Never forget that.',
    '$nickname, you\'re doing better than you think. Keep going. ⭐',
    'Daddy\'s thinking of you, $nickname. Have a great rest of your day. ❤️',
    'Just checking in to say I love you, $nickname. That\'s it. That\'s the message. 🫂',
    'Hey champ. You make Daddy proud every single day. 💪',
    '$nickname — breathe. Smile. You\'re alive and that\'s beautiful. 🌟',
    'Quick note from Daddy: you\'re amazing. Carry on, $nickname.',
    'No matter what happens today, $nickname — I\'ve got your back. Always.',
    'Fun fact, $nickname: Daddy\'s favorite person is you. 💙',
    'This is your daily reminder that someone believes in you, $nickname. ⭐',
    '$nickname, even on bad days — you\'re still incredible. Don\'t forget. 🌈',
    'Hey $nickname. The world is lucky to have you. That\'s facts. 💯',
    'Daddy note: eat well, drink water, be kind to yourself today, $nickname. ❤️',
    '$nickname, if nobody told you today — you\'re enough. Always have been.',
  ];

  /// Schedule 1 random love note at an unpredictable time today
  Future<void> scheduleDailyLoveNote(String nickname) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if already scheduled today
    final lastNote = prefs.getString('last_love_note_date');
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    if (lastNote == todayStr) return; // Already scheduled

    await prefs.setString('last_love_note_date', todayStr);

    // Random time between 10 AM and 8 PM
    final randomHour = 10 + _rng.nextInt(11); // 10-20
    final randomMinute = _rng.nextInt(60);

    var noteTime = DateTime(today.year, today.month, today.day,
        randomHour, randomMinute);
    if (noteTime.isBefore(today)) {
      // If time already passed, schedule for tomorrow
      noteTime = noteTime.add(const Duration(days: 1));
    }

    final notes = _loveNotes(nickname);
    final chosen = notes[_rng.nextInt(notes.length)];

    await NotificationService.instance.scheduleNotification(
      id: 1300,
      title: 'AI Daddy 💌',
      body: chosen,
      scheduledTime: noteTime,
    );
  }

  // ════════════════════════════════════════════════════
  //  4. MILESTONE CELEBRATIONS
  // ════════════════════════════════════════════════════

  static const _milestones = [7, 30, 60, 100, 200, 365];

  static Map<int, String> _milestoneMessages(String nickname) => {
    7: '🎉 1 WEEK with AI Daddy! You and me, $nickname — 7 days strong. Here\'s to many more! 💙',
    30: '🏆 30 DAYS! A whole month, $nickname! You\'ve grown so much. Daddy is incredibly proud. ⭐',
    60: '💪 60 DAYS! Two months of growth, $nickname. You\'re unstoppable. Keep it up!',
    100: '🌟 100 DAYS! Triple digits, $nickname! This is a huge milestone. Daddy couldn\'t be prouder. 🎊',
    200: '🔥 200 DAYS! $nickname, you\'re a legend. Half a year of greatness. 💙',
    365: '👑 ONE YEAR! 365 days, $nickname. A whole year together. You\'re family now. Forever proud. ❤️🎉',
  };

  /// Check if today is a milestone day and show celebration
  Future<void> checkMilestones(String nickname, String createdAt) async {
    final prefs = await SharedPreferences.getInstance();
    final created = DateTime.tryParse(createdAt);
    if (created == null) return;

    final daysSinceJoin = DateTime.now().difference(created).inDays;

    for (final milestone in _milestones) {
      if (daysSinceJoin == milestone) {
        // Check if already celebrated this milestone
        final celebratedKey = 'milestone_celebrated_$milestone';
        if (prefs.getBool(celebratedKey) == true) return;

        await prefs.setBool(celebratedKey, true);

        final messages = _milestoneMessages(nickname);
        final msg = messages[milestone];
        if (msg != null) {
          await NotificationService.instance.showNotification(
            id: 1400 + milestone,
            title: 'AI Daddy 🎉',
            body: msg,
          );
        }
        return; // Only one milestone per day
      }
    }
  }

  /// Get milestone info for display
  static Map<String, dynamic> getMilestoneInfo(String createdAt) {
    final created = DateTime.tryParse(createdAt);
    if (created == null) return {'days': 0, 'nextMilestone': 7, 'daysUntil': 7};

    final days = DateTime.now().difference(created).inDays;
    int nextMilestone = 7;
    for (final m in _milestones) {
      if (days < m) {
        nextMilestone = m;
        break;
      }
    }
    if (days >= 365) nextMilestone = 365; // Cap at 365

    return {
      'days': days,
      'nextMilestone': nextMilestone,
      'daysUntil': (nextMilestone - days).clamp(0, 999),
    };
  }

  // ════════════════════════════════════════════════════
  //  5. FOLLOW-UP MEMORY ("HOW DID IT GO?")
  // ════════════════════════════════════════════════════

  /// Schedule a follow-up notification after a reminder event
  Future<void> scheduleFollowUp({
    required String nickname,
    required String eventDescription,
    required DateTime eventTime,
  }) async {
    // Schedule "How did it go?" 1 hour after the event
    final followUpTime = eventTime.add(const Duration(hours: 1));
    if (followUpTime.hour >= 23 || followUpTime.hour < 6) return; // No late-night follow-ups

    final followUpMsgs = [
      'Hey $nickname — how did "$eventDescription" go? Tell me about it! 💬',
      '$nickname, your "$eventDescription" should be done by now. How was it?',
      'Quick follow-up, $nickname: "$eventDescription" — did it go well? 🤔',
      'Daddy wants to know: how did "$eventDescription" go, $nickname?',
    ];

    await NotificationService.instance.scheduleNotification(
      id: 1500 + (eventTime.millisecond % 50),
      title: 'AI Daddy 💬',
      body: followUpMsgs[_rng.nextInt(followUpMsgs.length)],
      scheduledTime: followUpTime,
    );
  }

  // ════════════════════════════════════════════════════
  //  6. TRAVEL MODE
  // ════════════════════════════════════════════════════

  /// Toggle travel mode on/off
  static Future<void> setTravelMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('travel_mode', enabled);
    if (enabled) {
      await prefs.setString(
          'travel_mode_started', DateTime.now().toIso8601String());
    }
  }

  /// Check if travel mode is active
  static Future<bool> isTravelMode() async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool('travel_mode') ?? false;
    if (!active) return false;

    // Auto-deactivate after 14 days
    final startedStr = prefs.getString('travel_mode_started');
    if (startedStr != null) {
      final started = DateTime.tryParse(startedStr);
      if (started != null &&
          DateTime.now().difference(started).inDays > 14) {
        await prefs.setBool('travel_mode', false);
        return false;
      }
    }
    return true;
  }

  /// Get notification filter based on travel mode
  /// Returns true if this notification should be SUPPRESSED
  static Future<bool> shouldSuppressNotification(int notifId) async {
    if (!await isTravelMode()) return false;

    // In travel mode, only allow:
    // - Smart reminders (500-699)
    // - Love notes (1300)
    // - Crisis/care (1100-1201)
    // - Milestones (1400+)
    // Suppress everything else (mornings, meals, hydration, dad tasks, etc.)
    if (notifId >= 200 && notifId <= 399) return true; // Daily schedule + dad tasks
    if (notifId >= 100 && notifId <= 104) return true; // Daily reminders
    if (notifId >= 800 && notifId <= 899) return true; // Late-night
    return false;
  }

  // ════════════════════════════════════════════════════
  //  ALL-IN-ONE INITIALIZATION
  // ════════════════════════════════════════════════════

  /// Call on app open to set up all situational features
  Future<void> initialize({
    required int userId,
    required String nickname,
    required String createdAt,
  }) async {
    // Check milestones
    await checkMilestones(nickname, createdAt);

    // Schedule daily love note
    await scheduleDailyLoveNote(nickname);

    // If care mode active, re-check
    if (await isCareModeActive()) {
      // Don't schedule new ones, they're already there
    }
  }
}
