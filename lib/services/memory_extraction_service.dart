import '../database/database_helper.dart';
import '../models/dad_memory_model.dart';

/// Memory Extraction Service — extracts important memories from conversations
/// and stores them in the Dad Memory Vault.
class MemoryExtractionService {
  static final MemoryExtractionService instance =
      MemoryExtractionService._();
  MemoryExtractionService._();

  /// Analyze user message for extractable memories
  static Future<void> extractAndStore(int userId, String message) async {
    final lower = message.toLowerCase();
    final now = DateTime.now().toIso8601String();
    final db = DatabaseHelper.instance;

    // Goal detection
    final goalPatterns = [
      RegExp(r'i want to (.+)', caseSensitive: false),
      RegExp(r'my goal is (.+)', caseSensitive: false),
      RegExp(r"i(?:'m| am) working on (.+)", caseSensitive: false),
      RegExp(r"i(?:'m| am) trying to (.+)", caseSensitive: false),
      RegExp(r'i dream of (.+)', caseSensitive: false),
      RegExp(r'i hope to (.+)', caseSensitive: false),
      RegExp(r'i plan to (.+)', caseSensitive: false),
    ];

    for (final pattern in goalPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        final content = match.group(1)?.trim() ?? '';
        if (content.length > 3 && content.length < 200) {
          await _storeIfNew(db, userId, 'goal', content, now);
        }
      }
    }

    // Fear detection
    final fearPatterns = [
      RegExp(r"i(?:'m| am) afraid of (.+)", caseSensitive: false),
      RegExp(r"i(?:'m| am) scared of (.+)", caseSensitive: false),
      RegExp(r'i fear (.+)', caseSensitive: false),
      RegExp(r"i(?:'m| am) worried about (.+)", caseSensitive: false),
      RegExp(r"i(?:'m| am) anxious about (.+)", caseSensitive: false),
    ];

    for (final pattern in fearPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        final content = match.group(1)?.trim() ?? '';
        if (content.length > 3 && content.length < 200) {
          await _storeIfNew(db, userId, 'fear', content, now);
        }
      }
    }

    // Hobby detection
    final hobbyPatterns = [
      RegExp(r'i love (.+?)(?:\.|!|$)', caseSensitive: false),
      RegExp(r'i enjoy (.+?)(?:\.|!|$)', caseSensitive: false),
      RegExp(r'my hobby is (.+?)(?:\.|!|$)', caseSensitive: false),
      RegExp(r'i like (.+?)(?:\.|!|$)', caseSensitive: false),
    ];

    for (final pattern in hobbyPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        final content = match.group(1)?.trim() ?? '';
        if (content.length > 2 && content.length < 100) {
          await _storeIfNew(db, userId, 'hobby', content, now);
        }
      }
    }

    // Achievement detection
    if (lower.contains('i did it') ||
        lower.contains('i passed') ||
        lower.contains('i won') ||
        lower.contains('i got promoted') ||
        lower.contains('i graduated') ||
        lower.contains('i achieved') ||
        lower.contains('i finished') ||
        lower.contains('i completed')) {
      await _storeIfNew(
          db, userId, 'achievement', message.trim(), now);
    }

    // Preference detection
    final prefPatterns = [
      RegExp(r'i prefer (.+?)(?:\.|!|$)', caseSensitive: false),
      RegExp(r'my favorite (.+)', caseSensitive: false),
      RegExp(r'i always (.+?)(?:\.|!|$)', caseSensitive: false),
    ];

    for (final pattern in prefPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        final content = match.group(1)?.trim() ?? '';
        if (content.length > 2 && content.length < 150) {
          await _storeIfNew(db, userId, 'preference', content, now);
        }
      }
    }

    // Important date detection
    final datePattern = RegExp(
        r'(?:my|our) (.+?) is (?:on |)(\w+ \d+|\d+/\d+)',
        caseSensitive: false);
    final dateMatch = datePattern.firstMatch(message);
    if (dateMatch != null) {
      final content =
          '${dateMatch.group(1)} on ${dateMatch.group(2)}';
      await _storeIfNew(db, userId, 'date', content, now);
    }
  }

  /// Only store if no similar memory exists
  static Future<void> _storeIfNew(DatabaseHelper db, int userId,
      String category, String content, String now) async {
    final existing = await db.getDadMemoriesByCategory(userId, category);
    final lowerContent = content.toLowerCase();

    // Check for duplicates (fuzzy: if 60%+ chars match)
    for (final mem in existing) {
      if (mem.content.toLowerCase() == lowerContent) return;
      if (_similarity(mem.content.toLowerCase(), lowerContent) > 0.6) {
        // Update mention count for similar existing memory
        await db.touchMemory(mem.id!);
        return;
      }
    }

    await db.insertDadMemory(DadMemoryModel(
      userId: userId,
      category: category,
      content: content,
      createdAt: now,
    ));
  }

  /// Simple similarity ratio (Jaccard on words)
  static double _similarity(String a, String b) {
    final wordsA = a.split(RegExp(r'\s+')).toSet();
    final wordsB = b.split(RegExp(r'\s+')).toSet();
    if (wordsA.isEmpty || wordsB.isEmpty) return 0.0;
    final intersection = wordsA.intersection(wordsB).length;
    final union = wordsA.union(wordsB).length;
    return intersection / union;
  }

  /// Build memory vault context for AI prompt
  static Future<String> buildMemoryPrompt(int userId) async {
    final db = DatabaseHelper.instance;
    final memories = await db.getTopMemories(userId, limit: 15);
    if (memories.isEmpty) return '';

    final buf = StringBuffer();
    buf.writeln('=== DAD MEMORY VAULT ===');
    buf.writeln('Things I remember about my kid:');
    for (final mem in memories) {
      buf.writeln(mem.toPromptLine());
    }
    return buf.toString();
  }
}
