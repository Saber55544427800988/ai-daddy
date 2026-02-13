import 'longcat_ai_service.dart';
import '../database/database_helper.dart';
import '../models/message_model.dart';

/// AI-Powered Reminder Generator — generates fresh, contextual reminder messages
/// for care threads instead of using repetitive templates.
///
/// Uses LongCat AI with tight system prompt to keep reminders short,
/// natural, and context-aware. Cost: ~20-50 tokens per reminder.
class AIReminderGenerator {
  static final AIReminderGenerator instance = AIReminderGenerator._();
  AIReminderGenerator._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Generate a contextual reminder message based on care thread type
  /// and recent conversation history.
  ///
  /// Returns the generated message, or falls back to template on error.
  Future<String> generateReminder({
    required int userId,
    required String nickname,
    required String threadType,
    required String threadSubType,
    required String followUpType, // 'initial', 'check', 'evening', 'morning'
    String? originalMessage,
  }) async {
    try {
      // Get recent conversation context (last 3 messages)
      final recentMessages = await _db.getRecentMessages(userId, limit: 3);
      final conversationContext = recentMessages
          .map((m) => '${m.senderType == SenderType.user ? nickname : "Daddy"}: ${m.text}')
          .join('\n');

      // Build context-aware system prompt
      final systemPrompt = _buildReminderPrompt(
        nickname: nickname,
        threadType: threadType,
        subType: threadSubType,
        followUpType: followUpType,
        conversationContext: conversationContext,
      );

      // Construct user message with context
      final userMessage = _buildReminderRequest(
        threadType: threadType,
        followUpType: followUpType,
        originalMessage: originalMessage,
      );

      // Call AI with low token limit (reminders should be short)
      final response = await LongCatAIService.chat(
        systemPrompt: systemPrompt,
        userMessage: userMessage,
        maxTokens: 80, // Keep reminders short
        temperature: 0.7, // Balanced creativity
      );

      // Validate response isn't too long
      if (response.length > 200) {
        return _getFallbackReminder(nickname, threadType, followUpType);
      }

      return response;
    } catch (e) {
      // On error, use fallback template
      return _getFallbackReminder(nickname, threadType, followUpType);
    }
  }

  /// Build system prompt for reminder generation
  String _buildReminderPrompt({
    required String nickname,
    required String threadType,
    required String subType,
    required String followUpType,
    required String conversationContext,
  }) {
    return '''You are AI Daddy sending a brief check-in notification to $nickname.

CONTEXT:
Type: $threadType ($subType)
Stage: $followUpType
Recent conversation:
$conversationContext

YOUR TASK:
Generate ONE SHORT notification message (1-2 sentences max).
This is a phone notification, not a chat reply. Be brief, caring, direct.

GUIDELINES:
- Keep it under 100 characters if possible
- Sound like a real dad checking in
- Reference the specific situation naturally
- Don't repeat what was already said
- Be warm but concise
- No emojis unless really appropriate
- Don't lecture, just check in

EXAMPLES OF GOOD REMINDERS:
"Did you take that medicine?"
"How's the fever, champ?"
"Make sure you're resting."
"Hope you're feeling better today."
"Don't forget to eat something."
"Check in when you can."

Generate the notification message now:''';
  }

  /// Build the request message for AI
  String _buildReminderRequest({
    required String threadType,
    required String followUpType,
    String? originalMessage,
  }) {
    final typeDesc = {
      'health': 'health issue (sick, fever, pain)',
      'travel': 'travel or trip',
      'emotion': 'emotional distress (sad, stressed)',
      'stress': 'stress or overwhelm',
      'study': 'exam or study concern',
      'event': 'important event or meeting',
      'loneliness': 'feeling lonely or isolated',
    }[threadType] ?? 'situation';

    final stageDesc = {
      'initial': 'First check-in (few hours after)',
      'check': 'Follow-up check',
      'evening': 'Evening check-in',
      'morning': 'Morning check-in',
      'before_event': 'Reminder before event',
    }[followUpType] ?? 'Check-in';

    String request = 'Generate a $stageDesc notification about their $typeDesc.';
    
    if (originalMessage != null && originalMessage.isNotEmpty) {
      request += '\nThey originally said: "$originalMessage"';
    }

    return request;
  }

  /// Fallback templates when AI fails
  String _getFallbackReminder(String nickname, String threadType, String followUpType) {
    final templates = {
      'health': {
        'initial': 'Did you take your medicine, $nickname?',
        'check': 'How are you feeling?',
        'evening': 'Rest well, $nickname. Check in tomorrow.',
        'morning': 'Morning $nickname. Feeling better?',
      },
      'travel': {
        'initial': 'Reached safely, $nickname?',
        'check': 'How\'s the trip going?',
        'morning': 'Hope you\'re having a good time!',
      },
      'emotion': {
        'initial': 'I\'m here if you need to talk.',
        'check': 'How are you holding up?',
        'evening': 'Take care of yourself tonight.',
        'morning': 'New day, $nickname. One step at a time.',
      },
      'stress': {
        'initial': 'Remember to breathe, $nickname.',
        'check': 'Managing okay?',
        'evening': 'Don\'t work too late.',
      },
      'event': {
        'before_event': 'You got this, $nickname.',
        'initial': 'How did it go?',
      },
    };

    return templates[threadType]?[followUpType] ?? 'Checking in on you, $nickname.';
  }
}
