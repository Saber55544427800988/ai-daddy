import 'dart:convert';

/// Enhanced user profile with deep self-learning fields.
/// Tracks per-tone engagement scores, timing patterns, streaks,
/// and reinforcement-learning data for fully adaptive AI behavior.
class UserProfileModel {
  final int? id;
  final String nickname;
  final String favoriteTone;
  final String preferredMessageLength; // short, medium, long
  final String activityPatterns; // JSON string

  // ── Per-tone reinforcement scores ──
  final double caringScore;
  final double strictScore;
  final double playfulScore;
  final double motivationalScore;

  // ── Timing & streak data ──
  final String bestActiveHours; // JSON: {"hour": engagementAvg, ...}
  final int interactionStreak; // consecutive days with ≥1 message
  final int totalInteractions;
  final String preferredReminderTimes; // JSON array of hours
  final String lastWeeklyAnalysis; // ISO-8601

  // ── Message style tracking ──
  final double avgUserMsgLength;
  final double avgResponseTime; // seconds
  final String topIntents; // JSON: {"intent": count, ...}
  final String moodHistory; // JSON array of recent mood scores

  UserProfileModel({
    this.id,
    required this.nickname,
    this.favoriteTone = 'caring',
    this.preferredMessageLength = 'short',
    this.activityPatterns = '{}',
    this.caringScore = 50.0,
    this.strictScore = 50.0,
    this.playfulScore = 50.0,
    this.motivationalScore = 50.0,
    this.bestActiveHours = '{}',
    this.interactionStreak = 0,
    this.totalInteractions = 0,
    this.preferredReminderTimes = '[]',
    this.lastWeeklyAnalysis = '',
    this.avgUserMsgLength = 0.0,
    this.avgResponseTime = 0.0,
    this.topIntents = '{}',
    this.moodHistory = '[]',
  });

  /// Get tone scores as a map for easy comparison
  Map<String, double> get toneScores => {
        'caring': caringScore,
        'strict': strictScore,
        'playful': playfulScore,
        'motivational': motivationalScore,
      };

  /// Best tone based on reinforcement scores
  String get bestTone {
    final scores = toneScores;
    return scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Parsed best active hours
  Map<String, double> get activeHoursMap {
    try {
      final decoded = jsonDecode(bestActiveHours);
      return (decoded as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  /// Parsed top intents
  Map<String, int> get topIntentsMap {
    try {
      final decoded = jsonDecode(topIntents);
      return (decoded as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  /// Parsed mood history
  List<double> get moodHistoryList {
    try {
      final decoded = jsonDecode(moodHistory);
      return (decoded as List).map((e) => (e as num).toDouble()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Average recent mood (0 = unknown)
  double get averageMood {
    final list = moodHistoryList;
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'favorite_tone': favoriteTone,
      'preferred_message_length': preferredMessageLength,
      'activity_patterns': activityPatterns,
      'caring_score': caringScore,
      'strict_score': strictScore,
      'playful_score': playfulScore,
      'motivational_score': motivationalScore,
      'best_active_hours': bestActiveHours,
      'interaction_streak': interactionStreak,
      'total_interactions': totalInteractions,
      'preferred_reminder_times': preferredReminderTimes,
      'last_weekly_analysis': lastWeeklyAnalysis,
      'avg_user_msg_length': avgUserMsgLength,
      'avg_response_time': avgResponseTime,
      'top_intents': topIntents,
      'mood_history': moodHistory,
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] as int?,
      nickname: map['nickname'] as String,
      favoriteTone: map['favorite_tone'] as String? ?? 'caring',
      preferredMessageLength:
          map['preferred_message_length'] as String? ?? 'short',
      activityPatterns: map['activity_patterns'] as String? ?? '{}',
      caringScore: (map['caring_score'] as num?)?.toDouble() ?? 50.0,
      strictScore: (map['strict_score'] as num?)?.toDouble() ?? 50.0,
      playfulScore: (map['playful_score'] as num?)?.toDouble() ?? 50.0,
      motivationalScore:
          (map['motivational_score'] as num?)?.toDouble() ?? 50.0,
      bestActiveHours: map['best_active_hours'] as String? ?? '{}',
      interactionStreak: (map['interaction_streak'] as int?) ?? 0,
      totalInteractions: (map['total_interactions'] as int?) ?? 0,
      preferredReminderTimes:
          map['preferred_reminder_times'] as String? ?? '[]',
      lastWeeklyAnalysis: map['last_weekly_analysis'] as String? ?? '',
      avgUserMsgLength:
          (map['avg_user_msg_length'] as num?)?.toDouble() ?? 0.0,
      avgResponseTime: (map['avg_response_time'] as num?)?.toDouble() ?? 0.0,
      topIntents: map['top_intents'] as String? ?? '{}',
      moodHistory: map['mood_history'] as String? ?? '[]',
    );
  }

  UserProfileModel copyWith({
    int? id,
    String? nickname,
    String? favoriteTone,
    String? preferredMessageLength,
    String? activityPatterns,
    double? caringScore,
    double? strictScore,
    double? playfulScore,
    double? motivationalScore,
    String? bestActiveHours,
    int? interactionStreak,
    int? totalInteractions,
    String? preferredReminderTimes,
    String? lastWeeklyAnalysis,
    double? avgUserMsgLength,
    double? avgResponseTime,
    String? topIntents,
    String? moodHistory,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      favoriteTone: favoriteTone ?? this.favoriteTone,
      preferredMessageLength:
          preferredMessageLength ?? this.preferredMessageLength,
      activityPatterns: activityPatterns ?? this.activityPatterns,
      caringScore: caringScore ?? this.caringScore,
      strictScore: strictScore ?? this.strictScore,
      playfulScore: playfulScore ?? this.playfulScore,
      motivationalScore: motivationalScore ?? this.motivationalScore,
      bestActiveHours: bestActiveHours ?? this.bestActiveHours,
      interactionStreak: interactionStreak ?? this.interactionStreak,
      totalInteractions: totalInteractions ?? this.totalInteractions,
      preferredReminderTimes:
          preferredReminderTimes ?? this.preferredReminderTimes,
      lastWeeklyAnalysis: lastWeeklyAnalysis ?? this.lastWeeklyAnalysis,
      avgUserMsgLength: avgUserMsgLength ?? this.avgUserMsgLength,
      avgResponseTime: avgResponseTime ?? this.avgResponseTime,
      topIntents: topIntents ?? this.topIntents,
      moodHistory: moodHistory ?? this.moodHistory,
    );
  }
}
