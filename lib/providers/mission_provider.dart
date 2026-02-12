import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/mission_model.dart';

class MissionProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<MissionModel> _missions = [];
  List<MissionLogModel> _todayLogs = [];
  int _totalXP = 0;
  int _level = 1;
  final int _completedStreak = 0;

  List<MissionModel> get missions => _missions;
  List<MissionLogModel> get todayLogs => _todayLogs;
  int get totalXP => _totalXP;
  int get level => _level;
  int get completedStreak => _completedStreak;
  int get xpToNextLevel => level * 200;
  double get levelProgress => (_totalXP % xpToNextLevel) / xpToNextLevel;

  Future<void> init(int userId) async {
    _missions = await _db.getMissions();
    _todayLogs = await _db.getTodayMissionLogs(userId);

    // Calculate total XP from all completed missions
    final completedCount = await _db.getCompletedMissionCount(userId);
    _totalXP = completedCount * 50;
    _level = (_totalXP ~/ 200) + 1;

    // Initialize today's missions if not exists
    if (_todayLogs.isEmpty) {
      await _initTodayMissions(userId);
    }

    notifyListeners();
  }

  Future<void> _initTodayMissions(int userId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    for (final mission in _missions) {
      if (mission.id != null) {
        final log = MissionLogModel(
          userId: userId,
          missionId: mission.id!,
          status: MissionStatus.active,
          date: today,
        );
        await _db.insertMissionLog(log);
      }
    }
    _todayLogs = await _db.getTodayMissionLogs(userId);
  }

  Future<void> completeMission(int userId, int missionId) async {
    // Find log
    final logIndex =
        _todayLogs.indexWhere((l) => l.missionId == missionId);
    if (logIndex == -1) return;

    final log = _todayLogs[logIndex];
    if (log.status == MissionStatus.completed) return;

    // Update log
    final updatedLog = MissionLogModel(
      id: log.id,
      userId: userId,
      missionId: missionId,
      status: MissionStatus.completed,
      date: log.date,
    );
    await _db.updateMissionLog(updatedLog);

    // Find mission for XP/token reward
    final mission = _missions.firstWhere(
      (m) => m.id == missionId,
      orElse: () => MissionModel(
          title: '', description: '', category: '', xpReward: 50, tokenReward: 50),
    );

    // Award XP
    _totalXP += mission.xpReward;
    _level = (_totalXP ~/ 200) + 1;

    // Award tokens
    await _db.earnTokens(userId, mission.tokenReward);

    // Refresh logs
    _todayLogs = await _db.getTodayMissionLogs(userId);
    notifyListeners();
  }

  MissionStatus getMissionStatus(int missionId) {
    final log = _todayLogs.where((l) => l.missionId == missionId).firstOrNull;
    return log?.status ?? MissionStatus.active;
  }

  String get levelTitle {
    if (_level >= 50) return 'Unbreakable 🔱';
    if (_level >= 40) return 'Iron Will 🛡️';
    if (_level >= 30) return 'Soul Warrior ⚔️';
    if (_level >= 25) return 'Legend 🏆';
    if (_level >= 20) return 'Master 🎖️';
    if (_level >= 15) return 'Hero 🦸';
    if (_level >= 12) return 'Guardian 🛡️';
    if (_level >= 10) return 'Star ⭐';
    if (_level >= 7) return 'Champion 💎';
    if (_level >= 4) return 'Rising 🌟';
    return 'Rookie 🐣';
  }

  /// Identity growth stage name
  String get identityStage {
    if (_level >= 50) return 'Unbreakable';
    if (_level >= 40) return 'Iron Will';
    if (_level >= 30) return 'Soul Warrior';
    if (_level >= 25) return 'Elite Legend';
    if (_level >= 20) return 'Master';
    if (_level >= 15) return 'Hero';
    if (_level >= 10) return 'Rising Star';
    if (_level >= 5) return 'Committed';
    return 'Beginner';
  }

  List<String> get earnedBadges {
    final badges = <String>[];
    if (_totalXP >= 100) badges.add('First Steps 🐣');
    if (_totalXP >= 500) badges.add('Rising Star ⭐');
    if (_totalXP >= 1000) badges.add('Water Warrior 💧');
    if (_totalXP >= 2000) badges.add('Study Champion 📚');
    if (_totalXP >= 3000) badges.add('Consistency King 👑');
    if (_totalXP >= 5000) badges.add('Fitness Hero 💪');
    if (_totalXP >= 7500) badges.add('Mind Master 🧠');
    if (_totalXP >= 10000) badges.add('Legend Status 🏆');
    if (_totalXP >= 15000) badges.add('Iron Will 🛡️');
    if (_totalXP >= 25000) badges.add('Unbreakable 🔱');
    return badges;
  }
}
