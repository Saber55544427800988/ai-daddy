import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/care_thread_model.dart';
import '../database/database_helper.dart';
import 'notification_service.dart';
import 'emotional_state_engine.dart';
import 'user_emotional_model_service.dart';
import 'ai_reminder_generator.dart';

/// CareThreadEngine — The core brain of AI Daddy's caring system.
///
/// Manages active life-situation threads with:
/// - Auto-detection from chat messages
/// - Persistent follow-up scheduling
/// - Escalation when ignored
/// - Stop conditions when resolved
/// - Priority-based reminder ordering
///
/// Uses 0 AI tokens — all reminders are pre-written templates.
class CareThreadEngine {
  static final CareThreadEngine instance = CareThreadEngine._();
  CareThreadEngine._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final Random _rng = Random();

  // ════════════════════════════════════════════════════
  //  KEYWORD DETECTION MAPS
  // ════════════════════════════════════════════════════

  static const _healthKeywords = [
    'sick', 'ill', 'fever', 'cold', 'flu', 'headache', 'stomach',
    'nausea', 'vomit', 'throwing up', 'cough', 'sore throat',
    'not feeling well', 'feel awful', 'feel terrible', 'unwell',
    'migraine', 'dizzy', 'pain', 'injured', 'hurt myself', 'hospital',
    'doctor', 'medicine', 'antibiotics', 'covid', 'infection',
    'allergy', 'asthma', 'surgery', 'broken bone', 'sprain',
    'can\'t breathe', 'chest pain', 'back pain', 'toothache',
    'مريض', 'حرارة', 'صداع', 'مستشفى', 'دكتور', // Arabic
  ];

  static const _travelKeywords = [
    'traveling', 'travelling', 'travel', 'trip', 'flight', 'airport',
    'plane', 'train', 'bus ride', 'road trip', 'vacation', 'holiday',
    'going abroad', 'going overseas', 'leaving town', 'going on a trip',
    'packing', 'luggage', 'boarding', 'hotel', 'landing',
    'سفر', 'رحلة', 'مطار', 'طيارة', // Arabic
  ];

  static const _sadKeywords = [
    'sad', 'depressed', 'crying', 'heartbroken', 'broken',
    'hopeless', 'rejected', 'bullied', 'breakup', 'broke up',
    'divorced', 'lost my job', 'fired', 'miss my mom', 'miss my dad',
    'miss my family', 'hate myself', 'worthless', 'miserable',
    'betrayed', 'abandoned', 'suffering', 'give up', 'giving up',
    'what\'s the point', 'why bother', 'i suck', 'i\'m done',
    'nobody loves me', 'alone in this', 'can\'t take it',
    'حزين', 'مكتئب', 'وحيد', 'ما أحد يحبني', // Arabic
  ];

  static const _stressKeywords = [
    'stressed', 'overwhelmed', 'too much work', 'busy', 'exhausted',
    'burned out', 'burnout', 'can\'t sleep', 'no time', 'overworked',
    'deadline', 'pressure', 'anxious', 'panic', 'anxiety',
    'frustrated', 'angry', 'losing my mind', 'going crazy',
    'can\'t handle', 'need a break', 'so tired', 'drained',
    'ضغط', 'تعب', 'مشغول', 'قلق', // Arabic
  ];

  static const _studyKeywords = [
    'exam', 'test', 'quiz', 'study', 'studying', 'homework',
    'assignment', 'finals', 'midterm', 'failed exam', 'didn\'t pass',
    'did not pass', 'flunked', 'bad grade', 'low score', 'failed test',
    'retake', 'gpa', 'scholarship', 'presentation',
    'امتحان', 'دراسة', 'واجب', 'رسبت', // Arabic
  ];

  static const _eventKeywords = [
    'meeting', 'interview', 'appointment', 'deadline',
    'presentation', 'conference', 'wedding', 'ceremony',
    'مقابلة', 'موعد', 'اجتماع', // Arabic
  ];

  static const _lonelyKeywords = [
    'lonely', 'alone', 'no friends', 'nobody talks', 'isolated',
    'left out', 'ignored', 'invisible', 'no one cares', 'by myself',
    'miss having friends', 'empty', 'bored', 'nothing to do',
    'وحيد', 'ما عندي أصحاب', 'محد يكلمني', // Arabic
  ];

