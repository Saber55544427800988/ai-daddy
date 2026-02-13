import 'dart:math';
import '../models/message_model.dart';
import '../models/ai_token_model.dart';
import '../models/user_profile_model.dart';

/// Offline AI response engine for AI Daddy.
/// Generates dad-like responses based on personality, context, token budget,
/// and self-learned user preferences from [UserProfileModel].
class AIEngine {
  final Random _random = Random();

  /// Generate a dad-like response to the user message.
  ///
  /// When [learnedProfile] is provided the engine adapts:
  ///  • Tone selection (weighted by reinforcement scores)
  ///  • Message length preference
  ///  • Context-aware intent overrides
  String generateResponse({
    required String userMessage,
    required String personality,
    required String nickname,
    required List<MessageModel> recentMessages,
    AITokenModel? tokens,
    UserProfileModel? learnedProfile,
  }) {
    final lower = userMessage.toLowerCase().trim();

    // If tokens are low, shorten responses
    final isLowTokens = tokens != null && tokens.isLow;

    // Detect message intent
    final intent = detectIntent(lower);

    // Possibly override personality with learned best tone
    String effectivePersonality = personality;
    if (learnedProfile != null) {
      effectivePersonality = _adaptPersonality(
        base: personality,
        profile: learnedProfile,
        intent: intent,
        message: lower,
      );
    }

    // Pick response pool based on personality + intent
    List<String> responses = _getResponses(
      personality: effectivePersonality,
      intent: intent,
      nickname: nickname,
      isLowTokens: isLowTokens,
    );

    // Adapt response length if profile says "long"
    if (learnedProfile != null &&
        learnedProfile.preferredMessageLength == 'long' &&
        !isLowTokens) {
      // Combine two responses for a richer message
      if (responses.length >= 2) {
        final a = responses[_random.nextInt(responses.length)];
        List<String> remaining = responses.where((r) => r != a).toList();
        if (remaining.isNotEmpty) {
          final b = remaining[_random.nextInt(remaining.length)];
          return '$a\n\n$b';
        }
      }
    }

    return responses[_random.nextInt(responses.length)];
  }

  /// Expose intent detection so ChatProvider can log it.
  String detectIntent(String messageLower) {
    return _detectIntent(messageLower);
  }

  /// Pick the effective personality considering learned scores.
  String _adaptPersonality({
    required String base,
    required UserProfileModel profile,
    required String intent,
    required String message,
  }) {
    // Hard override when user is clearly upset
    if (intent == 'comfort' || intent == 'calm') return 'caring';
    if (intent == 'celebrate') return 'playful';
    if (intent == 'study') {
      return profile.strictScore >= profile.motivationalScore
          ? 'strict'
          : 'motivational';
    }

    // If mood is low, lean caring
    if (profile.averageMood > 0 && profile.averageMood < 2.5) return 'caring';

    // Respect the user's explicitly chosen personality
    return base;
  }

  String _detectIntent(String message) {
    if (message.contains(RegExp(r'sad|upset|cry|depressed|down|tired|lonely'))) {
      return 'comfort';
    }
    if (message.contains(RegExp(r'happy|great|awesome|excited|amazing|good'))) {
      return 'celebrate';
    }
    if (message.contains(RegExp(r'help|advice|what should|how do|how can'))) {
      return 'advice';
    }
    if (message.contains(RegExp(r'hi|hello|hey|morning|evening|night'))) {
      return 'greeting';
    }
    if (message.contains(RegExp(r'love|miss|thank|appreciate'))) {
      return 'emotional';
    }
    if (message.contains(RegExp(r'bored|nothing|idk|whatever|meh'))) {
      return 'motivate';
    }
    if (message.contains(RegExp(r'angry|mad|frustrated|annoyed|hate'))) {
      return 'calm';
    }
    if (message.contains(RegExp(r'exam|test|study|homework|school|work'))) {
      return 'study';
    }
    return 'general';
  }

  List<String> _getResponses({
    required String personality,
    required String intent,
    required String nickname,
    required bool isLowTokens,
  }) {
    if (isLowTokens) {
      return _shortResponses(nickname);
    }

    switch (personality.toLowerCase()) {
      case 'caring':
        return _caringResponses(intent, nickname);
      case 'strict':
        return _strictResponses(intent, nickname);
      case 'playful':
        return _playfulResponses(intent, nickname);
      case 'motivational':
        return _motivationalResponses(intent, nickname);
      default:
        return _caringResponses(intent, nickname);
    }
  }

