class SmartReminderModel {
  final int? id;
  final int userId;
  final String text;
  final String scheduledTime;
  final bool sentFlag;
  final bool voicePlayedFlag;
  final String eventType; // meeting, homework, call, custom

  SmartReminderModel({
    this.id,
    required this.userId,
    required this.text,
    required this.scheduledTime,
    this.sentFlag = false,
    this.voicePlayedFlag = false,
    required this.eventType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'text': text,
      'scheduled_time': scheduledTime,
      'sent_flag': sentFlag ? 1 : 0,
      'voice_played_flag': voicePlayedFlag ? 1 : 0,
      'event_type': eventType,
    };
  }

  factory SmartReminderModel.fromMap(Map<String, dynamic> map) {
    return SmartReminderModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      text: map['text'] as String,
      scheduledTime: map['scheduled_time'] as String,
      sentFlag: (map['sent_flag'] as int?) == 1,
      voicePlayedFlag: (map['voice_played_flag'] as int?) == 1,
      eventType: map['event_type'] as String,
    );
  }

  /// Token cost for smart auto-reminder
  static const int tokenCost = 50;
}