  static const _achievementKeywords = [
    'passed', 'won', 'got promoted', 'graduated', 'accepted',
    'accomplished', 'succeeded', 'first place', 'got the job',
    'hired', 'i did it', 'made it', 'got an a', 'perfect score',
    'nailed it', 'proud of myself', 'good news',
  ];

  static const _negativeModifiers = [
    'not ', 'didn\'t ', 'did not ', 'don\'t ', 'never ', 'can\'t ',
    'cannot ', 'won\'t ', 'failed', 'couldn\'t ', 'could not ',
    'barely ', 'almost didn\'t ', 'no ',
  ];

  /// STOP condition keywords — user is better / resolved
  static const _healthStopKeywords = [
    'feeling better', 'i\'m better', 'recovered', 'i\'m fine',
    'i\'m okay', 'i\'m good', 'all better', 'got better',
    'not sick anymore', 'healed', 'doctor said ok',
  ];

  static const _travelStopKeywords = [
    'i\'m back', 'arrived home', 'got back', 'returned',
    'trip is over', 'back home', 'back now', 'home safe',
  ];

  static const _emotionStopKeywords = [
    'feeling better', 'i\'m better', 'i\'m okay', 'i\'m good',
    'much better', 'thank you', 'thanks daddy', 'i\'m happy',
    'i\'m fine now', 'doing better', 'it\'s okay', 'moved on',
  ];

  // ════════════════════════════════════════════════════
  //  DETECTION ENGINE
  // ════════════════════════════════════════════════════

  /// Analyze a message and return detected situation info.
  /// Returns null if no situation detected.
  Map<String, dynamic>? analyzeMessage(String text) {
    final lower = text.toLowerCase();

    // Health detection (highest priority)
    for (final kw in _healthKeywords) {
      if (lower.contains(kw)) {
        return {
          'type': 'health',
          'sub_type': kw,
          'intensity': _guessIntensity(lower, 'health'),
        };
      }
    }

    // Travel detection
    for (final kw in _travelKeywords) {
      if (lower.contains(kw)) {
        return {
          'type': 'travel',
          'sub_type': kw,
          'intensity': 'medium',
        };
      }
    }

    // Study detection (before achievement — "failed exam" must trigger study)
    for (final kw in _studyKeywords) {
      if (lower.contains(kw)) {
        final isFail = _negativeModifiers.any((n) => lower.contains(n));
        return {
          'type': 'study',
          'sub_type': isFail ? 'exam_fail' : 'study',
          'intensity': isFail ? 'high' : 'medium',
        };
      }
    }

    // Achievement detection (skip if negative modifiers present)
    final hasNegative = _negativeModifiers.any((n) => lower.contains(n));
    if (!hasNegative) {
      for (final kw in _achievementKeywords) {
        if (lower.contains(kw)) {
          return {
            'type': 'achievement',
            'sub_type': kw,
            'intensity': 'high',
          };
        }
      }
    }

    // Important events (meeting, interview, etc.)
    for (final kw in _eventKeywords) {
      if (lower.contains(kw)) {
        return {
          'type': 'event',
          'sub_type': kw,
          'intensity': 'medium',
        };
      }
    }

    // Loneliness
    for (final kw in _lonelyKeywords) {
      if (lower.contains(kw)) {
        return {
          'type': 'loneliness',
          'sub_type': kw,
          'intensity': 'medium',
        };
      }
    }

    // Sad / emotional
    for (final kw in _sadKeywords) {
      if (lower.contains(kw)) {
        return {
          'type': 'emotion',
          'sub_type': kw,
          'intensity': _guessIntensity(lower, 'emotion'),
        };
      }
    }

    // Stress
    for (final kw in _stressKeywords) {
      if (lower.contains(kw)) {
        return {
          'type': 'stress',
          'sub_type': kw,
          'intensity': _guessIntensity(lower, 'stress'),
        };
      }
    }

    return null;
  }

