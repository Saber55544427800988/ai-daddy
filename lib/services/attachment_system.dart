import '../database/database_helper.dart';

/// Attachment Level System — tracks bonding between user and AI Daddy.
///
/// Score: 0–100
/// Increases when user shares vulnerability, responds consistently, opens app daily.
/// Decreases during long inactivity or shallow conversations.
/// Attachment affects tone warmth and familiarity.
class AttachmentSystem {
  static final AttachmentSystem instance = AttachmentSystem._();
  AttachmentSystem._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // Cached scores
  final Map<int, int> _scores = {};

  /// Get attachment score for user
  Future<int> getScore(int userId) async {
    if (_scores.containsKey(userId)) return _scores[userId]!;

    final db = await _db.database;
    final rows = await db.query('user_emotional_profile',
        columns: ['attachment_score'],
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1);
    final score = rows.isNotEmpty
        ? (rows.first['attachment_score'] as int?) ?? 20
        : 20;
    _scores[userId] = score;
    return score;
  }

  /// Increase attachment (capped at 100)
  Future<void> increase(int userId, int amount) async {
    final current = await getScore(userId);
    final newScore = (current + amount).clamp(0, 100);
    _scores[userId] = newScore;
    await _persist(userId, newScore);
  }

  /// Decrease attachment (min 0)
  Future<void> decrease(int userId, int amount) async {
    final current = await getScore(userId);
    final newScore = (current - amount).clamp(0, 100);
    _scores[userId] = newScore;
    await _persist(userId, newScore);
  }

  /// Process signals from a message to adjust attachment
  Future<void> processMessage(int userId, String message) async {
    final lower = message.toLowerCase();

    // Vulnerability sharing = +3
    final vulnerableWords = [
      'afraid', 'scared', 'lonely', 'miss', 'cry',
      'ashamed', 'sorry', 'love you', 'need you',
      'thank you daddy', 'thanks dad', 'i trust you',
    ];
    if (vulnerableWords.any((w) => lower.contains(w))) {
      await increase(userId, 3);
      return;
    }

    // Longer emotional message = +1
    if (message.length > 80) {
      await increase(userId, 1);
    }
  }

  /// Daily app open bonus
  Future<void> recordAppOpen(int userId) async {
    await increase(userId, 1);
  }

  /// Record inactivity (called when user hasn't been active)
  Future<void> recordInactivity(int userId, int daysSinceLastActive) async {
    if (daysSinceLastActive >= 7) {
      await decrease(userId, 5);
    } else if (daysSinceLastActive >= 3) {
      await decrease(userId, 2);
    }
  }

  /// Get attachment label
  Future<String> getLabel(int userId) async {
    final score = await getScore(userId);
    if (score >= 80) return 'deeply_bonded';
    if (score >= 60) return 'close';
    if (score >= 40) return 'comfortable';
    if (score >= 20) return 'warming_up';
    return 'new';
  }

  /// Build attachment context for AI prompt
  Future<String> buildAttachmentContext(int userId) async {
    final score = await getScore(userId);

    if (score >= 80) {
      return 'ATTACHMENT: Deep bond ($score/100). You know this kid well. '
          'Be personal, use inside references. "You\'ve been quiet. I don\'t like that."';
    } else if (score >= 60) {
      return 'ATTACHMENT: Close ($score/100). Warm and familiar. '
          'Reference past conversations naturally.';
    } else if (score >= 40) {
      return 'ATTACHMENT: Comfortable ($score/100). Getting to know each other. '
          'Be warm but not overly familiar.';
    } else if (score >= 20) {
      return 'ATTACHMENT: Warming up ($score/100). Building trust. '
          'Be encouraging, patient.';
    } else {
      return 'ATTACHMENT: New ($score/100). First impressions matter. '
          'Be welcoming, gentle, not pushy. "Busy?" style.';
    }
  }

  Future<void> _persist(int userId, int score) async {
    final db = await _db.database;
    await db.update(
      'user_emotional_profile',
      {'attachment_score': score},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
