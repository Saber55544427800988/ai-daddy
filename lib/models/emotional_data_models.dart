/// Memory Weight — every stored memory has emotional weight,
/// recency, and frequency scores to determine when to recall it.
class MemoryWeight {
  final int? id;
  final int userId;
  final int memoryId; // FK to dad_memories
  final String memoryType; // goal, fear, hobby, date, achievement, failure
  final int emotionalWeight; // 1–10 (how impactful)
  final double recencyScore; // 0.0–1.0 (decays over time)
  final double frequencyScore; // 0.0–1.0 (how often mentioned)
  final String lastCalculated;

  MemoryWeight({
    this.id,
    required this.userId,
    required this.memoryId,
    required this.memoryType,
    this.emotionalWeight = 5,
    this.recencyScore = 1.0,
    this.frequencyScore = 0.0,
    required this.lastCalculated,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'memory_id': memoryId,
        'memory_type': memoryType,
        'emotional_weight': emotionalWeight,
        'recency_score': recencyScore,
        'frequency_score': frequencyScore,
        'last_calculated': lastCalculated,
      };

  factory MemoryWeight.fromMap(Map<String, dynamic> m) => MemoryWeight(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        memoryId: m['memory_id'] as int,
        memoryType: (m['memory_type'] as String?) ?? 'preference',
        emotionalWeight: (m['emotional_weight'] as int?) ?? 5,
        recencyScore: (m['recency_score'] as num?)?.toDouble() ?? 1.0,
        frequencyScore: (m['frequency_score'] as num?)?.toDouble() ?? 0.0,
        lastCalculated: m['last_calculated'] as String,
      );

  /// Combined relevance score for memory retrieval priority
  double get relevanceScore =>
      (emotionalWeight / 10.0) * 0.5 +
      recencyScore * 0.3 +
      frequencyScore * 0.2;
}

/// Behavior Stats — tracks user preferences for adaptation.
class BehaviorStats {
  final int? id;
  final int userId;
  final double preferredMsgLength; // avg chars user prefers in response
  final double preferredStrictness; // 0.0=soft, 1.0=strict
  final String preferredReminderTiming; // morning, afternoon, evening, adaptive
  final double emotionalSensitivity; // 0.0–1.0 how emotionally responsive
  final double reminderResponseRate; // 0.0–1.0 how often user responds to reminders
  final double conversationDepth; // 0.0–1.0 avg depth of conversations
  final int inactivityDays; // days since last interaction
  final String lastAdaptation; // ISO timestamp of last weekly adaptation
  final String weeklyTrends; // JSON snapshot of weekly behavior

  BehaviorStats({
    this.id,
    required this.userId,
    this.preferredMsgLength = 60.0,
    this.preferredStrictness = 0.4,
    this.preferredReminderTiming = 'adaptive',
    this.emotionalSensitivity = 0.5,
    this.reminderResponseRate = 0.5,
    this.conversationDepth = 0.3,
    this.inactivityDays = 0,
    this.lastAdaptation = '',
    this.weeklyTrends = '{}',
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'preferred_msg_length': preferredMsgLength,
        'preferred_strictness': preferredStrictness,
        'preferred_reminder_timing': preferredReminderTiming,
        'emotional_sensitivity': emotionalSensitivity,
        'reminder_response_rate': reminderResponseRate,
        'conversation_depth': conversationDepth,
        'inactivity_days': inactivityDays,
        'last_adaptation': lastAdaptation,
        'weekly_trends': weeklyTrends,
      };

  factory BehaviorStats.fromMap(Map<String, dynamic> m) => BehaviorStats(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        preferredMsgLength: (m['preferred_msg_length'] as num?)?.toDouble() ?? 60.0,
        preferredStrictness: (m['preferred_strictness'] as num?)?.toDouble() ?? 0.4,
        preferredReminderTiming: (m['preferred_reminder_timing'] as String?) ?? 'adaptive',
        emotionalSensitivity: (m['emotional_sensitivity'] as num?)?.toDouble() ?? 0.5,
        reminderResponseRate: (m['reminder_response_rate'] as num?)?.toDouble() ?? 0.5,
        conversationDepth: (m['conversation_depth'] as num?)?.toDouble() ?? 0.3,
        inactivityDays: (m['inactivity_days'] as int?) ?? 0,
        lastAdaptation: (m['last_adaptation'] as String?) ?? '',
        weeklyTrends: (m['weekly_trends'] as String?) ?? '{}',
      );

  BehaviorStats copyWith({
    double? preferredMsgLength,
    double? preferredStrictness,
    String? preferredReminderTiming,
    double? emotionalSensitivity,
    double? reminderResponseRate,
    double? conversationDepth,
    int? inactivityDays,
    String? lastAdaptation,
    String? weeklyTrends,
  }) =>
      BehaviorStats(
        id: id,
        userId: userId,
        preferredMsgLength: preferredMsgLength ?? this.preferredMsgLength,
        preferredStrictness: preferredStrictness ?? this.preferredStrictness,
        preferredReminderTiming:
            preferredReminderTiming ?? this.preferredReminderTiming,
        emotionalSensitivity:
            emotionalSensitivity ?? this.emotionalSensitivity,
        reminderResponseRate:
            reminderResponseRate ?? this.reminderResponseRate,
        conversationDepth: conversationDepth ?? this.conversationDepth,
        inactivityDays: inactivityDays ?? this.inactivityDays,
        lastAdaptation: lastAdaptation ?? this.lastAdaptation,
        weeklyTrends: weeklyTrends ?? this.weeklyTrends,
      );
}