  List<String> _shortResponses(String n) {
    return [
      "Got it, $n ❤️",
      "I hear you, champ",
      "Daddy's here 💪",
      "Understood, $n",
      "Always for you ❤️",
    ];
  }

  List<String> _caringResponses(String intent, String n) {
    switch (intent) {
      case 'greeting':
        return [
          "Hey $n. ❤️",
          "Good to see you, $n.",
          "Hello champ. How's your day?",
          "Hey there, $n. Tell me everything.",
        ];
      case 'comfort':
        return [
          "Come here, $n. It's okay. ❤️",
          "Tough times don't last. You do. 💪",
          "I know it's hard. I'm right here.",
          "It's okay to cry, $n. I'm here.",
        ];
      case 'celebrate':
        return [
          "That's my $n! Proud of you. 🎉",
          "Way to go, champ! ⭐",
          "I knew you could do it, $n!",
          "Look at you go! ❤️",
        ];
      case 'advice':
        return [
          "Step by step, $n. Don't rush. ❤️",
          "Every big thing starts small. Focus. 💪",
          "Breathe first. Think second. Act third.",
          "Trust yourself, $n. You're smarter than you think.",
        ];
      case 'emotional':
        return [
          "I love you too, $n. ❤️",
          "You make Daddy proud every day.",
          "Those words mean the world to me.",
          "You're my greatest treasure, $n.",
        ];
      case 'motivate':
        return [
          "Get up, $n. Let's do something. 💪",
          "How about a mission today? You'll earn XP! 🎮",
          "Time to shine, champ!",
          "Boredom is a choice. Move.",
        ];
      case 'calm':
        return [
          "Deep breath, $n. I'm here.",
          "It's okay to be frustrated. Let it out.",
          "This too shall pass.",
          "I hear you, $n.",
        ];
      case 'study':
        return [
          "Focus, $n. You've got this. 📚",
          "25 minutes of focus. Then break. Go.",
          "Proud of you for studying, $n.",
          "One step at a time. You're building your future.",
        ];
      default:
        return [
          "Tell me more, $n.",
          "What else is on your mind?",
          "I'm listening.",
          "Gotcha, $n. I'm here.",
        ];
    }
  }

  List<String> _strictResponses(String intent, String n) {
    switch (intent) {
      case 'greeting':
        return [
          "Hey $n. Let's be productive.",
          "Morning. What's the plan?",
          "No time to waste, $n.",
        ];
      case 'comfort':
        return [
          "You're stronger than this, $n. Get up. 💪",
          "Tough, $n. But you're tougher.",
          "Feel it. Accept it. Then fix it.",
        ];
      case 'celebrate':
        return [
          "Good job. Now aim higher. 🎯",
          "Not bad. I know you can do better.",
          "Expected nothing less, $n.",
        ];
      case 'motivate':
        return [
          "Get up. Do something productive. 💪",
          "No slacking, $n.",
          "Time is ticking. Move.",
        ];
      case 'study':
        return [
          "Phone down. Books open. No excuses.",
          "Study now. Play later. 📚",
          "Focus, $n. Get to work.",
        ];
      default:
        return [
          "Noted, $n. Stay focused.",
          "I hear you. Keep moving.",
          "Good. Eyes on the prize. 🎯",
        ];
    }
  }

  List<String> _playfulResponses(String intent, String n) {
    switch (intent) {
      case 'greeting':
        return [
          "Heyyyy $n! 😜",
          "Oh look who showed up! 🎉",
          "Yooo $n!",
        ];
      case 'comfort':
        return [
          "Aww $n. Come here. 🤗",
          "Bad day? Daddy's got hugs. 🤗",
          "Even superheroes have bad days.",
        ];
      case 'celebrate':
        return [
          "YESSS $n!!! 🎉",
          "$n is on FIRE! 🔥",
          "*throws confetti* 🎊",
        ];
      case 'motivate':
        return [
          "Bored? Complete a mission! 🎮",
          "Name 3 fun things. Go! 🏃‍♂️",
          "Let's do something fun, $n!",
        ];
      default:
        return [
          "Haha $n! 😂",
          "Tell me mooore 👀",
          "Classic $n! 😄",
        ];
    }
  }

