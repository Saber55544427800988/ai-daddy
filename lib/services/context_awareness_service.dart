/// Smart Context Awareness — time of day, weekday/weekend,
/// season, special occasions detection.
class ContextAwarenessService {
  static final ContextAwarenessService instance =
      ContextAwarenessService._();
  ContextAwarenessService._();

  /// Get full context snapshot for AI prompt
  static String buildContextPrompt() {
    final now = DateTime.now();
    final buf = StringBuffer();
    buf.writeln('=== CONTEXT ===');
    buf.writeln('Time: ${_getTimeOfDay(now.hour)} (${now.hour}:${now.minute.toString().padLeft(2, '0')})');
    buf.writeln('Day: ${_getDayName(now.weekday)}, ${_isWeekend(now.weekday) ? "Weekend" : "Weekday"}');
    buf.writeln('Season: ${_getSeason(now.month)}');

    final special = _getSpecialOccasion(now);
    if (special != null) {
      buf.writeln('Special: $special');
    }

    // Time-specific behavior hints
    buf.writeln(_getTimeBehavior(now.hour));

    return buf.toString();
  }

  /// Sleep mode detection
  static bool isSleepTime() {
    final hour = DateTime.now().hour;
    return hour >= 23 || hour < 6;
  }

  /// Late night mode (not full sleep, but winding down)
  static bool isLateNight() {
    final hour = DateTime.now().hour;
    return hour >= 21 || hour < 6;
  }

  /// Morning motivation window
  static bool isMorningWindow() {
    final hour = DateTime.now().hour;
    return hour >= 6 && hour < 10;
  }

  static String _getTimeOfDay(int hour) {
    if (hour < 6) return 'Late Night';
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    if (hour < 21) return 'Evening';
    return 'Night';
  }

  static String _getDayName(int weekday) {
    const days = [
      '', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return days[weekday];
  }

  static bool _isWeekend(int weekday) =>
      weekday == DateTime.saturday || weekday == DateTime.sunday;

  static String _getSeason(int month) {
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    if (month >= 9 && month <= 11) return 'Autumn';
    return 'Winter';
  }

  static String? _getSpecialOccasion(DateTime now) {
    final md = '${now.month}-${now.day}';
    const occasions = {
      '1-1': "New Year's Day 🎆",
      '2-14': "Valentine's Day 💝",
      '3-8': "International Women's Day 🌸",
      '6-16': "Father's Day 👨‍👧",
      '10-31': 'Halloween 🎃',
      '12-25': 'Christmas 🎄',
      '12-31': "New Year's Eve 🥂",
    };
    return occasions[md];
  }

  static String _getTimeBehavior(int hour) {
    if (hour >= 23 || hour < 5) {
      return 'SLEEP MODE: Be calm, soothing, encourage rest. Use gentle language. End messages with goodnight warmth.';
    }
    if (hour >= 5 && hour < 8) {
      return 'MORNING: Be energizing, motivational. Help them start the day strong.';
    }
    if (hour >= 8 && hour < 12) {
      return 'PRODUCTIVE MORNING: Be supportive of their routine. Encourage focus.';
    }
    if (hour >= 12 && hour < 14) {
      return 'MIDDAY: Check in on how their day is going. Light and friendly.';
    }
    if (hour >= 14 && hour < 18) {
      return 'AFTERNOON: Be encouraging. They might be tired — offer motivation.';
    }
    if (hour >= 18 && hour < 21) {
      return 'EVENING: Be warm and reflective. Help them wind down.';
    }
    return 'NIGHT: Be calming, reflective. Gentle encouragement.';
  }

  /// Get greeting based on time of day
  static String getTimeGreeting(String nickname) {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Still up, $nickname? 🌙';
    if (hour < 12) return 'Good morning, $nickname! ☀️';
    if (hour < 17) return 'Good afternoon, $nickname! 🌤️';
    if (hour < 21) return 'Good evening, $nickname! 🌅';
    return 'Hey $nickname, winding down? 🌙';
  }
}