  String _guessIntensity(String text, String type) {
    // High intensity markers
    final highMarkers = [
      'hospital', 'surgery', 'can\'t breathe', 'chest pain',
      'hate myself', 'give up', 'suicide', 'dying', 'emergency',
      'panic', 'can\'t take it', 'killing me',
    ];
    for (final m in highMarkers) {
      if (text.contains(m)) return 'high';
    }

    // Low intensity markers
    final lowMarkers = [
      'a bit', 'slightly', 'little', 'kind of', 'somewhat', 'mild',
    ];
    for (final m in lowMarkers) {
      if (text.contains(m)) return 'low';
    }

    return 'medium';
  }

  // ════════════════════════════════════════════════════
  //  STOP CONDITION CHECKING
  // ════════════════════════════════════════════════════

  /// Helper to get thread by ID
  Future<CareThread?> _getThread(int threadId) async {
    final db = await _db.database;
    final rows = await db.query('care_threads',
        where: 'id = ?', whereArgs: [threadId], limit: 1);
    if (rows.isEmpty) return null;
    return CareThread.fromMap(rows.first);
  }

  /// Check if a message contains stop words for active threads.
  /// Returns list of thread types that should be resolved.
  List<String> checkStopConditions(String text) {
    final lower = text.toLowerCase();
    final stops = <String>[];

    for (final kw in _healthStopKeywords) {
      if (lower.contains(kw)) {
        stops.add('health');
        break;
      }
    }
    for (final kw in _travelStopKeywords) {
      if (lower.contains(kw)) {
        stops.add('travel');
        break;
      }
    }
    for (final kw in _emotionStopKeywords) {
      if (lower.contains(kw)) {
        stops.addAll(['emotion', 'loneliness', 'stress']);
        break;
      }
    }

    return stops;
  }

  // ════════════════════════════════════════════════════
  //  CARE THREAD LIFECYCLE
  // ════════════════════════════════════════════════════

  /// Process a user message: detect situations, create/resolve threads,
  /// schedule reminders, and return feedback message for chat.
  Future<String?> processMessage(int userId, String text, String nickname) async {
    // 1. Check stop conditions on active threads
    final stopsFor = checkStopConditions(text);
    if (stopsFor.isNotEmpty) {
      final resolved = await _resolveThreads(userId, stopsFor);
      if (resolved.isNotEmpty) {
        // Transition AI state to relieved
        await EmotionalStateEngine.instance.transitionState(
          userId: userId,
          moodScore: 1.0,
          userRecovered: true,
        );
        // Deactivate support mode if emotion resolved
        if (resolved.contains('emotion') || resolved.contains('stress')) {
          await UserEmotionalModelService.instance.deactivateSupportMode(userId);
        }
        return _buildResolvedFeedback(resolved, nickname);
      }
    }

    // 2. Detect new situation
    final detected = analyzeMessage(text);
    if (detected == null) return null;

    final type = detected['type'] as String;
    final subType = detected['sub_type'] as String;
    final intensity = detected['intensity'] as String;

    // 3. Check if we already have an active thread of this type
    final existing = await _getActiveThread(userId, type);
    if (existing != null) {
      // Already tracking — skip creating duplicate
      return null;
    }

    // 4. Create new care thread
    final thread = CareThread(
      userId: userId,
      type: type,
      subType: subType,
      intensity: intensity,
      startTime: DateTime.now().toIso8601String(),
      triggerMessage: text.length > 200 ? text.substring(0, 200) : text,
    );
    final threadId = await _insertThread(thread);

    // 5. Schedule reminders for this thread
    await _scheduleThreadReminders(userId, threadId, type, subType, intensity, nickname);

    // 6. Save activation state in SharedPreferences for care mode context
    await _saveThreadState(type, true);

    // 7. Update emotional subsystems
    // Transition AI emotional state
    await EmotionalStateEngine.instance.transitionState(
      userId: userId,
      moodScore: type == 'achievement' ? 3.0 : -2.0,
      careThreadType: type,
      careThreadIntensity: intensity,
      userAchievedSomething: type == 'achievement',
    );
    // Track health/loneliness in emotional profile
    if (type == 'health') {
      await UserEmotionalModelService.instance.recordHealthIncident(userId);
    } else if (type == 'loneliness') {
      await UserEmotionalModelService.instance.recordLoneliness(userId);
    }

    // 8. Return feedback message
    return _buildActivationFeedback(type, subType, nickname);
  }

