class ReminderModel {
  final int? id;
  final int userId;
  final String text;
  final String scheduledTime;
  final bool sentFlag;
  final bool readFlag;
  final String tone;
  final double engagementScore;

  ReminderModel({
    this.id,
    required this.userId,
    required this.text,
    required this.scheduledTime,
    this.sentFlag = false,
    this.readFlag = false,
    required this.tone,
    this.engagementScore = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'text': text,
      'scheduled_time': scheduledTime,
      'sent_flag': sentFlag ? 1 : 0,
      'read_flag': readFlag ? 1 : 0,
      'tone': tone,
      'engagement_score': engagementScore,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      text: map['text'] as String,
      scheduledTime: map['scheduled_time'] as String,
      sentFlag: (map['sent_flag'] as int?) == 1,
      readFlag: (map['read_flag'] as int?) == 1,
      tone: map['tone'] as String,
      engagementScore: (map['engagement_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Token cost for hidden reminder
  static const int tokenCost = 30;

  /// Default hidden reminders for the day
  static List<String> defaultReminderTexts(String nickname) {
    return [
      "Good morning, $nickname ❤️ Daddy loves you!",
      "Hey $nickname, don't forget your mission today 💪",
      "Just checking in, $nickname. You're doing great!",
      "Remember to take a break and drink water, champ 🥤",
      "Good night, $nickname. Daddy is proud of you ⭐",
    ];
  }
}
