/// Habit tracking model — tracks repeated behaviors and builds habit scores.
class HabitModel {
  final int? id;
  final int userId;
  final String name;
  final String category; // health, study, exercise, social, custom
  final int totalDays; // total days tracked
  final int completedDays; // days completed
  final int currentStreak;
  final int bestStreak;
  final String lastCompleted; // ISO-8601
  final String createdAt;

  HabitModel({
    this.id,
    required this.userId,
    required this.name,
    this.category = 'custom',
    this.totalDays = 0,
    this.completedDays = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCompleted = '',
    required this.createdAt,
  });

  double get completionRate =>
      totalDays > 0 ? completedDays / totalDays : 0.0;

  /// Habit strength classification
  String get strength {
    final rate = completionRate;
    if (rate >= 0.85) return 'strong';
    if (rate >= 0.5) return 'building';
    if (rate >= 0.25) return 'weak';
    return 'at-risk';
  }

  String get strengthEmoji {
    switch (strength) {
      case 'strong':
        return '💪';
      case 'building':
        return '🔨';
      case 'weak':
        return '⚠️';
      case 'at-risk':
        return '🔴';
      default:
        return '❓';
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'category': category,
        'total_days': totalDays,
        'completed_days': completedDays,
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'last_completed': lastCompleted,
        'created_at': createdAt,
      };

  factory HabitModel.fromMap(Map<String, dynamic> m) => HabitModel(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        name: m['name'] as String,
        category: m['category'] as String? ?? 'custom',
        totalDays: m['total_days'] as int? ?? 0,
        completedDays: m['completed_days'] as int? ?? 0,
        currentStreak: m['current_streak'] as int? ?? 0,
        bestStreak: m['best_streak'] as int? ?? 0,
        lastCompleted: m['last_completed'] as String? ?? '',
        createdAt: m['created_at'] as String,
      );

  HabitModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? category,
    int? totalDays,
    int? completedDays,
    int? currentStreak,
    int? bestStreak,
    String? lastCompleted,
    String? createdAt,
  }) =>
      HabitModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        category: category ?? this.category,
        totalDays: totalDays ?? this.totalDays,
        completedDays: completedDays ?? this.completedDays,
        currentStreak: currentStreak ?? this.currentStreak,
        bestStreak: bestStreak ?? this.bestStreak,
        lastCompleted: lastCompleted ?? this.lastCompleted,
        createdAt: createdAt ?? this.createdAt,
      );
}
