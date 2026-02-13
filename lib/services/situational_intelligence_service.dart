import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

/// SituationalIntelligenceService — Full auto-reminder AI Dad system.
///
/// Acts like a REAL FATHER: auto-detects situations from chat and
/// schedules caring check-in reminders without user asking.
///
/// Features:
/// 1. Sick Detection + Care Mode (medicine, hydration, rest reminders)
/// 2. Emotional Support (sadness, stress, loneliness → follow-ups)
/// 3. Travel Mode (safety check-ins, "arrived safe?", "how's the trip?")
/// 4. Study/Exam Support (study reminders, pre-exam encouragement)
/// 5. Achievement Celebration (congrats follow-ups)
/// 6. Sleep & Routine Care (goodnight, wake-up check-ins)
/// 7. Random Love Notes (1 surprise/day)
/// 8. Milestone Celebrations (7/30/100/365 day)
/// 9. Follow-up Memory ("How did it go?")
/// 10. Loneliness Detection (social isolation check-ins)
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
    'sick', 'ill', 'fever', 'cold', 'flu', 'headache', 'stomach',
    'nausea', 'vomit', 'throwing up', 'cough', 'sore throat',
    'not feeling well', 'feel awful', 'feel terrible', 'unwell',
    'migraine', 'dizzy', 'pain', 'injured', 'hurt', 'hospital',
    'doctor', 'medicine', 'antibiotics', 'covid', 'infection',
    'allergy', 'asthma', 'surgery', 'broken', 'sprain',
  ];

  static bool detectSickness(String text) {
    final lower = text.toLowerCase();
    for (final kw in _sickKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  /// Activate care mode — schedules multiple caring reminders
  Future<void> activateCareMode(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getBool('care_mode_active') ?? false;
    if (already) return;

    await prefs.setBool('care_mode_active', true);
    await prefs.setString('care_mode_started', DateTime.now().toIso8601String());

    final now = DateTime.now();
    final careMessages = [
      'Hey $nickname, did you take your medicine? And drink some water. I need you healthy.',
      'Quick check $nickname — are you resting? Don\'t push yourself. Eat something light.',
      '$nickname, how are you feeling now? Remember, rest is the best medicine.',
      'Still thinking about you $nickname. Drink water, take it easy. Tomorrow will be better.',
      'Hey $nickname, feeling any better? If not, maybe see a doctor. Your health comes first.',
    ];

    for (int i = 0; i < careMessages.length; i++) {
      final schedTime = now.add(Duration(hours: 2 * (i + 1)));
      if (schedTime.hour >= 23 || schedTime.hour < 7) continue;
      await NotificationService.instance.scheduleNotification(
        id: 1100 + i,
        title: 'AI Daddy',
        body: careMessages[i],
        scheduledTime: schedTime,
      );
    }

    // Next morning follow-up
    var nextMorning = DateTime(now.year, now.month, now.day + 1, 8, 30);
    await NotificationService.instance.scheduleNotification(
      id: 1106,
      title: 'AI Daddy',
      body: 'Good morning $nickname. How did you sleep? Feeling better today?',
      scheduledTime: nextMorning,
    );
  }

  Future<void> deactivateCareMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('care_mode_active', false);
    for (int i = 0; i < 7; i++) {
      await NotificationService.instance.cancel(1100 + i);
    }
  }

  static Future<bool> isCareModeActive() async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool('care_mode_active') ?? false;
    if (!active) return false;
    final startedStr = prefs.getString('care_mode_started');
    if (startedStr != null) {
      final started = DateTime.tryParse(startedStr);
      if (started != null && DateTime.now().difference(started).inHours > 48) {
        await prefs.setBool('care_mode_active', false);
        return false;
      }
    }
    return true;
  }

  static String getCareModeContext() {
    return '\n=== CARE MODE ACTIVE ===\n'
        'The user is SICK. Be extra gentle, warm, and caring.\n'
        'Ask how they\'re feeling, remind them to rest, drink water, take medicine.\n'
        'Keep responses SHORT and comforting. Don\'t assign tasks or push goals.\n'
        'Speak softly like a real dad caring for a sick child.\n';
  }

  static List<String> getSickResponses(String nickname) => [
    'Oh no, $nickname. Take it easy. Rest is the best medicine right now.',
    'I\'m sorry you\'re not feeling well, $nickname. Drink water, rest, and take your medicine. I\'ll keep checking on you.',
    'Take care of yourself, $nickname. No tasks today, just rest. I\'ll be here.',
  ];

  // ════════════════════════════════════════════════════
  //  2. EMOTIONAL SUPPORT (SADNESS, STRESS, LONELINESS)
  // ════════════════════════════════════════════════════

  static const _distressKeywords = [
    'sad', 'depressed', 'lonely', 'crying', 'stressed', 'overwhelmed',
    'anxious', 'panic', 'scared', 'heartbroken', 'broken', 'lost',
    'hopeless', 'failed', 'rejected', 'bullied', 'fight', 'argument',
    'breakup', 'broke up', 'divorced', 'lost my job', 'fired',
    'can\'t sleep', 'nightmare', 'miss my mom', 'miss my dad',
    'miss my family', 'no friends', 'nobody cares', 'hate myself',
    'worthless', 'frustrated', 'angry', 'upset', 'disappointed',
    'exhausted', 'burned out', 'burnout', 'miserable', 'hurt',
    'betrayed', 'abandoned', 'confused', 'struggling', 'suffering',
    'didn\'t pass', 'did not pass', 'flunked', 'bad grade',
    'not good enough', 'give up', 'giving up', 'can\'t do this',
    'i\'m done', 'i quit', 'what\'s the point', 'why bother',
    'i suck', 'i\'m stupid', 'i\'m dumb', 'loser',
  ];

  static bool detectDistress(String text) {
    final lower = text.toLowerCase();
    for (final kw in _distressKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  /// Schedule multiple emotional support check-ins
  Future<void> scheduleEmotionalFollowUp(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final lastFollowUp = prefs.getString('last_emotional_followup');
    if (lastFollowUp != null) {
      final last = DateTime.tryParse(lastFollowUp);
      if (last != null && DateTime.now().difference(last).inHours < 4) return;
    }

    await prefs.setString('last_emotional_followup', DateTime.now().toIso8601String());
    final now = DateTime.now();

    // Follow-up 1: 1 hour later
    final oneHour = now.add(const Duration(hours: 1));
    if (oneHour.hour < 23 && oneHour.hour >= 7) {
      final msgs1 = [
        'Hey $nickname, just checking. How are you holding up?',
        '$nickname, I\'m still here. Want to talk about it?',
        'Quick check $nickname. You\'re not alone. I\'m right here.',
      ];
      await NotificationService.instance.scheduleNotification(
        id: 1200,
        title: 'AI Daddy',
        body: msgs1[_rng.nextInt(msgs1.length)],
        scheduledTime: oneHour,
      );
    }

    // Follow-up 2: 3 hours later
    final threeHours = now.add(const Duration(hours: 3));
    if (threeHours.hour < 23 && threeHours.hour >= 7) {
      final msgs3 = [
        '$nickname, remember — bad moments pass. You\'re stronger than you think.',
        'Hey $nickname. Whatever happened, it doesn\'t define you. Keep going.',
        '$nickname, take a deep breath. I believe in you, always.',
      ];
      await NotificationService.instance.scheduleNotification(
        id: 1201,
        title: 'AI Daddy',
        body: msgs3[_rng.nextInt(msgs3.length)],
        scheduledTime: threeHours,
      );
    }

    // Follow-up 3: Next morning
    var nextMorning = DateTime(now.year, now.month, now.day + 1, 9, 0);
    if (now.hour < 9) {
      nextMorning = DateTime(now.year, now.month, now.day, 9, 0);
    }
    final morningMsgs = [
      'Good morning $nickname. Yesterday was tough, but today is a new start. How are you?',
      'Morning $nickname. I hope you slept okay. I\'m here whenever you need me.',
      'Hey $nickname. New day, clean slate. Talk to me when you\'re ready.',
    ];
    await NotificationService.instance.scheduleNotification(
      id: 1202,
      title: 'AI Daddy',
      body: morningMsgs[_rng.nextInt(morningMsgs.length)],
      scheduledTime: nextMorning,
    );

    // Follow-up 4: Next evening (soft check-in)
    final nextEvening = DateTime(now.year, now.month, now.day + 1, 19, 0);
    await NotificationService.instance.scheduleNotification(
      id: 1203,
      title: 'AI Daddy',
      body: 'How was your day today $nickname? I hope it was better than yesterday.',
      scheduledTime: nextEvening,
    );
  }

  // ════════════════════════════════════════════════════
  //  3. TRAVEL MODE — AUTO CHECK-INS DURING TRAVEL
  // ════════════════════════════════════════════════════

  static const _travelKeywords = [
    'traveling', 'travelling', 'travel', 'trip', 'flight', 'airport',
    'plane', 'train', 'bus ride', 'road trip', 'vacation', 'holiday',
    'going abroad', 'going overseas', 'leaving town', 'going on a trip',
    'packing', 'luggage', 'boarding', 'hotel', 'arrived', 'landing',
  ];

  /// Detect travel-related messages
  static bool detectTravel(String text) {
    final lower = text.toLowerCase();
    for (final kw in _travelKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  /// Activate travel mode + schedule caring travel check-ins
  Future<void> activateTravelMode(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getBool('travel_mode') ?? false;
    if (already) return;

    await prefs.setBool('travel_mode', true);
    await prefs.setString('travel_mode_started', DateTime.now().toIso8601String());

    final now = DateTime.now();

    // Schedule travel check-in reminders
    final travelMessages = [
      'Hey $nickname, did you arrive safe? Let me know.',
      '$nickname, how\'s the trip going? Stay safe out there.',
      'Quick check $nickname. Are you eating well? Don\'t forget to stay hydrated.',
      'Hey $nickname, hope you\'re having a great time. Remember to rest too.',
      '$nickname, just checking in. Everything okay? Stay safe.',
      'Morning $nickname. Another day of adventure. Take care of yourself.',
    ];

    // Space them: first 3 hours, then every 8 hours up to 6 messages
    for (int i = 0; i < travelMessages.length; i++) {
      final schedTime = i == 0
          ? now.add(const Duration(hours: 3))
          : now.add(Duration(hours: 3 + (i * 8)));
      if (schedTime.hour >= 23 || schedTime.hour < 7) continue;
      await NotificationService.instance.scheduleNotification(
        id: 1600 + i,
        title: 'AI Daddy',
        body: travelMessages[i],
        scheduledTime: schedTime,
      );
    }
  }

  static Future<void> setTravelMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('travel_mode', enabled);
    if (enabled) {
      await prefs.setString('travel_mode_started', DateTime.now().toIso8601String());
    } else {
      // Cancel travel reminders
      for (int i = 0; i < 6; i++) {
        await NotificationService.instance.cancel(1600 + i);
      }
    }
  }

  static Future<bool> isTravelMode() async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool('travel_mode') ?? false;
    if (!active) return false;
    final startedStr = prefs.getString('travel_mode_started');
    if (startedStr != null) {
      final started = DateTime.tryParse(startedStr);
      if (started != null && DateTime.now().difference(started).inDays > 14) {
        await prefs.setBool('travel_mode', false);
        return false;
      }
    }
    return true;
  }

  static Future<bool> shouldSuppressNotification(int notifId) async {
    if (!await isTravelMode()) return false;
    if (notifId >= 200 && notifId <= 399) return true;
    if (notifId >= 100 && notifId <= 104) return true;
    if (notifId >= 800 && notifId <= 899) return true;
    return false;
  }

  // ════════════════════════════════════════════════════
  //  4. STUDY / EXAM SUPPORT
  // ════════════════════════════════════════════════════

  static const _studyKeywords = [
    'exam', 'test', 'quiz', 'study', 'studying', 'homework', 'assignment',
    'project', 'deadline', 'presentation', 'finals', 'midterm',
    'failed exam', 'didn\'t pass', 'did not pass', 'flunked',
    'bad grade', 'low score', 'failed test', 'retake', 'repeat the year',
    'failed class', 'dropped out', 'academic', 'gpa', 'scholarship',
  ];

  static bool detectStudy(String text) {
    final lower = text.toLowerCase();
    for (final kw in _studyKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  /// Schedule study encouragement reminders
  Future<void> scheduleStudySupport(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final lastStudy = prefs.getString('last_study_support');
    if (lastStudy != null) {
      final last = DateTime.tryParse(lastStudy);
      if (last != null && DateTime.now().difference(last).inHours < 4) return;
    }
    await prefs.setString('last_study_support', DateTime.now().toIso8601String());

    final now = DateTime.now();
    final studyMsgs = [
      '$nickname, take a 5-minute break. Stretch, drink water, then get back to it. You\'re doing great.',
      'Hey $nickname, slow and steady wins the race. Don\'t stress, just keep going. I believe in you.',
      '$nickname, hard work always pays off. Even if you don\'t see it now, you\'re building something great.',
      'Quick reminder $nickname: rest your eyes for 5 minutes. Then come back stronger.',
      'One step at a time $nickname. Every hour you study gets you closer. Daddy\'s proud of your effort.',
    ];

    // Break reminder every 90 minutes (more frequent)
    for (int i = 0; i < studyMsgs.length; i++) {
      final schedTime = now.add(Duration(minutes: 90 * (i + 1)));
      if (schedTime.hour >= 23 || schedTime.hour < 7) continue;
      await NotificationService.instance.scheduleNotification(
        id: 1700 + i,
        title: 'AI Daddy',
        body: studyMsgs[i],
        scheduledTime: schedTime,
      );
    }

    // Next morning encouragement
    var nextMorning = DateTime(now.year, now.month, now.day + 1, 8, 0);
    await NotificationService.instance.scheduleNotification(
      id: 1705,
      title: 'AI Daddy',
      body: 'Good morning $nickname. New day, fresh mind. You\'ll do great today. Go get it!',
      scheduledTime: nextMorning,
    );
  }

  // ════════════════════════════════════════════════════
  //  5. ACHIEVEMENT CELEBRATION
  // ════════════════════════════════════════════════════

  static const _achievementKeywords = [
    'passed', 'won', 'got promoted', 'graduated', 'accepted', 'achieved',
    'accomplished', 'succeeded', 'first place', 'got the job', 'hired',
    'i did it', 'made it', 'got an a', 'perfect score', 'nailed it',
    'proud of myself', 'good news',
  ];

  /// Negative words that flip the meaning ("didn't pass" is NOT achievement)
  static const _negativeModifiers = [
    'not ', 'didn\'t ', 'did not ', 'don\'t ', 'never ', 'no ', 'can\'t ',
    'cannot ', 'won\'t ', 'failed', 'couldn\'t ', 'could not ',
    'barely ', 'almost didn\'t ',
  ];

  static bool detectAchievement(String text) {
    final lower = text.toLowerCase();
    // If any negative modifier is present, it's NOT an achievement
    for (final neg in _negativeModifiers) {
      if (lower.contains(neg)) return false;
    }
    for (final kw in _achievementKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  /// Schedule celebration follow-up
  Future<void> scheduleAchievementFollowUp(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final lastAch = prefs.getString('last_achievement_followup');
    if (lastAch != null) {
      final last = DateTime.tryParse(lastAch);
      if (last != null && DateTime.now().difference(last).inHours < 6) return;
    }
    await prefs.setString('last_achievement_followup', DateTime.now().toIso8601String());

    final now = DateTime.now();

    // Celebration follow-up next day
    final nextDay = DateTime(now.year, now.month, now.day + 1, 10, 0);
    final celebMsgs = [
      'Hey $nickname, still smiling about yesterday? You earned it. Keep that energy.',
      '$nickname, yesterday\'s win was just the beginning. Proud of you.',
      'Good morning champ. Remember what you achieved yesterday? That\'s the real you.',
    ];
    await NotificationService.instance.scheduleNotification(
      id: 1800,
      title: 'AI Daddy',
      body: celebMsgs[_rng.nextInt(celebMsgs.length)],
      scheduledTime: nextDay,
    );
  }

  // ════════════════════════════════════════════════════
  //  6. LONELINESS DETECTION
  // ════════════════════════════════════════════════════

  static const _lonelinessKeywords = [
    'lonely', 'alone', 'no friends', 'nobody talks', 'isolated',
    'left out', 'ignored', 'invisible', 'no one cares', 'by myself',
    'miss having friends', 'bored', 'nothing to do', 'empty',
  ];

  static bool detectLoneliness(String text) {
    final lower = text.toLowerCase();
    for (final kw in _lonelinessKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  /// Schedule loneliness support reminders
  Future<void> scheduleLonelinessSupport(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final lastLonely = prefs.getString('last_loneliness_support');
    if (lastLonely != null) {
      final last = DateTime.tryParse(lastLonely);
      if (last != null && DateTime.now().difference(last).inHours < 8) return;
    }
    await prefs.setString('last_loneliness_support', DateTime.now().toIso8601String());

    final now = DateTime.now();

    // Check-in in 2 hours
    final twoH = now.add(const Duration(hours: 2));
    if (twoH.hour < 23 && twoH.hour >= 7) {
      await NotificationService.instance.scheduleNotification(
        id: 1900,
        title: 'AI Daddy',
        body: 'Hey $nickname, I\'m here. You\'re never really alone. Talk to me anytime.',
        scheduledTime: twoH,
      );
    }

    // Evening check-in
    var evening = DateTime(now.year, now.month, now.day, 20, 0);
    if (evening.isBefore(now)) evening = evening.add(const Duration(days: 1));
    await NotificationService.instance.scheduleNotification(
      id: 1901,
      title: 'AI Daddy',
      body: 'How was your evening $nickname? Remember, I\'m always just a message away.',
      scheduledTime: evening,
    );

    // Next morning
    final morning = DateTime(now.year, now.month, now.day + 1, 8, 0);
    await NotificationService.instance.scheduleNotification(
      id: 1902,
      title: 'AI Daddy',
      body: 'Good morning $nickname. Today is a good day to try something new. What do you say?',
      scheduledTime: morning,
    );
  }

  // ════════════════════════════════════════════════════
  //  7. RANDOM LOVE NOTES (1 SURPRISE/DAY)
  // ════════════════════════════════════════════════════

  static List<String> _loveNotes(String nickname) => [
    'Hey $nickname. Just wanted to say, I\'m proud of you.',
    'Random reminder: you matter, $nickname. Never forget that.',
    '$nickname, you\'re doing better than you think. Keep going.',
    'Daddy\'s thinking of you, $nickname. Have a great rest of your day.',
    'Just checking in to say I love you, $nickname. That\'s it.',
    'Hey champ. You make Daddy proud every single day.',
    '$nickname, breathe. Smile. You\'re alive and that\'s beautiful.',
    'Quick note from Daddy: you\'re amazing. Carry on, $nickname.',
    'No matter what happens today, $nickname, I\'ve got your back. Always.',
    'Fun fact, $nickname: Daddy\'s favorite person is you.',
    'This is your daily reminder that someone believes in you, $nickname.',
    '$nickname, even on bad days, you\'re still incredible. Don\'t forget.',
    'Hey $nickname. The world is lucky to have you.',
    'Daddy note: eat well, drink water, be kind to yourself today, $nickname.',
    '$nickname, if nobody told you today, you\'re enough. Always have been.',
  ];

  Future<void> scheduleDailyLoveNote(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final lastNote = prefs.getString('last_love_note_date');
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    if (lastNote == todayStr) return;

    await prefs.setString('last_love_note_date', todayStr);

    final randomHour = 10 + _rng.nextInt(11);
    final randomMinute = _rng.nextInt(60);
    var noteTime = DateTime(today.year, today.month, today.day, randomHour, randomMinute);
    if (noteTime.isBefore(today)) {
      noteTime = noteTime.add(const Duration(days: 1));
    }

    final notes = _loveNotes(nickname);
    await NotificationService.instance.scheduleNotification(
      id: 1300,
      title: 'AI Daddy',
      body: notes[_rng.nextInt(notes.length)],
      scheduledTime: noteTime,
    );
  }

  // ════════════════════════════════════════════════════
  //  8. MILESTONE CELEBRATIONS
  // ════════════════════════════════════════════════════

  static const _milestones = [7, 30, 60, 100, 200, 365];

  static Map<int, String> _milestoneMessages(String nickname) => {
    7: '1 WEEK with AI Daddy! You and me, $nickname, 7 days strong. Here\'s to many more!',
    30: '30 DAYS! A whole month, $nickname! You\'ve grown so much. Daddy is incredibly proud.',
    60: '60 DAYS! Two months of growth, $nickname. You\'re unstoppable. Keep it up!',
    100: '100 DAYS! Triple digits, $nickname! This is a huge milestone.',
    200: '200 DAYS! $nickname, you\'re a legend. Half a year of greatness.',
    365: 'ONE YEAR! 365 days, $nickname. A whole year together. Forever proud.',
  };

  Future<void> checkMilestones(String nickname, String createdAt) async {
    final prefs = await SharedPreferences.getInstance();
    final created = DateTime.tryParse(createdAt);
    if (created == null) return;

    final daysSinceJoin = DateTime.now().difference(created).inDays;
    for (final milestone in _milestones) {
      if (daysSinceJoin == milestone) {
        final celebratedKey = 'milestone_celebrated_$milestone';
        if (prefs.getBool(celebratedKey) == true) return;
        await prefs.setBool(celebratedKey, true);

        final messages = _milestoneMessages(nickname);
        final msg = messages[milestone];
        if (msg != null) {
          await NotificationService.instance.showNotification(
            id: 1400 + milestone,
            title: 'AI Daddy',
            body: msg,
          );
        }
        return;
      }
    }
  }

  static Map<String, dynamic> getMilestoneInfo(String createdAt) {
    final created = DateTime.tryParse(createdAt);
    if (created == null) return {'days': 0, 'nextMilestone': 7, 'daysUntil': 7};
    final days = DateTime.now().difference(created).inDays;
    int nextMilestone = 7;
    for (final m in _milestones) {
      if (days < m) { nextMilestone = m; break; }
    }
    if (days >= 365) nextMilestone = 365;
    return {
      'days': days,
      'nextMilestone': nextMilestone,
      'daysUntil': (nextMilestone - days).clamp(0, 999),
    };
  }

  // ════════════════════════════════════════════════════
  //  9. FOLLOW-UP MEMORY ("HOW DID IT GO?")
  // ════════════════════════════════════════════════════

  Future<void> scheduleFollowUp({
    required String nickname,
    required String eventDescription,
    required DateTime eventTime,
  }) async {
    final followUpTime = eventTime.add(const Duration(hours: 1));
    if (followUpTime.hour >= 23 || followUpTime.hour < 6) return;

    final followUpMsgs = [
      'Hey $nickname, how did "$eventDescription" go? Tell me about it!',
      '$nickname, your "$eventDescription" should be done by now. How was it?',
      'Quick follow-up $nickname: "$eventDescription", did it go well?',
      'Daddy wants to know: how did "$eventDescription" go, $nickname?',
    ];
    await NotificationService.instance.scheduleNotification(
      id: 1500 + (eventTime.millisecond % 50),
      title: 'AI Daddy',
      body: followUpMsgs[_rng.nextInt(followUpMsgs.length)],
      scheduledTime: followUpTime,
    );
  }

  // ════════════════════════════════════════════════════
  //  10. COMPREHENSIVE SITUATION ANALYZER
  // ════════════════════════════════════════════════════

  /// Analyze a user message and auto-schedule appropriate reminders.
  /// Called from ChatProvider on every message.
  /// Returns the detected situation type (or null).
  Future<String?> analyzeAndAutoRemind(String text, String nickname) async {
    // Check each situation in priority order
    // IMPORTANT: sick first, then study BEFORE achievement
    // ("didn't pass exam" must trigger study, NOT achievement)
    if (detectSickness(text)) {
      await activateCareMode(nickname);
      return 'sick';
    }

    if (detectTravel(text)) {
      await activateTravelMode(nickname);
      return 'travel';
    }

    // Study BEFORE achievement — "failed exam" should trigger study support
    if (detectStudy(text)) {
      await scheduleStudySupport(nickname);
      // Also schedule emotional support if it's a failure
      if (detectDistress(text)) {
        await scheduleEmotionalFollowUp(nickname);
        return 'study_fail';
      }
      return 'study';
    }

    if (detectAchievement(text)) {
      await scheduleAchievementFollowUp(nickname);
      return 'achievement';
    }

    if (detectLoneliness(text)) {
      await scheduleLonelinessSupport(nickname);
      return 'lonely';
    }

    if (detectDistress(text)) {
      await scheduleEmotionalFollowUp(nickname);
      return 'distress';
    }

    return null;
  }

  /// Get a caring feedback message that appears in chat to tell the user
  /// that AI Daddy has set up reminders. Returns null if no feedback is needed.
  String? getSituationFeedback(String situation, String nickname) {
    switch (situation) {
      case 'sick':
        return 'I\'ve set up care reminders to check on you, $nickname. '
            'I\'ll remind you to take medicine, drink water, and rest. '
            'Get well soon. ❤️';
      case 'travel':
        return 'Travel mode activated, $nickname. '
            'I\'ll check in on you during your trip to make sure you\'re safe. ✈️';
      case 'study':
        return 'Study mode ON, $nickname. '
            'I\'ll send you break reminders and encouragement. '
            'You got this! 📚';
      case 'study_fail':
        return 'Hey $nickname, failing doesn\'t make you a failure. '
            'I\'ve set up reminders to encourage you and help you study. '
            'We\'ll get through this together. I believe in you. 💪';
      case 'achievement':
        return 'That\'s amazing, $nickname! I\'m so proud of you! '
            'I\'ll follow up tomorrow to celebrate again. 🎉';
      case 'lonely':
        return 'You\'re not alone, $nickname. I\'m here, always. '
            'I\'ve set reminders to check in on you. '
            'We\'ll get through this. 💙';
      case 'distress':
        return 'I hear you, $nickname. '
            'I\'ve set up check-in reminders to make sure you\'re okay. '
            'Remember, bad moments pass. I\'m always here. 🤗';
      default:
        return null;
    }
  }

  // ════════════════════════════════════════════════════
  //  ALL-IN-ONE INITIALIZATION
  // ════════════════════════════════════════════════════

  Future<void> initialize({
    required int userId,
    required String nickname,
    required String createdAt,
  }) async {
    await checkMilestones(nickname, createdAt);
    await scheduleDailyLoveNote(nickname);
  }
}