  // ════════════════════════════════════════════════════
  //  REMINDER TEMPLATES (0 AI TOKENS)
  // ════════════════════════════════════════════════════

  Future<void> _scheduleThreadReminders(
    int userId, int threadId, String type, String subType, String intensity, String nickname,
  ) async {
    final now = DateTime.now();

    switch (type) {
      case 'health':
        await _scheduleHealthReminders(userId, threadId, nickname, now, intensity);
        break;
      case 'travel':
        await _scheduleTravelReminders(userId, threadId, nickname, now);
        break;
      case 'emotion':
        await _scheduleEmotionReminders(userId, threadId, nickname, now, intensity);
        break;
      case 'stress':
        await _scheduleStressReminders(userId, threadId, nickname, now);
        break;
      case 'study':
        await _scheduleStudyReminders(userId, threadId, nickname, now, subType);
        break;
      case 'achievement':
        await _scheduleAchievementReminders(userId, threadId, nickname, now);
        break;
      case 'event':
        await _scheduleEventReminders(userId, threadId, nickname, now, subType);
        break;
      case 'loneliness':
        await _scheduleLonelinessReminders(userId, threadId, nickname, now);
        break;
    }
  }

  Future<void> _scheduleHealthReminders(
      int userId, int threadId, String nickname, DateTime now, String intensity) async {
    // Get user ID from thread
    final thread = await _getThread(threadId);
    if (thread == null) return;

    final userId = thread.userId;
    final generator = AIReminderGenerator.instance;

    // 3 reminders max: check-in, evening, next morning
    final checkIn = now.add(const Duration(hours: 3));
    if (checkIn.hour < 23 && checkIn.hour >= 7) {
      final msg = await generator.generateReminder(
        userId: userId,
        nickname: nickname,
        threadType: 'health',
        threadSubType: thread.subType,
        followUpType: 'initial',
        originalMessage: thread.triggerMessage,
      );
      await NotificationService.instance.scheduleNotification(
        id: 2000 + threadId * 10,
        title: 'AI Daddy',
        body: msg,
        scheduledTime: checkIn,
      );
    }
    var evening = DateTime(now.year, now.month, now.day, 21, 30);
    if (evening.isBefore(now)) evening = evening.add(const Duration(days: 1));
    final eveningMsg = await generator.generateReminder(
      userId: userId,
      nickname: nickname,
      threadType: 'health',
      threadSubType: thread.subType,
      followUpType: 'evening',
    );
    await NotificationService.instance.scheduleNotification(
      id: 2000 + threadId * 10 + 1,
      title: 'AI Daddy',
      body: eveningMsg,
      scheduledTime: evening,
    );
    final morning = DateTime(now.year, now.month, now.day + 1, 8, 30);
    final morningMsg = await generator.generateReminder(
      userId: userId,
      nickname: nickname,
      threadType: 'health',
      threadSubType: thread.subType,
      followUpType: 'morning',
    );
    await NotificationService.instance.scheduleNotification(
      id: 2000 + threadId * 10 + 2,
      title: 'AI Daddy',
      body: morningMsg,
      scheduledTime: morning,
    );
  }

  Future<void> _scheduleTravelReminders(
      int userId, int threadId, String nickname, DateTime now) async {
    final thread = await _getThread(threadId);
    if (thread == null) return;
    final generator = AIReminderGenerator.instance;

    // 2 reminders: arrival check + next day check
    final arrival = now.add(const Duration(hours: 4));
    if (arrival.hour < 23 && arrival.hour >= 7) {
      final arrivalMsg = await generator.generateReminder(
        userId: userId,
        nickname: nickname,
        threadType: 'travel',
        threadSubType: thread.subType,
        followUpType: 'check',
        originalMessage: thread.triggerMessage,
      );
      await NotificationService.instance.scheduleNotification(
        id: 2100 + threadId * 10,
        title: 'AI Daddy',
        body: arrivalMsg,
        scheduledTime: arrival,
      );
    }
    final nextDay = DateTime(now.year, now.month, now.day + 1, 10, 0);
    final nextDayMsg = await generator.generateReminder(
      userId: userId,
      nickname: nickname,
      threadType: 'travel',
      threadSubType: thread.subType,
      followUpType: 'morning',
    );
    await NotificationService.instance.scheduleNotification(
      id: 2100 + threadId * 10 + 1,
      title: 'AI Daddy',
      body: nextDayMsg,
      scheduledTime: nextDay,
    );
  }