  List<String> _motivationalResponses(String intent, String n) {
    switch (intent) {
      case 'greeting':
        return [
          "Today is YOUR day, $n. 🌟",
          "Champions show up. Here you are. 🏆",
          "Ready to level up? 📈",
        ];
      case 'comfort':
        return [
          "Every storm ends, $n. Keep going. 🌈",
          "Tough times build tough people.",
          "This is a chapter. Not the whole story.",
        ];
      case 'celebrate':
        return [
          "Remember this feeling, $n. You earned it. 🏆",
          "Hard work pays off. Proud of you. 💪",
          "That's the energy! Keep winning. 🌟",
        ];
      case 'motivate':
        return [
          "Ordinary vs extraordinary? That EXTRA effort. Go. 💪",
          "Every champion started somewhere. Start now.",
          "Your potential is limitless, $n. Move.",
        ];
      case 'study':
        return [
          "Discipline today = freedom tomorrow. 🎯",
          "Knowledge is power. Keep going. 📚",
          "Smart work + hard work = unstoppable.",
        ];
      default:
        return [
          "Keep going, $n. You're close. 💪",
          "Every step counts. Don't stop.",
          "I see greatness in you, $n. 🌟",
        ];
    }
  }

  /// Detect if user message contains a time-based event for smart reminders.
  ///
  /// Triggers:
  ///   "I have a meeting at 3 PM"
  ///   "Tomorrow morning I need to submit homework"
  ///   "Call Mom at 7 PM"
  ///   "Remind me to drink water in 30 minutes"
  ///   "I need to wake up at 6 AM"
  SmartReminderParsed? detectSmartReminder(String message) {
    final lower = message.toLowerCase();

    // ── Time patterns ──
    final timeRegex = RegExp(
        r'(\d{1,2})\s*(am|pm|AM|PM)|at\s+(\d{1,2}):?(\d{2})?\s*(am|pm|AM|PM)?');
    final timeMatch = timeRegex.firstMatch(lower);

    // Word-to-number mapping for time expressions
    const wordToNum = <String, int>{
      'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
      'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
      'eleven': 11, 'twelve': 12, 'fifteen': 15, 'twenty': 20,
      'thirty': 30, 'forty': 40, 'fifty': 50,
    };

    // "in X minutes/hours" or "for X minutes" or "X minutes/hours later" or bare "X minutes" — supports word numbers
    final numWords = wordToNum.keys.join('|');
    final inDurationRegex = RegExp(
      '(?:(?:in|for)\\s+)(\\d+|$numWords)\\s*(minutes?|mins?|hours?|hrs?|seconds?|secs?)'
      '|(\\d+|$numWords)\\s*(minutes?|mins?|hours?|hrs?)\\s+(?:later|from now)'
      '|(?:(?:in|for)\\s+)?half\\s+(?:an?\\s+)?hour\\s*(?:later|from\\s*now)?'
      '|(?:(?:in|for)\\s+)an?\\s+hour\\s*(?:later|from\\s*now)?'
      '|(\\d+|$numWords)\\s*(minutes?|mins?|hours?|hrs?|seconds?|secs?)',
      caseSensitive: false,
    );
    final durationMatch = inDurationRegex.firstMatch(lower);

    // ── Date patterns ──
    final hasTomorrow = lower.contains('tomorrow');
    final hasMorning = lower.contains('morning');
    final hasEvening = lower.contains('evening');
    final hasNight = lower.contains('tonight') || lower.contains('night');
    final hasAfternoon = lower.contains('afternoon');

    // ── Action keywords that signal a reminder ──
    final hasReminderIntent = RegExp(
      r'remind|need to|have to|must|gotta|should|'
      r"i have\b|i got\b|i've got|ive got|"
      r"don't forget|dont forget|don't let me forget|"
      r'wake me|wake up|alarm|'
      r'going to|gonna|planning to|scheduled|'
      r'appointment|deadline|due|submit',
    ).hasMatch(lower);

    // ── Event keywords ──
    final eventKeywords = {
      'meeting': 'meeting',
      'call': 'call',
      'phone': 'call',
      'homework': 'homework',
      'submit': 'homework',
      'assignment': 'homework',
      'project': 'homework',
      'exam': 'study',
      'test': 'study',
      'study': 'study',
      'quiz': 'study',
      'appointment': 'appointment',
      'dentist': 'appointment',
      'doctor': 'appointment',
      'gym': 'exercise',
      'workout': 'exercise',
      'exercise': 'exercise',
      'run': 'exercise',
      'walk': 'exercise',
      'medicine': 'health',
      'pill': 'health',
      'water': 'health',
      'eat': 'meal',
      'lunch': 'meal',
      'dinner': 'meal',
      'breakfast': 'meal',
      'cook': 'meal',
      'class': 'class',
      'lecture': 'class',
      'lesson': 'class',
      'pick up': 'errand',
      'buy': 'errand',
      'shop': 'errand',
      'clean': 'chore',
      'laundry': 'chore',
      'pray': 'prayer',
      'prayer': 'prayer',
      'sleep': 'sleep',
      'bed': 'sleep',
      'wake': 'wake',
    };

    String? eventType;
    for (final entry in eventKeywords.entries) {
      if (lower.contains(entry.key)) {
        eventType = entry.value;
        break;
      }
    }

    // Must have: (time context + event/intent) OR (event keyword + intent) OR (event keyword alone = auto-detect)
    final hasTimeContext = timeMatch != null ||
        durationMatch != null ||
        hasTomorrow ||
        hasMorning ||
        hasEvening ||
        hasNight ||
        hasAfternoon;

    // If nothing found at all, skip
    if (!hasTimeContext && !hasReminderIntent && eventType == null) return null;
    // If only reminder intent with no time and no event, skip
    if (!hasTimeContext && eventType == null) return null;

    // ── Calculate scheduled time ──
    DateTime scheduledTime = DateTime.now();

    if (durationMatch != null) {
      // "in 30 minutes" / "five minutes later" / "half an hour" / bare "5 minutes"
      final numStr = durationMatch.group(1) ?? durationMatch.group(3) ?? durationMatch.group(5);
      final unitStr = durationMatch.group(2) ?? durationMatch.group(4) ?? durationMatch.group(6) ?? '';
      if (numStr == null) {
        // "half an hour" or "an hour" pattern
        final matchText = durationMatch.group(0) ?? '';
        if (matchText.contains('half')) {
          scheduledTime = scheduledTime.add(const Duration(minutes: 30));
        } else {
          scheduledTime = scheduledTime.add(const Duration(hours: 1));
        }
      } else {
        final amount = int.tryParse(numStr) ?? wordToNum[numStr.toLowerCase()] ?? 0;
        if (unitStr.startsWith('h')) {
          scheduledTime = scheduledTime.add(Duration(hours: amount));
        } else if (unitStr.startsWith('s')) {
          scheduledTime = scheduledTime.add(Duration(seconds: amount));
        } else {
          scheduledTime = scheduledTime.add(Duration(minutes: amount));
        }
      }
    } else if (timeMatch != null) {
      int hour =
          int.tryParse(timeMatch.group(1) ?? timeMatch.group(3) ?? '0') ?? 0;
      int minute = int.tryParse(timeMatch.group(4) ?? '0') ?? 0;
      String? period = timeMatch.group(2) ?? timeMatch.group(5);

      if (period != null && period.toLowerCase() == 'pm' && hour != 12) {
        hour += 12;
      }
      if (period != null && period.toLowerCase() == 'am' && hour == 12) {
        hour = 0;
      }

      scheduledTime = DateTime(
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day + (hasTomorrow ? 1 : 0),
        hour,
        minute,
      );

      // If the time already passed today, schedule for tomorrow
      if (!hasTomorrow && scheduledTime.isBefore(DateTime.now())) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
    } else if (hasTomorrow) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
      int hour = 9; // Default morning
      if (hasEvening) {
        hour = 18;
      } else if (hasAfternoon) {
        hour = 14;
      } else if (hasNight) {
        hour = 21;
      } else if (hasMorning) {
        hour = 8;
      }
      scheduledTime = DateTime(
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        hour,
        0,
      );
    } else if (hasMorning) {
      // Today morning → if already past, tomorrow morning
      scheduledTime = DateTime(
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        8,
        0,
      );
      if (scheduledTime.isBefore(DateTime.now())) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
    } else if (hasEvening) {
      scheduledTime = DateTime(
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        18,
        0,
      );
      if (scheduledTime.isBefore(DateTime.now())) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
    } else if (hasNight) {
      scheduledTime = DateTime(
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        21,
        0,
      );
      if (scheduledTime.isBefore(DateTime.now())) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
    } else if (hasAfternoon) {
      scheduledTime = DateTime(
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        14,
        0,
      );
      if (scheduledTime.isBefore(DateTime.now())) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
    } else {
      // Has reminder intent + event but no explicit time → 1 hour from now
      scheduledTime = scheduledTime.add(const Duration(hours: 1));
    }

    return SmartReminderParsed(
      scheduledTime: scheduledTime,
      eventType: eventType ?? 'custom',
      originalText: message,
    );
  }
}

class SmartReminderParsed {
  final DateTime scheduledTime;
  final String eventType;
  final String originalText;

  SmartReminderParsed({
    required this.scheduledTime,
    required this.eventType,
    required this.originalText,
  });
}
