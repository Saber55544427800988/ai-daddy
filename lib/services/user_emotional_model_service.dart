import '../database/database_helper.dart';
import '../models/user_emotional_profile.dart';

/// User Emotional Model — maintains dynamic emotional profile per user.
///
/// Tracks mood, stress frequency, loneliness, sleep patterns,
/// emotional openness, and auto-triggers Support Mode when needed.
///
/// Updated on EVERY user message.
class UserEmotionalModelService {
  static final UserEmotionalModelService instance =
      UserEmotionalModelService._();
  UserEmotionalModelService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // Cached profile per user
  final Map<int, UserEmotionalProfile> _profiles = {};

  /// Get or create emotional profile for a user
  Future<UserEmotionalProfile> getProfile(int userId) async {
    if (_profiles.containsKey(userId)) return _profiles[userId]!;

    final db = await _db.database;
    final rows = await db.query('user_emotional_profile',
        where: 'user_id = ?', whereArgs: [userId], limit: 1);
    if (rows.isNotEmpty) {
      _profiles[userId] = UserEmotionalProfile.fromMap(rows.first);
    } else {
      // Create default profile
      final profile = UserEmotionalProfile(userId: userId);
      final id = await db.insert('user_emotional_profile', profile.toMap());
      _profiles[userId] = UserEmotionalProfile(
        id: id,
        userId: userId,
      );
    }
    return _profiles[userId]!;
  }

  /// Update mood from a new message.
  /// [sentimentScore] is -1.0 to +1.0 from sentiment analysis.
  /// Converts to -5 to +5 range internally.
  Future<UserEmotionalProfile> updateMood(
      int userId, double sentimentScore) async {
    var profile = await getProfile(userId);

    // Convert sentiment (-1..1) to mood (-5..5)
    final moodDelta = sentimentScore * 5.0;

    // Apply with smoothing — don't swing wildly
    final smoothed = profile.currentMoodScore * 0.6 + moodDelta * 0.4;
    profile = profile.addMoodScore(smoothed);

    // Auto-activate support mode if 3+ negative signals in 24h
    int stressCount = profile.stressCount24h;
    if (sentimentScore < -0.3) {
      stressCount++;
    }
    profile = profile.copyWith(
      stressCount24h: stressCount,
      supportModeActive: stressCount >= 3 || profile.supportModeActive,
    );

    // Persist
    await _saveProfile(profile);
    _profiles[userId] = profile;
    return profile;
  }

  /// Track loneliness signal
  Future<void> recordLoneliness(int userId) async {
    var profile = await getProfile(userId);
    profile = profile.copyWith(
      lonelinessCount7d: profile.lonelinessCount7d + 1,
    );
    await _saveProfile(profile);
    _profiles[userId] = profile;
  }

  /// Track health incident
  Future<void> recordHealthIncident(int userId) async {
    var profile = await getProfile(userId);
    profile = profile.copyWith(
      healthIncidents30d: profile.healthIncidents30d + 1,
    );
    await _saveProfile(profile);
    _profiles[userId] = profile;
  }

  /// Update sleep pattern based on message timing
  Future<void> detectSleepPattern(int userId) async {
    final db = await _db.database;
    // Check messages sent between midnight-5am in last 7 days
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7)).toIso8601String();
    final lateNightCount = await db.rawQuery('''
      SELECT COUNT(*) as cnt FROM messages
      WHERE user_id = ? AND timestamp >= ?
      AND CAST(SUBSTR(timestamp, 12, 2) AS INTEGER) BETWEEN 0 AND 5
    ''', [userId, weekAgo]);
    final count = (lateNightCount.first['cnt'] as num?)?.toInt() ?? 0;

    String pattern = 'good';
    if (count >= 10) {
      pattern = 'poor';
    } else if (count >= 4) {
      pattern = 'irregular';
    }

    var profile = await getProfile(userId);
    if (profile.sleepPattern != pattern) {
      profile = profile.copyWith(sleepPattern: pattern);
      await _saveProfile(profile);
      _profiles[userId] = profile;
    }
  }

  /// Update emotional openness based on message depth
  Future<void> updateOpenness(int userId, String message) async {
    var profile = await getProfile(userId);
    double openness = profile.emotionalOpenness;

    // Longer messages about feelings = more open
    final lower = message.toLowerCase();
    final emotionalWords = [
      'feel', 'afraid', 'love', 'hate', 'miss', 'scared',
      'happy', 'sad', 'angry', 'hurt', 'cry', 'worried',
      'alone', 'broken', 'grateful', 'proud', 'ashamed',
    ];
    final hasEmotional = emotionalWords.any((w) => lower.contains(w));
    final isLong = message.length > 100;

    if (hasEmotional && isLong) {
      openness = (openness + 0.05).clamp(0.0, 1.0);
    } else if (hasEmotional) {
      openness = (openness + 0.02).clamp(0.0, 1.0);
    } else if (message.length < 20) {
      openness = (openness - 0.01).clamp(0.0, 1.0);
    }

    if (openness != profile.emotionalOpenness) {
      profile = profile.copyWith(emotionalOpenness: openness);
      await _saveProfile(profile);
      _profiles[userId] = profile;
    }
  }

  /// Deactivate support mode
  Future<void> deactivateSupportMode(int userId) async {
    var profile = await getProfile(userId);
    if (profile.supportModeActive) {
      profile = profile.copyWith(
        supportModeActive: false,
        stressCount24h: 0,
      );
      await _saveProfile(profile);
      _profiles[userId] = profile;
    }
  }

  /// Reset daily counters (call at midnight or on day change)
  Future<void> resetDailyCounters(int userId) async {
    var profile = await getProfile(userId);
    profile = profile.copyWith(stressCount24h: 0);
    await _saveProfile(profile);
    _profiles[userId] = profile;
  }

  /// Build emotional context for AI prompt
  Future<String> buildEmotionalModelContext(int userId) async {
    final profile = await getProfile(userId);
    final buf = StringBuffer();
    buf.writeln('=== USER EMOTIONAL PROFILE ===');
    buf.writeln('Current mood: ${profile.currentMoodScore.toStringAsFixed(1)}/5');
    buf.writeln('Baseline mood: ${profile.baselineMood.toStringAsFixed(1)}/5');
    buf.writeln('Mood trend: ${profile.moodTrend}');
    buf.writeln('Emotional openness: ${(profile.emotionalOpenness * 100).toInt()}%');
    buf.writeln('Sleep pattern: ${profile.sleepPattern}');
    buf.writeln('Attachment: ${profile.attachmentLabel}');
    if (profile.supportModeActive) {
      buf.writeln('⚠️ SUPPORT MODE ACTIVE — user had multiple negative signals');
    }
    if (profile.moodTrend == 'declining') {
      buf.writeln('⚠️ MOOD DECLINING — be extra gentle and proactive');
    }
    return buf.toString();
  }

  /// Save profile to DB
  Future<void> _saveProfile(UserEmotionalProfile profile) async {
    final db = await _db.database;
    if (profile.id != null) {
      await db.update('user_emotional_profile', profile.toMap(),
          where: 'id = ?', whereArgs: [profile.id]);
    } else {
      await db.insert('user_emotional_profile', profile.toMap());
    }
  }
}
