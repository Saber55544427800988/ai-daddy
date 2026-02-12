/// Weekly Dad Report model — stores generated reports.
class DadReportModel {
  final int? id;
  final int userId;
  final String weekStart; // ISO date
  final String weekEnd;
  final int totalMessages;
  final int missionsCompleted;
  final int missionsTotal;
  final double avgMood;
  final String moodTrend; // improving, stable, declining
  final int tokensUsed;
  final int remindersMissed;
  final double engagementScore;
  final double growthScore; // 0-100
  final String daddyMessage; // AI-generated summary
  final String highlights; // JSON array
  final String createdAt;

  DadReportModel({
    this.id,
    required this.userId,
    required this.weekStart,
    required this.weekEnd,
    this.totalMessages = 0,
    this.missionsCompleted = 0,
    this.missionsTotal = 0,
    this.avgMood = 3.0,
    this.moodTrend = 'stable',
    this.tokensUsed = 0,
    this.remindersMissed = 0,
    this.engagementScore = 0.0,
    this.growthScore = 0.0,
    this.daddyMessage = '',
    this.highlights = '[]',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'week_start': weekStart,
        'week_end': weekEnd,
        'total_messages': totalMessages,
        'missions_completed': missionsCompleted,
        'missions_total': missionsTotal,
        'avg_mood': avgMood,
        'mood_trend': moodTrend,
        'tokens_used': tokensUsed,
        'reminders_missed': remindersMissed,
        'engagement_score': engagementScore,
        'growth_score': growthScore,
        'daddy_message': daddyMessage,
        'highlights': highlights,
        'created_at': createdAt,
      };

  factory DadReportModel.fromMap(Map<String, dynamic> m) => DadReportModel(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        weekStart: m['week_start'] as String,
        weekEnd: m['week_end'] as String,
        totalMessages: m['total_messages'] as int? ?? 0,
        missionsCompleted: m['missions_completed'] as int? ?? 0,
        missionsTotal: m['missions_total'] as int? ?? 0,
        avgMood: (m['avg_mood'] as num?)?.toDouble() ?? 3.0,
        moodTrend: m['mood_trend'] as String? ?? 'stable',
        tokensUsed: m['tokens_used'] as int? ?? 0,
        remindersMissed: m['reminders_missed'] as int? ?? 0,
        engagementScore: (m['engagement_score'] as num?)?.toDouble() ?? 0.0,
        growthScore: (m['growth_score'] as num?)?.toDouble() ?? 0.0,
        daddyMessage: m['daddy_message'] as String? ?? '',
        highlights: m['highlights'] as String? ?? '[]',
        createdAt: m['created_at'] as String,
      );

  String get growthEmoji {
    if (growthScore >= 80) return '🔥';
    if (growthScore >= 60) return '⭐';
    if (growthScore >= 40) return '💪';
    if (growthScore >= 20) return '🌱';
    return '🌿';
  }

  String get moodTrendEmoji {
    switch (moodTrend) {
      case 'improving':
        return '📈';
      case 'stable':
        return '➡️';
      case 'declining':
        return '📉';
      default:
        return '➡️';
    }
  }
}

/// Relationship depth stages
class RelationshipStage {
  static const stages = [
    {'level': 1, 'title': 'Stranger Dad', 'emoji': '👤', 'minInteractions': 0},
    {'level': 2, 'title': 'Caring Guardian', 'emoji': '🛡️', 'minInteractions': 20},
    {'level': 3, 'title': 'Protective Mentor', 'emoji': '🧭', 'minInteractions': 75},
    {'level': 4, 'title': 'Deep Emotional Bond', 'emoji': '💙', 'minInteractions': 200},
    {'level': 5, 'title': 'Lifetime Dad', 'emoji': '👑', 'minInteractions': 500},
  ];

  static Map<String, dynamic> getStage(int totalInteractions) {
    for (int i = stages.length - 1; i >= 0; i--) {
      if (totalInteractions >= (stages[i]['minInteractions'] as int)) {
        return stages[i];
      }
    }
    return stages[0];
  }

  static Map<String, dynamic>? getNextStage(int totalInteractions) {
    for (int i = 0; i < stages.length; i++) {
      if (totalInteractions < (stages[i]['minInteractions'] as int)) {
        return stages[i];
      }
    }
    return null;
  }

  static double getProgress(int totalInteractions) {
    final current = getStage(totalInteractions);
    final next = getNextStage(totalInteractions);
    if (next == null) return 1.0;
    final currentMin = current['minInteractions'] as int;
    final nextMin = next['minInteractions'] as int;
    return (totalInteractions - currentMin) / (nextMin - currentMin);
  }
}
