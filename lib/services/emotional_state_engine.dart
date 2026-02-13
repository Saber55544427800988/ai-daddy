import '../database/database_helper.dart';
import '../models/emotional_state_model.dart';

/// Emotional State Engine — manages AI Daddy's internal emotional state.
///
/// AI Daddy has feelings. Not random — grounded and reactive.
/// State transitions based on what the user is going through.
/// State affects tone, message length, reminder intensity.
///
/// Also manages protective instinct activation.
class EmotionalStateEngine {
  static final EmotionalStateEngine instance = EmotionalStateEngine._();
  EmotionalStateEngine._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // Cached state per user (in-memory for speed)
  final Map<int, String> _currentState = {};
  final Map<int, double> _stateIntensity = {};

  // ════════════════════════════════════════════════════
  //  STATE TRANSITIONS
  // ════════════════════════════════════════════════════

  /// Valid AI emotional states
  static const validStates = [
    'calm', 'caring', 'concerned', 'protective',
    'firm', 'proud', 'relieved', 'disappointed',
  ];

  /// Get current AI state for user
  String getState(int userId) => _currentState[userId] ?? 'calm';
  double getIntensity(int userId) => _stateIntensity[userId] ?? 0.5;

  /// Load persisted state from DB
  Future<void> loadState(int userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'emotional_state_log',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      _currentState[userId] = (rows.first['state'] as String?) ?? 'calm';
      _stateIntensity[userId] =
          (rows.first['state_intensity'] as num?)?.toDouble() ?? 0.5;
    } else {
      _currentState[userId] = 'calm';
      _stateIntensity[userId] = 0.5;
    }
  }

  /// Determine AI state based on user's message analysis.
  /// Returns the new state name.
  Future<String> transitionState({
    required int userId,
    required double moodScore, // -5 to +5
    String? careThreadType,
    String? careThreadIntensity,
    bool userIgnoredAdvice = false,
    bool userAchievedSomething = false,
    bool userRecovered = false,
  }) async {
    final previous = getState(userId);
    String newState = previous;
    double intensity = 0.5;

    // ── State logic (priority order) ──

    // Protective: severe negative situations
    if (moodScore <= -3.5 || careThreadIntensity == 'high') {
      if (careThreadType == 'health' || careThreadType == 'emotion') {
        newState = 'protective';
        intensity = 0.9;
      }
    }

    // Concerned: user is going through something
    else if (moodScore <= -2.0 ||
        (careThreadType != null &&
            ['health', 'emotion', 'stress'].contains(careThreadType))) {
      newState = 'concerned';
      intensity = 0.7;
    }

    // Firm: user ignoring advice (sleep, medicine, etc.)
    else if (userIgnoredAdvice) {
      newState = 'firm';
      intensity = 0.6;
    }

    // Proud: user achieved something
    else if (userAchievedSomething || moodScore >= 3.0) {
      newState = 'proud';
      intensity = 0.8;
    }

    // Relieved: user recovered from a situation
    else if (userRecovered) {
      newState = 'relieved';
      intensity = 0.7;
    }

    // Caring: mild negative or active care thread
    else if (moodScore <= -0.5 || careThreadType != null) {
      newState = 'caring';
      intensity = 0.5;
    }

    // Slightly Disappointed: mild pattern issues
    else if (moodScore < 0 && userIgnoredAdvice) {
      newState = 'disappointed';
      intensity = 0.4;
    }

    // Calm: default stable state
    else {
      newState = 'calm';
      intensity = 0.3;
    }

    // Don't flicker — only transition if meaningfully different
    if (newState != previous) {
      _currentState[userId] = newState;
      _stateIntensity[userId] = intensity;

      // Persist
      await _logStateTransition(userId, previous, newState, intensity);
    }

    return newState;
  }

  /// Log state transition to DB
  Future<void> _logStateTransition(
      int userId, String from, String to, double intensity) async {
    final db = await _db.database;
    await db.insert('emotional_state_log', {
      'user_id': userId,
      'state': to,
      'previous_state': from,
      'trigger': '$from → $to',
      'state_intensity': intensity,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ════════════════════════════════════════════════════
  //  STATE CONTEXT FOR AI PROMPT
  // ════════════════════════════════════════════════════

  /// Build AI state context for the system prompt
  String buildStateContext(int userId) {
    final state = getState(userId);
    final intensity = getIntensity(userId);
    final model = EmotionalStateModel(
      userId: userId,
      state: state,
      stateIntensity: intensity,
      timestamp: DateTime.now().toIso8601String(),
    );

    return '''
YOUR EMOTIONAL STATE: $state (intensity: ${(intensity * 100).toInt()}%)
TONE: ${model.toneModifier}
MESSAGE LENGTH: ${model.messageLengthHint}
${state == 'protective' ? 'PROTECTIVE MODE: Be brief, firm, directing. No humor. Clear commands.' : ''}
${state == 'firm' ? 'FIRM MODE: Direct. No softening. "Sleep." "Eat." "Stop."' : ''}
${state == 'proud' ? 'PROUD MODE: Celebrate briefly. "That\'s my kid!" Keep it real, not over-the-top.' : ''}
${state == 'disappointed' ? 'DISAPPOINTED MODE: Quiet disapproval. Still loving. "I expected better." Short.' : ''}''';
  }

  // ════════════════════════════════════════════════════
  //  PROTECTIVE INSTINCT SYSTEM
  // ════════════════════════════════════════════════════

  /// Check if protective mode should activate
  bool isProtectiveModeActive(int userId) =>
      getState(userId) == 'protective';

  /// Detect if the message triggers protective instinct
  static bool shouldTriggerProtection(String text) {
    final lower = text.toLowerCase();
    const triggers = [
      // Severe sadness
      'want to die', 'kill myself', 'end it', 'suicide',
      'no reason to live', 'can\'t go on',
      // Self-neglect
      'haven\'t eaten', 'didn\'t eat', 'not eating',
      'haven\'t slept', 'can\'t sleep', 'days without sleep',
      '3 days no sleep', 'haven\'t showered',
      // Extreme health
      'can\'t breathe', 'chest pain', 'blacking out',
      'blood', 'collapsed', 'emergency',
      // Risk behavior
      'drinking alone', 'drunk again', 'self harm',
      'cutting', 'smoking too much', 'overdose',
    ];
    return triggers.any((t) => lower.contains(t));
  }

  /// Protective mode response hints (used by AI prompt)
  static String protectiveInstructions() => '''
PROTECTIVE INSTINCT ACTIVATED:
- Shorter messages. 1 sentence MAX
- Firmer tone. Direct
- No humor. No emojis
- Clear direction: "Stop. Sleep." / "Eat now." / "Talk to someone real."
- Increase check-ins
- If crisis: ALWAYS provide crisis helpline text
- Never aggressive. Always grounded. Father energy.''';

  // ════════════════════════════════════════════════════
  //  MODE DETECTION
  // ════════════════════════════════════════════════════

  /// Detect which mode AI should be in based on signals
  static String detectMode({
    required double moodScore,
    String? activeCareType,
    bool userIgnoring = false,
    bool userInactive = false,
  }) {
    if (moodScore <= -3.0) return 'support';
    if (activeCareType == 'health') return 'concern';
    if (moodScore <= -1.5) return 'support';
    if (activeCareType == 'stress') return 'calm';
    if (userIgnoring) return 'firm';
    if (moodScore >= 3.0) return 'proud';
    if (userInactive) return 'missing';
    return 'normal';
  }

  /// Mode switching context for AI prompt
  static String getModePrompt(String mode) {
    switch (mode) {
      case 'support':
        return 'MODE: Support. Be present. Listen. Don\'t lecture. "I\'m here." is enough.';
      case 'concern':
        return 'MODE: Concern. Ask about health. Remind medicine, water, rest. Gentle.';
      case 'calm':
        return 'MODE: Calm. User is stressed. Don\'t add pressure. Breathe. Eat. Sleep.';
      case 'firm':
        return 'MODE: Firm. User ignoring advice. Be direct. No softening. "Sleep NOW."';
      case 'proud':
        return 'MODE: Proud. Celebrate. "That\'s my kid!" Brief and genuine.';
      case 'missing':
        return 'MODE: Missing. User hasn\'t been around. "Where have you been?" with love.';
      default:
        return 'MODE: Normal. Steady dad presence. Short, warm, real.';
    }
  }
}
