import '../database/database_helper.dart';
import '../models/mood_log_model.dart';

/// Emotional Intelligence System — detects mood from text,
/// tracks emotional patterns, crisis detection, mood memory.
class EmotionalIntelligenceService {
  static final EmotionalIntelligenceService instance =
      EmotionalIntelligenceService._();
  EmotionalIntelligenceService._();

  // ─── Mood Detection from Text ─────────────────────

  /// Analyze text → mood score (1-5) + detected emotion label
  static MoodAnalysis analyzeMood(String text) {
    final lower = text.toLowerCase().trim();
    double score = 3.0;
    String emotion = 'neutral';

    // Crisis keywords — highest priority
    if (_containsCrisisKeyword(lower)) {
      return const MoodAnalysis(score: 1.0, emotion: 'crisis', isCrisis: true);
    }

    // Negative emotions
    final negWeights = {
      'sad': -1.5,
      'depressed': -2.0,
      'anxious': -1.5,
      'worried': -1.0,
      'angry': -1.5,
      'frustrated': -1.0,
      'lonely': -1.5,
      'tired': -0.8,
      'exhausted': -1.0,
      'stressed': -1.2,
      'overwhelmed': -1.5,
      'hopeless': -2.0,
      'scared': -1.2,
      'afraid': -1.0,
      'hurt': -1.5,
      'disappointed': -1.0,
      'lost': -1.2,
      'confused': -0.5,
      'broken': -2.0,
      'crying': -1.8,
      'hate': -1.5,
      'terrible': -1.5,
      'awful': -1.5,
      'miserable': -2.0,
      'failed': -1.5,
      'fail': -1.0,
      'can\'t': -0.5,
      'sucks': -1.0,
      'worst': -1.5,
      'pain': -1.2,
      'give up': -1.8,
    };

    // Positive emotions
    final posWeights = {
      'happy': 1.5,
      'great': 1.5,
      'amazing': 2.0,
      'excited': 1.5,
      'proud': 1.5,
      'grateful': 1.5,
      'thankful': 1.2,
      'love': 1.0,
      'wonderful': 1.5,
      'fantastic': 2.0,
      'good': 0.8,
      'better': 0.5,
      'best': 1.5,
      'awesome': 1.5,
      'accomplished': 1.5,
      'motivated': 1.2,
      'inspired': 1.2,
      'confident': 1.0,
      'peaceful': 1.0,
      'relaxed': 0.8,
      'fun': 1.0,
      'laugh': 1.2,
      'smile': 1.0,
      'hope': 0.8,
      'win': 1.5,
      'won': 1.5,
      'success': 1.5,
      'achieved': 1.5,
    };

    double totalWeight = 0;
    int matchCount = 0;

    for (final entry in negWeights.entries) {
      if (lower.contains(entry.key)) {
        totalWeight += entry.value;
        matchCount++;
        if (entry.value <= -1.5) {
          emotion = 'very_sad';
        } else if (entry.value <= -1.0) {
          emotion = 'sad';
        } else {
          emotion = 'down';
        }
      }
    }

    for (final entry in posWeights.entries) {
      if (lower.contains(entry.key)) {
        totalWeight += entry.value;
        matchCount++;
        if (entry.value >= 1.5) {
          emotion = 'very_happy';
        } else if (entry.value >= 1.0) {
          emotion = 'happy';
        } else {
          emotion = 'okay';
        }
      }
    }

    if (matchCount > 0) {
      score = (3.0 + totalWeight / matchCount).clamp(1.0, 5.0);
    }

    // Text pattern analysis
    if (lower.endsWith('...') || lower.endsWith('..')) score -= 0.2;
    if (lower.contains('!!!')) score += 0.3;
    if (lower.toUpperCase() == lower && lower.length > 5) score -= 0.3; // ALL CAPS = intense
    if (lower.length < 5) score -= 0.1; // very short = disengaged

    score = score.clamp(1.0, 5.0);

    if (emotion == 'neutral') {
      if (score >= 4.0) {
        emotion = 'happy';
      } else if (score >= 3.5) {
        emotion = 'good';
      } else if (score <= 2.0) {
        emotion = 'sad';
      } else if (score <= 2.5) {
        emotion = 'down';
      }
    }

    return MoodAnalysis(score: score, emotion: emotion, isCrisis: false);
  }