  Future<void> _scheduleEmotionReminders(
      int userId, int threadId, String nickname, DateTime now, String intensity) async {
    final thread = await _getThread(threadId);
    if (thread == null) return;

    final userId = thread.userId;
    final generator = AIReminderGenerator.instance;

    // 2 reminders: later check + next morning
    final laterH = intensity == 'high' ? 3 : 5;
    final later = now.add(Duration(hours: laterH));
    if (later.hour < 23 && later.hour >= 7) {
      final msg = await generator.generateReminder(
        userId: userId,
        nickname: nickname,
        threadType: 'emotion',
        threadSubType: thread.subType,
        followUpType: 'check',
        originalMessage: thread.triggerMessage,
      );
      await NotificationService.instance.scheduleNotification(
        id: 2200 + threadId * 10,
        title: 'AI Daddy',
        body: msg,
        scheduledTime: later,
      );
    }
    final morning = DateTime(now.year, now.month, now.day + 1, 9, 0);
    final morningMsg = await generator.generateReminder(
      userId: userId,
      nickname: nickname,
      threadType: 'emotion',
      threadSubType: thread.subType,
      followUpType: 'morning',
    );
    await NotificationService.instance.scheduleNotification(
      id: 2200 + threadId * 10 + 1,
      title: 'AI Daddy',
      body: morningMsg,
      scheduledTime: morning,
    );
  }

  Future<void> _scheduleStressReminders(
      int userId, int threadId, String nickname, DateTime now) async {
    final thread = await _getThread(threadId);
    if (thread == null) return;

    final userId = thread.userId;
    final generator = AIReminderGenerator.instance;

    // 2 reminders: rest check + sleep reminder
    final restCheck = now.add(const Duration(hours: 3));
    if (restCheck.hour < 23 && restCheck.hour >= 7) {
      final msg = await generator.generateReminder(
        userId: userId,
        nickname: nickname,
        threadType: 'stress',
        threadSubType: thread.subType,
        followUpType: 'check',
        originalMessage: thread.triggerMessage,
      );
      await NotificationService.instance.scheduleNotification(
        id: 2300 + threadId * 10,
        title: 'AI Daddy',
        body: msg,
        scheduledTime: restCheck,
      );
    }
    var bedtime = DateTime(now.year, now.month, now.day, 22, 30);
    if (bedtime.isBefore(now)) bedtime = bedtime.add(const Duration(days: 1));
    final bedMsg = await generator.generateReminder(
      userId: userId,
      nickname: nickname,
      threadType: 'stress',
      threadSubType: thread.subType,
      followUpType: 'evening',
    );
    await NotificationService.instance.scheduleNotification(
      id: 2300 + threadId * 10 + 1,
      title: 'AI Daddy',
      body: bedMsg,
      scheduledTime: bedtime,
    );
  }

  Future<void> _scheduleStudyReminders(
      int userId, int threadId, String nickname, DateTime now, String subType) async {
    final thread = await _getThread(threadId);
    if (thread == null) return;
    final generator = AIReminderGenerator.instance;

    // 2 reminders: encouragement + next morning
    final isFail = subType == 'exam_fail';
    final later = now.add(Duration(hours: isFail ? 3 : 2));
    if (later.hour < 23 && later.hour >= 7) {
      final laterMsg = await generator.generateReminder(
        userId: userId,
        nickname: nickname,
        threadType: 'study',
        threadSubType: subType,
        followUpType: 'check',
        originalMessage: thread.triggerMessage,
      );
      await NotificationService.instance.scheduleNotification(
        id: 2400 + threadId * 10,
        title: 'AI Daddy',
        body: laterMsg,
        scheduledTime: later,
      );
    }
    final morning = DateTime(now.year, now.month, now.day + 1, 8, 0);
    final morningMsg = await generator.generateReminder(
      userId: userId,
      nickname: nickname,
      threadType: 'study',
      threadSubType: subType,
      followUpType: 'morning',
    );
    await NotificationService.instance.scheduleNotification(
      id: 2400 + threadId * 10 + 1,
      title: 'AI Daddy',
      body: morningMsg,
      scheduledTime: morning,
    );
  }

