enum MissionStatus { active, completed, ignored }

class MissionModel {
  final int? id;
  final String title;
  final String description;
  final String category; // water, study, exercise, custom
  final int xpReward;
  final int tokenReward;

  MissionModel({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    this.xpReward = 50,
    this.tokenReward = 50,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'xp_reward': xpReward,
      'token_reward': tokenReward,
    };
  }

  factory MissionModel.fromMap(Map<String, dynamic> map) {
    return MissionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      xpReward: map['xp_reward'] as int? ?? 50,
      tokenReward: map['token_reward'] as int? ?? 50,
    );
  }

  static List<MissionModel> dailyDefaults() {
    return [
      MissionModel(
        title: 'Drink Water',
        description: 'Drink at least 8 glasses of water today',
        category: 'water',
        xpReward: 30,
        tokenReward: 50,
      ),
      MissionModel(
        title: 'Study Time',
        description: 'Study or learn something new for 30 minutes',
        category: 'study',
        xpReward: 50,
        tokenReward: 50,
      ),
      MissionModel(
        title: 'Exercise',
        description: 'Do at least 15 minutes of exercise',
        category: 'exercise',
        xpReward: 50,
        tokenReward: 50,
      ),
      MissionModel(
        title: 'Complete a Task',
        description: 'Finish one important task from your to-do list',
        category: 'custom',
        xpReward: 40,
        tokenReward: 50,
      ),
      MissionModel(
        title: 'Chat with Daddy',
        description: 'Have a meaningful conversation with AI Daddy',
        category: 'custom',
        xpReward: 20,
        tokenReward: 30,
      ),
    ];
  }
}

class MissionLogModel {
  final int? id;
  final int userId;
  final int missionId;
  final MissionStatus status;
  final String date;

  MissionLogModel({
    this.id,
    required this.userId,
    required this.missionId,
    required this.status,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'mission_id': missionId,
      'status': status.name,
      'date': date,
    };
  }

  factory MissionLogModel.fromMap(Map<String, dynamic> map) {
    return MissionLogModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      missionId: map['mission_id'] as int,
      status: MissionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MissionStatus.active,
      ),
      date: map['date'] as String,
    );
  }
}
