import 'dart:convert';

/// Dynamic Emotional Profile per user.
///
/// Tracks baseline mood, stress/loneliness frequency,
/// sleep patterns, emotional openness, and attachment level.
/// Updated on every message via sentiment detection.
class UserEmotionalProfile {
  final int? id;
  final int userId;
  final double baselineMood; // long-term average (-5 to +5)
  final double currentMoodScore; // current session (-5 to +5)
  final int stressCount24h; // negative signals in last 24h
  final int lonelinessCount7d; // loneliness signals in 7 days
  final String sleepPattern; // good, irregular, poor, unknown
  final int healthIncidents30d; // health threads in 30 days
  final double emotionalOpenness; // 0.0–1.0 how open user is
  final int attachmentScore; // 0–100
  final String lastMoodUpdate; // ISO timestamp
  final String moodTrend; // improving, stable, declining
  final String recentMoods; // JSON array of last 20 mood scores
  final bool supportModeActive; // auto-triggered by multiple negatives

  UserEmotionalProfile({
    this.id,
    required this.userId,
    this.baselineMood = 0.0,
    this.currentMoodScore = 0.0,
    this.stressCount24h = 0,
    this.lonelinessCount7d = 0,
    this.sleepPattern = 'unknown',
    this.healthIncidents30d = 0,
    this.emotionalOpenness = 0.3,
    this.attachmentScore = 20,
    this.lastMoodUpdate = '',
    this.moodTrend = 'stable',
    this.recentMoods = '[]',
    this.supportModeActive = false,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'baseline_mood': baselineMood,
        'current_mood_score': currentMoodScore,
        'stress_count_24h': stressCount24h,
        'loneliness_count_7d': lonelinessCount7d,
        'sleep_pattern': sleepPattern,
        'health_incidents_30d': healthIncidents30d,
        'emotional_openness': emotionalOpenness,
        'attachment_score': attachmentScore,
        'last_mood_update': lastMoodUpdate,
        'mood_trend': moodTrend,
        'recent_moods': recentMoods,
        'support_mode_active': supportModeActive ? 1 : 0,
      };

  factory UserEmotionalProfile.fromMap(Map<String, dynamic> m) =>
      UserEmotionalProfile(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        baselineMood: (m['baseline_mood'] as num?)?.toDouble() ?? 0.0,
        currentMoodScore: (m['current_mood_score'] as num?)?.toDouble() ?? 0.0,
        stressCount24h: (m['stress_count_24h'] as int?) ?? 0,
        lonelinessCount7d: (m['loneliness_count_7d'] as int?) ?? 0,
        sleepPattern: (m['sleep_pattern'] as String?) ?? 'unknown',
        healthIncidents30d: (m['health_incidents_30d'] as int?) ?? 0,
        emotionalOpenness: (m['emotional_openness'] as num?)?.toDouble() ?? 0.3,
        attachmentScore: (m['attachment_score'] as int?) ?? 20,
        lastMoodUpdate: (m['last_mood_update'] as String?) ?? '',
        moodTrend: (m['mood_trend'] as String?) ?? 'stable',
        recentMoods: (m['recent_moods'] as String?) ?? '[]',
        supportModeActive: (m['support_mode_active'] as int?) == 1,
      );

  UserEmotionalProfile copyWith({
    double? baselineMood,
    double? currentMoodScore,
    int? stressCount24h,
    int? lonelinessCount7d,
    String? sleepPattern,
    int? healthIncidents30d,
    double? emotionalOpenness,
    int? attachmentScore,
    String? lastMoodUpdate,
    String? moodTrend,
    String? recentMoods,
    bool? supportModeActive,
  }) =>
      UserEmotionalProfile(
        id: id,
        userId: userId,
        baselineMood: baselineMood ?? this.baselineMood,
        currentMoodScore: currentMoodScore ?? this.currentMoodScore,
        stressCount24h: stressCount24h ?? this.stressCount24h,
        lonelinessCount7d: lonelinessCount7d ?? this.lonelinessCount7d,
        sleepPattern: sleepPattern ?? this.sleepPattern,
        healthIncidents30d: healthIncidents30d ?? this.healthIncidents30d,
        emotionalOpenness: emotionalOpenness ?? this.emotionalOpenness,
        attachmentScore: attachmentScore ?? this.attachmentScore,
        lastMoodUpdate: lastMoodUpdate ?? this.lastMoodUpdate,
        moodTrend: moodTrend ?? this.moodTrend,
        recentMoods: recentMoods ?? this.recentMoods,
        supportModeActive: supportModeActive ?? this.supportModeActive,
      );

  /// Parsed recent moods list
  List<double> get recentMoodsList {
    try {
      final decoded = jsonDecode(recentMoods);
      return (decoded as List).map((e) => (e as num).toDouble()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Add a new mood score and recalculate trend
  UserEmotionalProfile addMoodScore(double score) {
    final moods = recentMoodsList;
    moods.add(score.clamp(-5.0, 5.0));
    if (moods.length > 20) moods.removeRange(0, moods.length - 20);

    // Calculate trend from last 5 vs previous 5
    String newTrend = 'stable';
    if (moods.length >= 10) {
      final recent5 = moods.sublist(moods.length - 5);
      final prev5 = moods.sublist(moods.length - 10, moods.length - 5);
      final recentAvg = recent5.reduce((a, b) => a + b) / 5;
      final prevAvg = prev5.reduce((a, b) => a + b) / 5;
      if (recentAvg - prevAvg > 0.5) {
        newTrend = 'improving';
      } else if (prevAvg - recentAvg > 0.5) {
        newTrend = 'declining';
      }
    }

    // Recalculate baseline (weighted average of all moods)
    final newBaseline = moods.isNotEmpty
        ? moods.reduce((a, b) => a + b) / moods.length
        : 0.0;

    return copyWith(
      currentMoodScore: score.clamp(-5.0, 5.0),
      baselineMood: newBaseline,
      moodTrend: newTrend,
      recentMoods: jsonEncode(moods),
      lastMoodUpdate: DateTime.now().toIso8601String(),
    );
  }

  /// Check if support mode should auto-activate
  bool get shouldActivateSupportMode =>
      !supportModeActive && stressCount24h >= 3;

  /// Attachment level label
  String get attachmentLabel {
    if (attachmentScore >= 80) return 'deeply_bonded';
    if (attachmentScore >= 60) return 'close';
    if (attachmentScore >= 40) return 'comfortable';
    if (attachmentScore >= 20) return 'warming_up';
    return 'new';
  }
}
