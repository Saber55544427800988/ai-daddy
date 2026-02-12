enum SenderType { user, ai }

class MessageModel {
  final int? id;
  final int userId;
  final String text;
  final SenderType senderType;
  final String timestamp;
  final double engagementScore;

  MessageModel({
    this.id,
    required this.userId,
    required this.text,
    required this.senderType,
    required this.timestamp,
    this.engagementScore = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'text': text,
      'sender_type': senderType == SenderType.user ? 'user' : 'ai',
      'timestamp': timestamp,
      'engagement_score': engagementScore,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      text: map['text'] as String,
      senderType:
          map['sender_type'] == 'user' ? SenderType.user : SenderType.ai,
      timestamp: map['timestamp'] as String,
      engagementScore: (map['engagement_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Token cost estimate based on message length
  int get tokenCost {
    if (text.length < 50) return 15;
    if (text.length < 150) return 50;
    return 100;
  }
}
