/// CareThread — Persistent tracking of active life situations.
///
/// Each detected situation (sick, travel, sad, study, etc.)
/// creates a CareThread that manages follow-up reminders,
/// escalation, and stop conditions independently.
class CareThread {
  final int? id;
  final int userId;
  final String type; // health, travel, emotion, stress, study, event, loneliness
  final String subType; // fever, exam_fail, sad, trip, etc.
  final String status; // active, resolved, expired
  final String intensity; // low, medium, high
  final int escalationLevel; // 0=normal, 1=firmer, 2=insistent
  final int followUpCount; // how many follow-ups sent
  final int ignoredCount; // how many ignored (no reply after reminder)
  final String startTime;
  final String? endTime;
  final String? lastFollowUp;
  final String? triggerMessage; // the original user message that created this

  CareThread({
    this.id,
    required this.userId,
    required this.type,
    this.subType = '',
    this.status = 'active',
    this.intensity = 'medium',
    this.escalationLevel = 0,
    this.followUpCount = 0,
    this.ignoredCount = 0,
    required this.startTime,
    this.endTime,
    this.lastFollowUp,
    this.triggerMessage,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'type': type,
        'sub_type': subType,
        'status': status,
        'intensity': intensity,
        'escalation_level': escalationLevel,
        'follow_up_count': followUpCount,
        'ignored_count': ignoredCount,
        'start_time': startTime,
        'end_time': endTime,
        'last_follow_up': lastFollowUp,
        'trigger_message': triggerMessage,
      };

  factory CareThread.fromMap(Map<String, dynamic> m) => CareThread(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        type: m['type'] as String,
        subType: (m['sub_type'] as String?) ?? '',
        status: (m['status'] as String?) ?? 'active',
        intensity: (m['intensity'] as String?) ?? 'medium',
        escalationLevel: (m['escalation_level'] as int?) ?? 0,
        followUpCount: (m['follow_up_count'] as int?) ?? 0,
        ignoredCount: (m['ignored_count'] as int?) ?? 0,
        startTime: m['start_time'] as String,
        endTime: m['end_time'] as String?,
        lastFollowUp: m['last_follow_up'] as String?,
        triggerMessage: m['trigger_message'] as String?,
      );

  CareThread copyWith({
    String? status,
    String? intensity,
    int? escalationLevel,
    int? followUpCount,
    int? ignoredCount,
    String? endTime,
    String? lastFollowUp,
  }) =>
      CareThread(
        id: id,
        userId: userId,
        type: type,
        subType: subType,
        status: status ?? this.status,
        intensity: intensity ?? this.intensity,
        escalationLevel: escalationLevel ?? this.escalationLevel,
        followUpCount: followUpCount ?? this.followUpCount,
        ignoredCount: ignoredCount ?? this.ignoredCount,
        startTime: startTime,
        endTime: endTime ?? this.endTime,
        lastFollowUp: lastFollowUp ?? this.lastFollowUp,
        triggerMessage: triggerMessage,
      );

  /// Thread priority for scheduling (higher = more important)
  int get priority {
    switch (type) {
      case 'health':
        return 100;
      case 'emotion':
        return 90;
      case 'event':
        return 80;
      case 'study':
        return 75;
      case 'stress':
        return 70;
      case 'travel':
        return 60;
      case 'loneliness':
        return 55;
      default:
        return 50;
    }
  }

  /// Max expected duration in hours before auto-expire
  int get maxDurationHours {
    switch (type) {
      case 'health':
        return 72; // 3 days
      case 'travel':
        return 336; // 14 days
      case 'emotion':
        return 48; // 2 days
      case 'stress':
        return 24; // 1 day
      case 'study':
        return 72; // 3 days
      case 'event':
        return 24; // 1 day after event
      case 'loneliness':
        return 48; // 2 days
      default:
        return 48;
    }
  }

  /// Check if this thread should auto-expire
  bool get isExpired {
    final start = DateTime.tryParse(startTime);
    if (start == null) return false;
    return DateTime.now().difference(start).inHours > maxDurationHours;
  }
}
