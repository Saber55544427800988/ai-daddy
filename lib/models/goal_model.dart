/// Long-term goal tracking with milestones.
class GoalModel {
  final int? id;
  final int userId;
  final String title;
  final String description;
  final String category; // fitness, business, education, personal, creative
  final String milestones; // JSON array of {title, done}
  final double progress; // 0.0 - 1.0
  final String status; // active, completed, paused, abandoned
  final String createdAt;
  final String updatedAt;
  final String targetDate; // optional deadline

  GoalModel({
    this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.category = 'personal',
    this.milestones = '[]',
    this.progress = 0.0,
    this.status = 'active',
    required this.createdAt,
    this.updatedAt = '',
    this.targetDate = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'category': category,
        'milestones': milestones,
        'progress': progress,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'target_date': targetDate,
      };

  factory GoalModel.fromMap(Map<String, dynamic> m) => GoalModel(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        title: m['title'] as String,
        description: m['description'] as String? ?? '',
        category: m['category'] as String? ?? 'personal',
        milestones: m['milestones'] as String? ?? '[]',
        progress: (m['progress'] as num?)?.toDouble() ?? 0.0,
        status: m['status'] as String? ?? 'active',
        createdAt: m['created_at'] as String,
        updatedAt: m['updated_at'] as String? ?? '',
        targetDate: m['target_date'] as String? ?? '',
      );

  GoalModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    String? category,
    String? milestones,
    double? progress,
    String? status,
    String? createdAt,
    String? updatedAt,
    String? targetDate,
  }) =>
      GoalModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        milestones: milestones ?? this.milestones,
        progress: progress ?? this.progress,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        targetDate: targetDate ?? this.targetDate,
      );

  String get categoryEmoji {
    switch (category) {
      case 'fitness':
        return '💪';
      case 'business':
        return '💼';
      case 'education':
        return '📚';
      case 'personal':
        return '🌟';
      case 'creative':
        return '🎨';
      default:
        return '🎯';
    }
  }
}