  Future<void> _scheduleAchievementReminders(
      int userId, int threadId, String nickname, DateTime now) async {
    final thread = await _getThread(threadId);
    if (thread == null) return;
    final generator = AIReminderGenerator.instance;

    final nextDay = DateTime(now.year, now.month, now.day + 1, 10, 0);
    final msg = await generator.generateReminder(
      userId: userId,
      nickname: nickname,
      threadType: 'achievement',
      threadSubType: thread.subType,
      followUpType: 'morning',
      originalMessage: thread.triggerMessage,
    );
    await NotificationService.instance.scheduleNotification(
      id: 2500 + threadId * 10,
      title: 'AI Daddy',
      body: msg,
      scheduledTime: nextDay,
    );
  }

  Future<void> _scheduleEventReminders(
      int userId, int threadId, String nickname, DateTime now, String subType) async {
    final thread = await _getThread(threadId);
    if (thread == null) return;
    final generator = AIReminderGenerator.instance;

    // Encourage before, follow up after
    // 1 hour before a rough estimate + 3 hours after
    final oneH = now.add(const Duration(hours: 1));
    if (oneH.hour < 23 && oneH.hour >= 7) {
      final beforeMsg = await generator.generateReminder(
        userId: userId,
        nickname: nickname,
        threadType: 'event',
        threadSubType: subType,
        followUpType: 'before_event',
        originalMessage: thread.triggerMessage,
      );
      await NotificationService.instance.scheduleNotification(
        id: 2700 + threadId * 10,
        title: 'AI Daddy',
        body: beforeMsg,
        scheduledTime: oneH,
      );
    }
    final threeH = now.add(const Duration(hours: 3));
    if (threeH.hour < 23 && threeH.hour >= 7) {
      final afterMsg = await generator.generateReminder(
        userId: userId,
        nickname: nickname,
        threadType: 'event',
        threadSubType: subType,
        followUpType: 'check',
      );
      await NotificationService.instance.scheduleNotification(
        id: 2700 + threadId * 10 + 1,
        title: 'AI Daddy',
        body: afterMsg,
        scheduledTime: threeH,
      );
    }
  }

  Future<void> _scheduleLonelinessReminders(
      int userId, int threadId, String nickname, DateTime now) async {
    final thread = await _getThread(threadId);
    if (thread == null) return;
    final generator = AIReminderGenerator.instance;

    // 2 reminders: later check + next morning
    final later = now.add(const Duration(hours: 4));
    if (later.hour < 23 && later.hour >= 7) {
      final laterMsg = await generator.generateReminder(
        userId: userId,
        nickname: nickname,
        threadType: 'loneliness',
        threadSubType: thread.subType,
        followUpType: 'check',
        originalMessage: thread.triggerMessage,
      );
      await NotificationService.instance.scheduleNotification(
        id: 2600 + threadId * 10,
        title: 'AI Daddy',
        body: laterMsg,
        scheduledTime: later,
      );
    }
    final morning = DateTime(now.year, now.month, now.day + 1, 9, 0);
    final morningMsg = await generator.generateReminder(
      userId: userId,
      nickname: nickname,
      threadType: 'loneliness',
      threadSubType: thread.subType,
      followUpType: 'morning',
    );
    await NotificationService.instance.scheduleNotification(
      id: 2600 + threadId * 10 + 1,
      title: 'AI Daddy',
      body: morningMsg,
      scheduledTime: morning,
    );
  }

  // ════════════════════════════════════════════════════
  //  FEEDBACK MESSAGES (shown in chat)
  // ════════════════════════════════════════════════════

