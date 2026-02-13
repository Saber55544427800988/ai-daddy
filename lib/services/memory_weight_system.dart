import '../database/database_helper.dart';

/// Memory Weight System — assigns emotional weight, recency,
/// and frequency scores to every stored memory.
///
/// High-weight memories are referenced by AI Daddy naturally.
/// "You felt like this last month too."
class MemoryWeightSystem {
  static final MemoryWeightSystem instance = MemoryWeightSystem._();
  MemoryWeightSystem._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Calculate weights for all memories of a user.
  /// Call periodically (e.g., every 10 messages).
  Future<void> recalculateWeights(int userId) async {
    final db = await _db.database;
    final memories = await _db.getDadMemories(userId);
    final now = DateTime.now();

    for (final mem in memories) {
      // Recency: decays over time (1.0 = today, 0.0 = 90+ days ago)
      final created = DateTime.tryParse(mem.createdAt) ?? now;
      final daysSince = now.difference(created).inDays;
      final recency = (1.0 - (daysSince / 90.0)).clamp(0.0, 1.0);

      // Frequency: based on mention count (normalized to 0-1)
      final frequency = (mem.mentionCount / 10.0).clamp(0.0, 1.0);

      // Emotional weight: based on category + importance
      int emotionalWeight = _categoryWeight(mem.category);
      emotionalWeight =
          (emotionalWeight * mem.importance).round().clamp(1, 10);

      // Check if weight record exists
      final existing = await db.query('memory_weights',
          where: 'memory_id = ?', whereArgs: [mem.id], limit: 1);

      final data = {
        'user_id': userId,
        'memory_id': mem.id,
        'memory_type': mem.category,
        'emotional_weight': emotionalWeight,
        'recency_score': recency,
        'frequency_score': frequency,
        'last_calculated': now.toIso8601String(),
      };

      if (existing.isNotEmpty) {
        await db.update('memory_weights', data,
            where: 'id = ?', whereArgs: [existing.first['id']]);
      } else {
        await db.insert('memory_weights', data);
      }
    }
  }

  /// Get top N most relevant memories for AI prompt context
  Future<List<Map<String, dynamic>>> getTopMemories(int userId,
      {int limit = 5}) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT mw.*, dm.content, dm.category, dm.context
      FROM memory_weights mw
      JOIN dad_memories dm ON dm.id = mw.memory_id
      WHERE mw.user_id = ?
      ORDER BY (mw.emotional_weight * 0.5 + mw.recency_score * 10 * 0.3 + mw.frequency_score * 10 * 0.2) DESC
      LIMIT ?
    ''', [userId, limit]);
    return rows;
  }

  /// Build memory weight context for AI prompt
  Future<String> buildWeightedMemoryContext(int userId) async {
    final memories = await getTopMemories(userId, limit: 5);
    if (memories.isEmpty) return '';

    final buf = StringBuffer('\n=== WEIGHTED MEMORIES (reference naturally) ===\n');
    for (final m in memories) {
      final category = m['category'] as String? ?? 'memory';
      final content = m['content'] as String? ?? '';
      final weight = m['emotional_weight'] as int? ?? 5;
      if (weight >= 7) {
        buf.writeln('⭐ [$category] $content (important)');
      } else {
        buf.writeln('[$category] $content');
      }
    }
    return buf.toString();
  }

  int _categoryWeight(String category) {
    switch (category) {
      case 'fear':
      case 'failure':
        return 9;
      case 'achievement':
      case 'goal':
        return 8;
      case 'date':
        return 7; // birthdays, anniversaries
      case 'hobby':
        return 5;
      case 'preference':
        return 4;
      default:
        return 5;
    }
  }
}
