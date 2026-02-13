import 'dart:convert';
import '../database/database_helper.dart';
import '../models/emotional_data_models.dart';

/// Behavior Adaptation Engine — learns user preferences automatically.
///
/// Tracks preferred message length, strictness, reminder timing,
/// emotional sensitivity, and adapts weekly.
///
/// No AI tokens used — pure local computation.
class BehaviorAdaptationEngine {
  static final BehaviorAdaptationEngine instance =
      BehaviorAdaptationEngine._();
  BehaviorAdaptationEngine._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // Cached stats
  final Map<int, BehaviorStats> _stats = {};

  /// Get or create behavior stats for a user
  Future<BehaviorStats> getStats(int userId) async {
    if (_stats.containsKey(userId)) return _stats[userId]!;

    final db = await _db.database;
    final rows = await db.query('behavior_stats',
        where: 'user_id = ?', whereArgs: [userId], limit: 1);
    if (rows.isNotEmpty) {
      _stats[userId] = BehaviorStats.fromMap(rows.first);
    } else {
      final stats = BehaviorStats(userId: userId);
      final id = await db.insert('behavior_stats', stats.toMap());
      _stats[userId] = BehaviorStats(id: id, userId: userId);
    }
    return _stats[userId]!;
  }

  /// Quick per-message update — record message depth
  Future<void> recordMessage(int userId, String message, double sentiment) async {
    var stats = await getStats(userId);

    // Track conversation depth (longer + emotional = deeper)
    double depth = stats.conversationDepth;
    if (message.length > 100 && sentiment.abs() > 0.3) {
      depth = (depth + 0.02).clamp(0.0, 1.0);
    } else if (message.length < 20) {
      depth = (depth - 0.01).clamp(0.0, 1.0);
    }

    // Track emotional sensitivity from response patterns
    double sensitivity = stats.emotionalSensitivity;
    if (sentiment < -0.5) {
      sensitivity = (sensitivity + 0.03).clamp(0.0, 1.0);
    }

    // Reset inactivity
    stats = stats.copyWith(
      conversationDepth: depth,
      emotionalSensitivity: sensitivity,
      inactivityDays: 0,
    );

    _stats[userId] = stats;
    await _saveStats(stats);
  }

  /// Weekly deep adaptation — call every 7 days or every 50 messages
  Future<void> weeklyAdapt(int userId) async {
    var stats = await getStats(userId);
    final now = DateTime.now();

    // Check if already adapted this week
    if (stats.lastAdaptation.isNotEmpty) {
      final lastAdapt = DateTime.tryParse(stats.lastAdaptation);
      if (lastAdapt != null && now.difference(lastAdapt).inDays < 7) {
        return; // Too soon
      }
    }

    // ── 1. Preferred message length ──
    final avgLen = await _db.getAvgUserMessageLength(userId, days: 7);
    // If user writes short → they prefer short replies
    double prefLen = 60.0;
    if (avgLen < 30) {
      prefLen = 40.0; // very short replies
    } else if (avgLen < 60) {
      prefLen = 60.0; // short
    } else if (avgLen < 120) {
      prefLen = 100.0; // medium
    } else {
      prefLen = 140.0; // slightly longer OK
    }

    // ── 2. Preferred strictness ──
    // If user responds positively to strict tone → increase
    final tonePositivity = await _db.getToneReplyPositivity(userId, days: 7);
    double strictness = stats.preferredStrictness;
    final strictRate = tonePositivity['strict'] ?? 0.5;
    final caringRate = tonePositivity['caring'] ?? 0.5;
    if (strictRate > 0.6) {
      strictness = (strictness + 0.05).clamp(0.0, 1.0);
    } else if (caringRate > strictRate + 0.2) {
      strictness = (strictness - 0.05).clamp(0.0, 1.0);
    }

    // ── 3. Preferred reminder timing ──
    final hourEngagement = await _db.getEngagementByHour(userId, days: 7);
    String bestTiming = 'adaptive';
    if (hourEngagement.isNotEmpty) {
      final sortedHours = hourEngagement.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final bestHour = sortedHours.first.key;
      if (bestHour >= 6 && bestHour < 12) {
        bestTiming = 'morning';
      } else if (bestHour >= 12 && bestHour < 18) {
        bestTiming = 'afternoon';
      } else {
        bestTiming = 'evening';
      }
    }

    // ── 4. Reminder response rate ──
    // Approximated from reply rate on interaction logs
    final db = await _db.database;
    final replyRateResult = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN user_replied = 1 THEN 1 ELSE 0 END) as replied,
        COUNT(*) as total
      FROM interaction_log WHERE user_id = ? AND timestamp >= ?
    ''', [userId, now.subtract(const Duration(days: 7)).toIso8601String()]);
    final replied = (replyRateResult.first['replied'] as num?)?.toDouble() ?? 0;
    final total = (replyRateResult.first['total'] as num?)?.toDouble() ?? 1;
    final replyRate = total > 0 ? replied / total : 0.5;

    // ── 5. Inactivity check ──
    final activeDays = await _db.getActiveDays(userId, days: 7);
    final inactDays = 7 - activeDays.length;

    // ── Build weekly trends snapshot ──
    final trends = {
      'avg_msg_len': avgLen,
      'reply_rate': replyRate,
      'strictness': strictness,
      'active_days': activeDays.length,
      'best_timing': bestTiming,
      'week': now.toIso8601String().substring(0, 10),
    };

    stats = stats.copyWith(
      preferredMsgLength: prefLen,
      preferredStrictness: strictness,
      preferredReminderTiming: bestTiming,
      reminderResponseRate: replyRate,
      inactivityDays: inactDays,
      lastAdaptation: now.toIso8601String(),
      weeklyTrends: jsonEncode(trends),
    );

    _stats[userId] = stats;
    await _saveStats(stats);
  }

  /// Build behavior context for AI prompt
  Future<String> buildBehaviorContext(int userId) async {
    final stats = await getStats(userId);
    final buf = StringBuffer();
    buf.writeln('=== BEHAVIOR PREFERENCES ===');

    // Message length guidance
    if (stats.preferredMsgLength <= 50) {
      buf.writeln('User prefers VERY SHORT replies. 1 sentence max.');
    } else if (stats.preferredMsgLength <= 80) {
      buf.writeln('User prefers SHORT replies. 1-2 sentences.');
    } else {
      buf.writeln('User can handle MEDIUM replies. 2-3 sentences OK.');
    }

    // Strictness
    if (stats.preferredStrictness > 0.6) {
      buf.writeln('User responds well to DIRECT, firm tone.');
    } else if (stats.preferredStrictness < 0.3) {
      buf.writeln('User prefers GENTLE, soft approach.');
    }

    // Emotional sensitivity
    if (stats.emotionalSensitivity > 0.6) {
      buf.writeln('User is emotionally sensitive. Be extra careful with words.');
    }

    // Conversation depth
    if (stats.conversationDepth > 0.6) {
      buf.writeln('User engages deeply. It\'s OK to be more personal.');
    }

    return buf.toString();
  }

  Future<void> _saveStats(BehaviorStats stats) async {
    final db = await _db.database;
    if (stats.id != null) {
      await db.update('behavior_stats', stats.toMap(),
          where: 'id = ?', whereArgs: [stats.id]);
    } else {
      await db.insert('behavior_stats', stats.toMap());
    }
  }
}
