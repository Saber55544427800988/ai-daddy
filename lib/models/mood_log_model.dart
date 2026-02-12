class MoodLogModel {
  final int? id;
  final int userId;
  final int moodScore; // 1-5 scale
  final String timestamp;

  MoodLogModel({
    this.id,
    required this.userId,
    required this.moodScore,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'mood_score': moodScore,
      'timestamp': timestamp,
    };
  }

  factory MoodLogModel.fromMap(Map<String, dynamic> map) {
    return MoodLogModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      moodScore: map['mood_score'] as int,
      timestamp: map['timestamp'] as String,
    );
  }

  String get moodEmoji {
    switch (moodScore) {
      case 1:
        return '😢';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }
}
