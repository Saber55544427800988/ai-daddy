import 'dart:convert';
import 'dart:math';
import '../database/database_helper.dart';
import '../models/dad_report_model.dart';
import '../services/emotional_intelligence_service.dart';

/// Weekly Dad Report Service — generates comprehensive weekly reports
/// every Sunday with mood trends, engagement, growth scoring.
class DadReportService {
  static final DadReportService instance = DadReportService._();
  DadReportService._();

  /// Check if a new report should be generated (Sunday only, once per week)
  static Future<bool> shouldGenerateReport(int userId) async {
    final now = DateTime.now();
    if (now.weekday != DateTime.sunday) return false;

    final db = DatabaseHelper.instance;
    final latest = await db.getLatestDadReport(userId);
    if (latest == null) return true;

    final lastDate = DateTime.parse(latest.createdAt);
    return now.difference(lastDate).inDays >= 6;
  }

  /// Generate the weekly report
  static Future<DadReportModel> generateReport(
      int userId, String nickname) async {
    final db = DatabaseHelper.instance;
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));

    // Gather data
    final msgCount = await db.getMessageCount(userId, days: 7);
    final completedMissions =
        await db.getCompletedMissionCount(userId);
    final avgMood =
        await EmotionalIntelligenceService.getAverageMood(userId, days: 7);
    final moodTrend =
        await EmotionalIntelligenceService.getMoodTrend(userId);
    final avgEngagement = await db.getAverageEngagement(userId, days: 7);

    // Calculate growth score (0-100)
    double growthScore = 0;
    growthScore += (msgCount.clamp(0, 50) / 50) * 25; // chat activity
    growthScore += (avgMood / 5.0) * 25; // mood quality
    growthScore += (avgEngagement.clamp(0, 1)) * 25; // engagement
    growthScore += (completedMissions.clamp(0, 7) / 7) * 25; // missions

    // Generate daddy message
    final daddyMessage = _generateDaddyMessage(
        nickname, growthScore, moodTrend, msgCount, avgMood);

    // Highlights
    final highlights = <String>[];
    if (msgCount > 20) highlights.add('Active chatter — $msgCount messages!');
    if (avgMood >= 4.0) highlights.add('Great mood week! Avg: ${avgMood.toStringAsFixed(1)}');
    if (moodTrend == 'improving') highlights.add('Mood is improving! 📈');
    if (completedMissions > 3) highlights.add('Mission champion — $completedMissions done!');
    if (growthScore >= 80) highlights.add('Outstanding growth score! 🔥');
    if (highlights.isEmpty) highlights.add('Keep going! Every day counts. 💪');

    final report = DadReportModel(
      userId: userId,
      weekStart: weekStart.toIso8601String().substring(0, 10),
      weekEnd: now.toIso8601String().substring(0, 10),
      totalMessages: msgCount,
      missionsCompleted: completedMissions,
      missionsTotal: 7,
      avgMood: avgMood,
      moodTrend: moodTrend,
      tokensUsed: 0,
      engagementScore: avgEngagement,
      growthScore: growthScore,
      daddyMessage: daddyMessage,
      highlights: jsonEncode(highlights),
      createdAt: now.toIso8601String(),
    );

    await db.insertDadReport(report);
    return report;
  }

  static String _generateDaddyMessage(String nickname, double growth,
      String trend, int messages, double mood) {
    if (growth >= 80) {
      return "Incredible week, $nickname! 🔥 I'm so proud of you. "
          "You showed up, stayed active, and your growth is off the charts. "
          "Keep this energy going — you're building something amazing.";
    }
    if (growth >= 60) {
      return "Solid week, $nickname! ⭐ You've been putting in good effort. "
          "I can see the progress. A few more pushes and you'll be unstoppable. "
          "Daddy believes in you!";
    }
    if (growth >= 40) {
      return "Hey $nickname, not a bad week! 💪 You showed up, and that matters. "
          "Let's aim a little higher next week — I know you've got it in you. "
          "Remember, consistency beats perfection.";
    }
    if (trend == 'declining') {
      return "$nickname, I noticed things might be feeling tough lately. "
          "That's okay — we all have those weeks. 🌱 I'm here for you. "
          "Let's take it one day at a time. You don't have to be perfect.";
    }
    return "Week's done, $nickname! 🌿 Every small step counts. "
        "Even if it doesn't feel like much, showing up matters. "
        "Let's make next week even better together. 💙";
  }

  /// Generate surprise moment message (random positive reinforcement)
  static String? generateSurpriseMoment(
      String nickname, int totalInteractions) {
    final rand = Random();
    // 5% chance per message
    if (rand.nextDouble() > 0.05) return null;

    final surprises = [
      "Hey $nickname! 🎉 Random daddy moment — I'm proud of you. Just wanted you to know.",
      "Quick reminder, $nickname: You're stronger than you think. 💙 Keep going!",
      "$nickname, fun fact: We've chatted $totalInteractions times! That's commitment. 🏆",
      "Pause. Breathe. You're doing great, $nickname. Daddy sees you. 🫂",
      "Hey $nickname, remember that goal you mentioned? You're closer than you think. ⭐",
      "$nickname! 🌟 Surprise check — how's your energy right now? One word!",
      "I was just thinking... $nickname really is growing. Keep at it! 💪",
      "Random dad wisdom: \"The best time to start was yesterday. The second best is now.\" Go, $nickname! 🚀",
    ];

    return surprises[rand.nextInt(surprises.length)];
  }
}
