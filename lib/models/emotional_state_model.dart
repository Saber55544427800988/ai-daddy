/// AI Daddy's Internal Emotional State Model.
///
/// Tracks the AI's own emotional state — NOT the user's mood.
/// The AI's state changes based on what the user is going through
/// and influences tone, message length, and reminder intensity.
class EmotionalStateModel {
  final int? id;
  final int userId;
  final String state; // calm, caring, concerned, protective, firm, proud, relieved, disappointed
  final String previousState;
  final String trigger; // what caused the transition
  final double stateIntensity; // 0.0–1.0 how strong the state is
  final String timestamp;

  EmotionalStateModel({
    this.id,
    required this.userId,
    required this.state,
    this.previousState = 'calm',
    this.trigger = '',
    this.stateIntensity = 0.5,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'state': state,
        'previous_state': previousState,
        'trigger': trigger,
        'state_intensity': stateIntensity,
        'timestamp': timestamp,
      };

  factory EmotionalStateModel.fromMap(Map<String, dynamic> m) =>
      EmotionalStateModel(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        state: m['state'] as String,
        previousState: (m['previous_state'] as String?) ?? 'calm',
        trigger: (m['trigger'] as String?) ?? '',
        stateIntensity: (m['state_intensity'] as num?)?.toDouble() ?? 0.5,
        timestamp: m['timestamp'] as String,
      );

  /// State affects tone
  String get toneModifier {
    switch (state) {
      case 'calm':
        return 'relaxed, steady';
      case 'caring':
        return 'warm, gentle';
      case 'concerned':
        return 'worried, attentive';
      case 'protective':
        return 'firm but loving, urgent';
      case 'firm':
        return 'direct, no-nonsense';
      case 'proud':
        return 'excited, celebratory';
      case 'relieved':
        return 'lighter, happy';
      case 'disappointed':
        return 'quiet, slightly stern but still loving';
      default:
        return 'steady';
    }
  }

  /// State affects message length
  String get messageLengthHint {
    switch (state) {
      case 'protective':
      case 'firm':
        return 'very_short'; // 1 sentence, commands
      case 'concerned':
      case 'caring':
        return 'short'; // 1-2 sentences
      case 'proud':
      case 'relieved':
        return 'short'; // 1-2 celebratory
      case 'disappointed':
        return 'very_short'; // brief, pointed
      default:
        return 'short';
    }
  }

  /// State affects reminder intensity
  double get reminderMultiplier {
    switch (state) {
      case 'protective':
        return 1.5;
      case 'concerned':
        return 1.3;
      case 'firm':
        return 1.2;
      case 'caring':
        return 1.0;
      case 'calm':
        return 0.8;
      case 'proud':
      case 'relieved':
        return 0.5;
      default:
        return 1.0;
    }
  }
}
