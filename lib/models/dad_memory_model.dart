/// Dad Memory Vault — stores long-term memories about the user.
/// Goals, fears, hobbies, important dates, achievements, failures.
class DadMemoryModel {
  final int? id;
  final int userId;
  final String category; // goal, fear, hobby, date, achievement, failure, preference
  final String content;
  final String context; // when/why this was learned
  final String createdAt;
  final String lastMentioned; // last time AI referenced this
  final int mentionCount;
  final double importance; // 0.0 - 1.0

  DadMemoryModel({
    this.id,
    required this.userId,
    required this.category,
    required this.content,
    this.context = '',
    required this.createdAt,
    this.lastMentioned = '',
    this.mentionCount = 0,
    this.importance = 0.5,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'category': category,
        'content': content,
        'context': context,
        'created_at': createdAt,
        'last_mentioned': lastMentioned,
        'mention_count': mentionCount,
        'importance': importance,
      };

  factory DadMemoryModel.fromMap(Map<String, dynamic> m) => DadMemoryModel(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        category: m['category'] as String,
        content: m['content'] as String,
        context: m['context'] as String? ?? '',
        createdAt: m['created_at'] as String,
        lastMentioned: m['last_mentioned'] as String? ?? '',
        mentionCount: m['mention_count'] as int? ?? 0,
        importance: (m['importance'] as num?)?.toDouble() ?? 0.5,
      );

  DadMemoryModel copyWith({
    int? id,
    int? userId,
    String? category,
    String? content,
    String? context,
    String? createdAt,
    String? lastMentioned,
    int? mentionCount,
    double? importance,
  }) =>
      DadMemoryModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        category: category ?? this.category,
        content: content ?? this.content,
        context: context ?? this.context,
        createdAt: createdAt ?? this.createdAt,
        lastMentioned: lastMentioned ?? this.lastMentioned,
        mentionCount: mentionCount ?? this.mentionCount,
        importance: importance ?? this.importance,
      );

  /// Serialize for AI prompt context
  String toPromptLine() => '[$category] $content';

  /// Category icon
  String get emoji {
    switch (category) {
      case 'goal':
        return '🎯';
      case 'fear':
        return '😰';
      case 'hobby':
        return '🎨';
      case 'date':
        return '📅';
      case 'achievement':
        return '🏆';
      case 'failure':
        return '📉';
      case 'preference':
        return '💡';
      default:
        return '📝';
    }
  }
}

/// Serializable summary for AI context
String memoriesToPrompt(List<DadMemoryModel> memories) {
  if (memories.isEmpty) return '';
  final lines = memories.map((m) => m.toPromptLine()).join('\n');
  return 'THINGS YOU REMEMBER ABOUT THE USER:\n$lines';
}