  String _buildActivationFeedback(String type, String subType, String nickname) {
    switch (type) {
      case 'health':
        return 'I\'ll keep checking on you, $nickname. '
            'Take your medicine, drink water, and rest. '
            'I\'m not going anywhere. ❤️';
      case 'travel':
        return 'Travel mode on. '
            'I\'ll check if you\'re safe, eating, and sleeping. ✈️';
      case 'emotion':
        return 'I hear you, $nickname. '
            'I\'ll check on you. Remember — bad moments pass. '
            'I\'m here. 🤗';
      case 'stress':
        return 'Take a breath, $nickname. '
            'I\'ll remind you to rest and eat. '
            'Don\'t carry it all alone. 💙';
      case 'study':
        if (subType == 'exam_fail') {
          return 'Hey $nickname. One exam doesn\'t define you. '
              'I\'ve set reminders to help you study and recover. '
              'We\'ll get through this together. 💪';
        }
        return 'Study mode on, $nickname. '
            'I\'ll remind you to take breaks. You got this. 📚';
      case 'achievement':
        return 'That\'s my kid! I\'m so proud of you, $nickname! 🎉';
      case 'event':
        return 'Noted, $nickname. I\'ll encourage you before and follow up after. 📋';
      case 'loneliness':
        return 'You\'re not alone, $nickname. '
            'I\'m here. Always. '
            'I\'ll check in on you. 💙';
      default:
        return 'I\'ll check on you, $nickname.';
    }
  }

  String? _buildResolvedFeedback(List<String> resolvedTypes, String nickname) {
    if (resolvedTypes.isEmpty) return null;
    final type = resolvedTypes.first;
    switch (type) {
      case 'health':
        return 'Glad you\'re feeling better, $nickname. '
            'Take it easy though. I\'ll stop the health reminders. 😊';
      case 'travel':
        return 'Welcome back, $nickname! '
            'Glad you\'re home safe. Travel mode off. 🏠';
      case 'emotion':
      case 'loneliness':
      case 'stress':
        return 'Good to hear, $nickname. '
            'That makes Daddy happy. I\'m always here if you need me. 😊';
      default:
        return null;
    }
  }

  // ════════════════════════════════════════════════════
  //  ESCALATION ENGINE
  // ════════════════════════════════════════════════════

  /// Get escalated reminder text based on escalation level.
  /// Called when user hasn't responded to reminders.
  static List<String> getEscalatedMessages(String nickname, int level) {
    switch (level) {
      case 0: // Normal
        return [
          'How are you, $nickname?',
          'Checking on you.',
        ];
      case 1: // Firmer
        return [
          'Answer me, $nickname.',
          '$nickname. Talk to me.',
          'I\'m still waiting for your reply.',
        ];
      case 2: // Insistent
        return [
          'Don\'t ignore me, $nickname.',
          '$nickname, you\'re worrying me.',
          'I need to hear from you.',
        ];
      default:
        return ['I\'m still here, $nickname. Please respond.'];
    }
  }

  /// Check for active threads that need escalation
  /// (no user reply after reminder was sent).
  Future<void> checkEscalation(int userId, String nickname) async {
    final threads = await getActiveThreads(userId);
    for (final thread in threads) {
      if (thread.lastFollowUp != null) {
        final lastFU = DateTime.tryParse(thread.lastFollowUp!);
        if (lastFU != null) {
          final hoursSince = DateTime.now().difference(lastFU).inHours;
          // Escalate if no reply for 6+ hours
          if (hoursSince >= 6 && thread.escalationLevel < 2) {
            final newLevel = thread.escalationLevel + 1;
            await _updateThread(thread.id!, {
              'escalation_level': newLevel,
              'ignored_count': thread.ignoredCount + 1,
            });
            final msgs = getEscalatedMessages(nickname, newLevel);
            await NotificationService.instance.showNotification(
              id: 3000 + (thread.id ?? 0),
              title: 'AI Daddy',
              body: msgs[_rng.nextInt(msgs.length)],
            );
          }
        }
      }
    }
  }

  // ════════════════════════════════════════════════════
  //  CARE MODE CONTEXT (for AI prompt)
  // ════════════════════════════════════════════════════