  // ─── Crisis Detection ─────────────────────────────

  static bool _containsCrisisKeyword(String text) {
    const crisisKeywords = [
      'kill myself',
      'want to die',
      'end my life',
      'suicide',
      'self harm',
      'self-harm',
      'hurt myself',
      'no reason to live',
      'nobody cares',
      'better off dead',
      'i want to disappear',
      'can\'t go on',
      'nothing matters',
      'goodbye forever',
      'ending it',
      'don\'t want to exist',
      'no point in living',
    ];
    for (final keyword in crisisKeywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  /// Generate crisis response — immediate safety-first reply
  static String getCrisisResponse(String nickname) {
    return "Hey $nickname, I hear you, and I want you to know — "
        "I'm right here. What you're feeling is real, and it matters. "
        "You matter. 💙\n\n"
        "Please talk to someone who can help:\n"
        "📞 **988 Suicide & Crisis Lifeline** — Call or text 988\n"
        "📱 **Crisis Text Line** — Text HOME to 741741\n\n"
        "You're not alone. Daddy's always here for you. 🫂";
  }

  // ─── Mood Memory ──────────────────────────────────

  /// Store a mood entry from conversation analysis
  static Future<void> recordMoodFromChat(
      int userId, double moodScore) async {
    final db = DatabaseHelper.instance;
    await db.insertMoodLog(MoodLogModel(
      userId: userId,
      moodScore: moodScore.round().clamp(1, 5),
      timestamp: DateTime.now().toIso8601String(),
    ));
  }

  /// Get mood trend (improving, stable, declining)
  static Future<String> getMoodTrend(int userId) async {
    final db = DatabaseHelper.instance;
    final moods = await db.getMoodLogs(userId, days: 7);
    if (moods.length < 3) return 'stable';

    // Compare first half vs second half averages
    final mid = moods.length ~/ 2;
    final firstHalf =
        moods.sublist(0, mid).map((m) => m.moodScore).reduce((a, b) => a + b) /
            mid;
    final secondHalf =
        moods.sublist(mid).map((m) => m.moodScore).reduce((a, b) => a + b) /
            (moods.length - mid);

    final diff = secondHalf - firstHalf;
    if (diff > 0.5) return 'improving';
    if (diff < -0.5) return 'declining';
    return 'stable';
  }

  /// Get average mood for last N days
  static Future<double> getAverageMood(int userId, {int days = 7}) async {
    final db = DatabaseHelper.instance;
    final moods = await db.getMoodLogs(userId, days: days);
    if (moods.isEmpty) return 3.0;
    return moods.map((m) => m.moodScore).reduce((a, b) => a + b) /
        moods.length;
  }

  // ─── Emotional Context for AI ─────────────────────

  /// Build emotional context string for AI system prompt
  static Future<String> buildEmotionalContext(int userId) async {
    final avgMood = await getAverageMood(userId);
    final trend = await getMoodTrend(userId);
    final db = DatabaseHelper.instance;
    final recentMoods = await db.getMoodLogs(userId, days: 3);

    final buf = StringBuffer();
    buf.writeln('=== EMOTIONAL STATE ===');
    buf.writeln('Average mood (7d): ${avgMood.toStringAsFixed(1)}/5');
    buf.writeln('Mood trend: $trend');

    if (recentMoods.isNotEmpty) {
      final latestMood = recentMoods.first.moodScore;
      buf.writeln('Latest mood: $latestMood/5');
      if (latestMood <= 2) {
        buf.writeln(
            'USER IS FEELING LOW. Be extra gentle, warm, and supportive.');
      } else if (latestMood >= 4) {
        buf.writeln(
            'User is in a good mood. Match their energy positively.');
      }
    }

    if (trend == 'declining') {
      buf.writeln(
          'MOOD IS DECLINING. Check in gently, show extra care.');
    }

    return buf.toString();
  }
}

/// Result of mood analysis
class MoodAnalysis {
  final double score;
  final String emotion;
  final bool isCrisis;

  const MoodAnalysis({
    required this.score,
    required this.emotion,
    required this.isCrisis,
  });
}
