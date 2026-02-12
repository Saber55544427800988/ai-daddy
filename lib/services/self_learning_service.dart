import 'dart:convert';
import 'dart:math';
import '../database/database_helper.dart';
import '../models/user_profile_model.dart';

/// Enhanced self-learning engine using:
///  • Per-tone reinforcement scoring (+1 / -1)
///  • Hourly engagement pattern tracking
///  • Message-length & response-time adaptation
///  • Weekly deep-analysis cycle
///  • Streak & consistency tracking
///  • Mood-aware tone switching
///  • Intent frequency analysis
///
/// All data stays 100 % on-device — no network calls.
class SelfLearningService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // ─────────────────────────────────────────────────
  //  PUBLIC API
  // ─────────────────────────────────────────────────

  /// Record a single interaction for reinforcement learning.
  /// Call this AFTER the AI responds to every user message.
  Future<void> recordInteraction({
    required int userId,
    required String toneUsed,
    required String intentDetected,
    required int userMessageLength,
    required double responseTimeSeconds,
    required double sentimentScore, // -1.0 … +1.0
    required double engagementScore, // 0.0 … 1.0
  }) async {
    final now = DateTime.now();
    await _db.insertInteractionLog({
      'user_id': userId,
      'timestamp': now.toIso8601String(),
      'hour_of_day': now.hour,
      'day_of_week': now.weekday, // 1=Mon … 7=Sun
      'user_message_length': userMessageLength,
      'response_time_seconds': responseTimeSeconds,
      'tone_used': toneUsed,
      'intent_detected': intentDetected,
      'sentiment_score': sentimentScore,
      'engagement_score': engagementScore,
      'user_replied': 0,
      'reply_was_positive': 0,
    });
  }

  /// Called when the user sends their NEXT message — retroactively
  /// marks the previous AI turn as "replied" with sentiment.
  Future<void> recordReply(int userId, bool wasPositive) async {
    await _db.markLastInteractionReplied(userId, wasPositive);
  }

  /// Quick per-message analysis (runs every message).
  /// Updates tone scores via reinforcement and total_interactions.
  Future<void> quickUpdate(int userId) async {
    final profile = await _db.getUserProfile(userId);
    if (profile == null) return;

    // ── Reinforce tone scores from last few interactions ──
    final positivity = await _db.getToneReplyPositivity(userId, days: 7);
    double caring = profile.caringScore;
    double strict = profile.strictScore;
    double playful = profile.playfulScore;
    double motivational = profile.motivationalScore;

    for (final entry in positivity.entries) {
      // delta = +1 if positivity > 0.5, -1 if < 0.5, scaled
      final delta = (entry.value - 0.5) * 4.0; // range ≈ -2 … +2
      switch (entry.key) {
        case 'caring':
          caring = (caring + delta).clamp(0, 100);
          break;
        case 'strict':
          strict = (strict + delta).clamp(0, 100);
          break;
        case 'playful':
          playful = (playful + delta).clamp(0, 100);
          break;
        case 'motivational':
          motivational = (motivational + delta).clamp(0, 100);
          break;
      }
    }

    await _db.updateUserProfile(profile.copyWith(
      caringScore: caring,
      strictScore: strict,
      playfulScore: playful,
      motivationalScore: motivational,
      totalInteractions: profile.totalInteractions + 1,
    ));
  }

  /// Deep analysis — runs every 10 messages or on-demand.
  /// Aggregates patterns, adapts tone/length, updates streak & timing.
  Future<void> analyzeAndAdapt(int userId) async {
    final profile = await _db.getUserProfile(userId);
    if (profile == null) return;

    // ── 1. Engagement-by-tone ──
    final toneEngagement = await _db.getEngagementByTone(userId, days: 14);

    // ── 2. Engagement-by-hour ──
    final hourEngagement = await _db.getEngagementByHour(userId, days: 14);
    final bestHoursJson =
        jsonEncode(hourEngagement.map((k, v) => MapEntry(k.toString(), v)));

    // ── 3. Best preferred reminder times (top-3 hours) ──
    final sortedHours = hourEngagement.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topHours = sortedHours.take(3).map((e) => e.key).toList();
    final reminderTimesJson = jsonEncode(topHours);

    // ── 4. Intent frequency ──
    final intents = await _db.getIntentFrequency(userId, days: 14);
    final intentsJson = jsonEncode(intents);

    // ── 5. Message length adaptation ──
    final avgLen = await _db.getAvgUserMessageLength(userId, days: 14);
    String preferred = profile.preferredMessageLength;
    if (avgLen > 80) {
      preferred = 'long'; // user writes a lot — mirror with longer replies
    } else if (avgLen > 30) {
      preferred = 'medium';
    } else {
      preferred = 'short';
    }

    // ── 6. Average response time ──
    final avgRt = await _db.getAvgResponseTime(userId, days: 14);

    // ── 7. Streak calculation ──
    final activeDays = await _db.getActiveDays(userId, days: 30);
    int streak = _calculateStreak(activeDays);

    // ── 8. Mood-aware tone selection ──
    final moods = await _db.getMoodLogs(userId, days: 7);
    double avgMood = 3.0;
    if (moods.isNotEmpty) {
      avgMood =
          moods.map((m) => m.moodScore).reduce((a, b) => a + b) / moods.length;
    }
    // Push recent moods into a sliding window (last 14)
    final moodList = profile.moodHistoryList;
    if (moods.isNotEmpty) {
      for (final m in moods) {
        moodList.add(m.moodScore.toDouble());
      }
    }
    while (moodList.length > 14) {
      moodList.removeAt(0);
    }

    // ── 9. Determine best tone ──
    String bestTone = _determineBestTone(
      profile: profile,
      toneEngagement: toneEngagement,
      avgMood: avgMood,
      streak: streak,
    );

    // ── 10. Overall engagement ──
    final avgEngagement = await _db.getAverageEngagement(userId, days: 7);
    final msgCount = await _db.getMessageCount(userId, days: 7);
    final completedMissions = await _db.getCompletedMissionCount(userId);

    final patterns = {
      'avg_engagement': avgEngagement,
      'weekly_messages': msgCount,
      'avg_mood': avgMood,
      'completed_missions': completedMissions,
      'streak': streak,
      'last_analyzed': DateTime.now().toIso8601String(),
    };

    // ── Save everything ──
    await _db.updateUserProfile(profile.copyWith(
      favoriteTone: bestTone,
      preferredMessageLength: preferred,
      activityPatterns: jsonEncode(patterns),
      bestActiveHours: bestHoursJson,
      interactionStreak: streak,
      preferredReminderTimes: reminderTimesJson,
      lastWeeklyAnalysis: DateTime.now().toIso8601String(),
      avgUserMsgLength: avgLen,
      avgResponseTime: avgRt,
      topIntents: intentsJson,
      moodHistory: jsonEncode(moodList),
    ));
  }

  // ─────────────────────────────────────────────────
  //  SCORING HELPERS
  // ─────────────────────────────────────────────────

  /// Compute engagement score for one interaction (0.0 – 1.0)
  double calculateEngagement({
    required double responseTimeSeconds,
    required int messageLength,
    required bool isPositive,
  }) {
    double score = 0.5;

    // Faster response = higher engagement
    if (responseTimeSeconds < 10) {
      score += 0.25;
    } else if (responseTimeSeconds < 30) {
      score += 0.15;
    } else if (responseTimeSeconds < 120) {
      score += 0.05;
    } else if (responseTimeSeconds > 600) {
      score -= 0.2;
    }

    // Longer messages (more invested user)
    if (messageLength > 100) {
      score += 0.15;
    } else if (messageLength > 50) {
      score += 0.1;
    } else if (messageLength > 20) {
      score += 0.05;
    }

    // Sentiment
    if (isPositive) score += 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Sentiment on a -1.0 … +1.0 scale
  double sentimentScore(String message) {
    final lower = message.toLowerCase();
    int pos = _positiveWords.where((w) => lower.contains(w)).length;
    int neg = _negativeWords.where((w) => lower.contains(w)).length;
    final total = pos + neg;
    if (total == 0) return 0.0;
    return ((pos - neg) / total).clamp(-1.0, 1.0);
  }

  /// Simple boolean positive check
  bool isPositiveSentiment(String message) => sentimentScore(message) >= 0.0;

  /// Choose the optimal tone for the AI's next response, given the
  /// current user profile and contextual signals.
  String chooseToneForContext({
    required UserProfileModel profile,
    required String detectedIntent,
    required double currentSentiment,
  }) {
    // If user is upset, override to caring
    if (currentSentiment < -0.3) return 'caring';

    // If intent is study/advice, prefer strict or motivational
    if (detectedIntent == 'study' || detectedIntent == 'advice') {
      return profile.strictScore >= profile.motivationalScore
          ? 'strict'
          : 'motivational';
    }

    // If intent is celebrate, go playful
    if (detectedIntent == 'celebrate') return 'playful';

    // Otherwise, use the learned best tone
    return profile.bestTone;
  }

  // ─────────────────────────────────────────────────
  //  PRIVATE HELPERS
  // ─────────────────────────────────────────────────

  /// Determine the best overall tone using reinforcement scores,
  /// engagement data, mood, and streak.
  String _determineBestTone({
    required UserProfileModel profile,
    required Map<String, double> toneEngagement,
    required double avgMood,
    required int streak,
  }) {
    // Start from reinforcement scores
    final scores = {
      'caring': profile.caringScore,
      'strict': profile.strictScore,
      'playful': profile.playfulScore,
      'motivational': profile.motivationalScore,
    };

    // Boost tones that had high engagement
    for (final entry in toneEngagement.entries) {
      if (scores.containsKey(entry.key)) {
        scores[entry.key] = scores[entry.key]! + entry.value * 10;
      }
    }

    // Mood overrides
    if (avgMood < 2.0) {
      scores['caring'] = scores['caring']! + 20;
    } else if (avgMood < 3.0) {
      scores['caring'] = scores['caring']! + 10;
    } else if (avgMood > 4.0) {
      scores['playful'] = scores['playful']! + 10;
    }

    // Streak bonus — if user is very active, lean playful/motivational
    if (streak > 7) {
      scores['motivational'] = scores['motivational']! + 5;
      scores['playful'] = scores['playful']! + 5;
    }

    // Pick highest
    return scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Calculate consecutive-day streak from a list of active day strings
  /// (already sorted DESC).
  int _calculateStreak(List<String> activeDays) {
    if (activeDays.isEmpty) return 0;

    int streak = 0;
    DateTime expected = DateTime.now();
    // Normalize to date-only
    expected = DateTime(expected.year, expected.month, expected.day);

    for (final dayStr in activeDays) {
      final day = DateTime.parse(dayStr);
      final diff = expected.difference(day).inDays;
      if (diff == 0 || diff == 1) {
        streak++;
        expected = day;
      } else {
        break;
      }
    }
    return max(streak, 0);
  }

  // ─────────────────────────────────────────────────
  //  WORD LISTS
  // ─────────────────────────────────────────────────

  static const _positiveWords = [
    'good', 'great', 'awesome', 'thanks', 'thank', 'love', 'happy',
    'amazing', 'nice', 'cool', 'perfect', 'wonderful', 'yes', 'yeah',
    'haha', 'lol', '❤️', '😄', '😊', '🥰', '👍', 'appreciate',
    'excited', 'proud', 'yay', 'brilliant', 'excellent', 'sweet',
    'kind', 'helpful', 'wow', 'fantastic', 'beautiful', 'fun',
  ];

  static const _negativeWords = [
    'bad', 'sad', 'hate', 'angry', 'frustrated', 'annoyed', 'tired',
    'bored', 'whatever', 'meh', 'no', 'stop', 'leave', 'shut',
    'depressed', 'lonely', 'cry', 'sucks', 'terrible', 'horrible',
    'upset', 'anxious', 'stressed', 'scared', 'worried', 'hurt',
  ];
}