  /// Build context string for the AI system prompt based on active threads.
  Future<String> buildCareContext(int userId) async {
    final threads = await getActiveThreads(userId);
    if (threads.isEmpty) return '';

    final buf = StringBuffer('\n=== ACTIVE CARE THREADS ===\n');
    for (final t in threads) {
      switch (t.type) {
        case 'health':
          buf.writeln('User is SICK. Be extra gentle and caring. '
              'Ask how they\'re feeling. Remind to rest, drink water, take medicine. '
              'Keep responses SHORT and comforting.');
          break;
        case 'travel':
          buf.writeln('User is TRAVELING. Ask about safety, food, sleep. '
              'Be protective but supportive.');
          break;
        case 'emotion':
          buf.writeln('User is going through EMOTIONAL PAIN. Be very gentle. '
              'Listen. Don\'t lecture. Just be present. Short, warm responses.');
          break;
        case 'stress':
          buf.writeln('User is STRESSED. Remind to breathe, eat, sleep. '
              'Don\'t add pressure. Be calming.');
          break;
        case 'study':
          if (t.subType == 'exam_fail') {
            buf.writeln('User FAILED AN EXAM. Be encouraging. Don\'t minimize. '
                'Help them plan to study again. Show belief in them.');
          } else {
            buf.writeln('User is STUDYING. Be encouraging. '
                'Remind to take breaks. Keep it short and motivating.');
          }
          break;
        case 'loneliness':
          buf.writeln('User feels LONELY. Be present. Make them feel heard. '
              'Suggest activities gently. Remind them they matter.');
          break;
      }
    }
    return buf.toString();
  }

  // ════════════════════════════════════════════════════
  //  DATABASE OPERATIONS
  // ════════════════════════════════════════════════════

  Future<int> _insertThread(CareThread thread) async {
    final db = await _db.database;
    return await db.insert('care_threads', thread.toMap());
  }

  Future<void> _updateThread(int id, Map<String, dynamic> updates) async {
    final db = await _db.database;
    await db.update('care_threads', updates, where: 'id = ?', whereArgs: [id]);
  }

  Future<CareThread?> _getActiveThread(int userId, String type) async {
    final db = await _db.database;
    final results = await db.query(
      'care_threads',
      where: 'user_id = ? AND type = ? AND status = ?',
      whereArgs: [userId, type, 'active'],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return CareThread.fromMap(results.first);
  }

  Future<List<CareThread>> getActiveThreads(int userId) async {
    final db = await _db.database;
    final results = await db.query(
      'care_threads',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'active'],
      orderBy: 'start_time DESC',
    );
    final threads = results.map((r) => CareThread.fromMap(r)).toList();

    // Auto-expire old threads
    for (final t in threads) {
      if (t.isExpired) {
        await _updateThread(t.id!, {
          'status': 'expired',
          'end_time': DateTime.now().toIso8601String(),
        });
      }
    }

    return threads.where((t) => !t.isExpired).toList();
  }

  Future<List<String>> _resolveThreads(int userId, List<String> types) async {
    final resolved = <String>[];
    final db = await _db.database;
    for (final type in types) {
      final count = await db.update(
        'care_threads',
        {
          'status': 'resolved',
          'end_time': DateTime.now().toIso8601String(),
        },
        where: 'user_id = ? AND type = ? AND status = ?',
        whereArgs: [userId, type, 'active'],
      );
      if (count > 0) {
        resolved.add(type);
        await _saveThreadState(type, false);
      }
    }
    return resolved;
  }

  Future<void> _saveThreadState(String type, bool active) async {
    final prefs = await SharedPreferences.getInstance();
    switch (type) {
      case 'health':
        await prefs.setBool('care_mode_active', active);
        if (active) {
          await prefs.setString('care_mode_started', DateTime.now().toIso8601String());
        }
        break;
      case 'travel':
        await prefs.setBool('travel_mode', active);
        if (active) {
          await prefs.setString('travel_mode_started', DateTime.now().toIso8601String());
        }
        break;
    }
  }

  /// Get count of active threads
  Future<int> getActiveThreadCount(int userId) async {
    final threads = await getActiveThreads(userId);
    return threads.length;
  }

  /// Initialize thread table in database
  static Future<void> createTable(dynamic db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS care_threads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        sub_type TEXT DEFAULT '',
        status TEXT DEFAULT 'active',
        intensity TEXT DEFAULT 'medium',
        escalation_level INTEGER DEFAULT 0,
        follow_up_count INTEGER DEFAULT 0,
        ignored_count INTEGER DEFAULT 0,
        start_time TEXT NOT NULL,
        end_time TEXT,
        last_follow_up TEXT,
        trigger_message TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
  }
}
