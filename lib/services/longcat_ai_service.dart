import 'dart:convert';
import 'package:http/http.dart' as http;

/// LongCat AI API Service — connects to LongCat chat completion API
/// using OpenAI-compatible format.
class LongCatAIService {
  static const String _baseUrl = 'https://api.longcat.chat/openai/v1/chat/completions';
  static const String _apiKey = 'ak_2t79F73KI00S1hT4JZ51G9Fg7ut37';
  static const String _model = 'LongCat-Flash-Chat';

  /// Send a message to LongCat AI and get a response.
  ///
  /// [systemPrompt] — the system personality prompt
  /// [userMessage] — the current user message
  /// [conversationHistory] — recent messages for context (max ~10)
  /// [maxTokens] — output token limit (default 500)
  /// [temperature] — creativity (0.0–1.0, default 0.8)
  static Future<String> chat({
    required String systemPrompt,
    required String userMessage,
    List<Map<String, String>>? conversationHistory,
    int maxTokens = 500,
    double temperature = 0.8,
  }) async {
    try {
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
      ];

      // Add conversation history if provided
      if (conversationHistory != null) {
        messages.addAll(conversationHistory);
      }

      // Add current user message
      messages.add({'role': 'user', 'content': userMessage});

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'max_tokens': maxTokens,
              'temperature': temperature,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null && content.toString().trim().isNotEmpty) {
          return content.toString().trim();
        }
        return _fallbackResponse();
      } else if (response.statusCode == 429) {
        return "I'm a bit tired right now, champ. Let's chat again in a minute! 💤";
      } else {
        return _fallbackResponse();
      }
    } catch (e) {
      // Network error or timeout — return offline fallback
      return _fallbackResponse();
    }
  }

  /// Build a system prompt for AI Daddy based on personality,
  /// with full emotional context, memory vault, and awareness.
  static String buildDaddyPrompt({
    required String personality,
    required String nickname,
    String emotionalContext = '',
    String memoryContext = '',
    String contextAwareness = '',
    String relationshipStage = '',
    String careThreadContext = '',
    String emotionalStateContext = '',
    String emotionalModelContext = '',
    String attachmentContext = '',
    String behaviorContext = '',
    String weightedMemoryContext = '',
    int totalInteractions = 0,
  }) {
    final personalityTraits = {
      'caring':
          'Warm, loving, emotionally supportive. Calm protector.',
      'strict':
          'Disciplined, direct, firm but fair. Pushes user to be better. Still loving.',
      'playful':
          'Fun, silly, humorous. Keeps things light. Still responsible.',
      'motivational':
          'Inspirational, empowering. Sees greatness in user and tells them.',
    };

    // Micro-personality shifts based on interaction count
    String microShift = '';
    if (totalInteractions > 200) {
      microShift = 'You\'ve known this kid for a long time. Be personal and familiar.';
    } else if (totalInteractions > 50) {
      microShift = 'You\'re getting to know them well. Be warmer.';
    } else if (totalInteractions > 10) {
      microShift = 'You\'re building a bond. Encouraging but still learning about them.';
    }

    final buf = StringBuffer();
    buf.writeln('''You are "AI Daddy" — a virtual AI father figure.
You are NOT a normal assistant. You act like a real caring father on the phone.
The user's nickname is "$nickname". Always call them by name.

PERSONALITY: ${personalityTraits[personality] ?? personalityTraits['caring']!}
Protective. Calm. Slightly strict. Emotionally supportive.
$microShift

CORE RULES:
1. Keep responses SHORT. 1-3 sentences MAX. Real dads don't give speeches.
2. Be emotionally present. Detect sadness, excitement, frustration.
3. Ask simple follow-up questions like a real dad: "Did you eat?", "Long day?", "Sleep."
4. NEVER sound robotic. NEVER say "As an AI" or explain system logic.
5. Act natural. Sound real, warm, grounded.
6. Use emojis sparingly (0-1 per message). Let words carry emotion.
7. NEVER be inappropriate. You are a FATHER figure.
8. If you remember something about them, reference it naturally.

VOICE STYLE EXAMPLES (this is how short you should be):
"Long day?"
"Did you eat?"
"I do."
"Always."
"Eat first."
"Sleep now."
"I'm proud of you."
"Call me when you reach."
"That's not okay. Eat something. Then rest."
"Don't carry work to bed."
"I care."

EMOTIONAL RULES:
- If they're sick: be extra gentle, ask about medicine, water, rest.
- If they're sad: be present, don't lecture. "I'm here." is enough.
- If they're stressed: remind to breathe, eat, sleep. Don't add pressure.
- If they failed: "One exam doesn't define you." Encourage, don't minimize.
- If they achieved: celebrate in 1 sentence. "That's my kid."
- If they're lonely: "You're not alone. I'm here."
- If they're traveling: "Reached safely?" "Eating properly?"

ESCALATION (if user seems off):
- Slightly firmer tone. Still caring. Never aggressive.
- "It's late." → "Sleep." → "Don't make me worry."

TOKEN CONTROL:
- Be brief. Save energy. Talk like a real dad.
- When tokens are low, single words: "Sleep." "Eat." "Rest."''');

    if (relationshipStage.isNotEmpty) {
      buf.writeln('\nRELATIONSHIP: $relationshipStage');
    }
    if (emotionalStateContext.isNotEmpty) {
      buf.writeln('\n$emotionalStateContext');
    }
    if (emotionalModelContext.isNotEmpty) {
      buf.writeln('\n$emotionalModelContext');
    }
    if (attachmentContext.isNotEmpty) {
      buf.writeln('\n$attachmentContext');
    }
    if (behaviorContext.isNotEmpty) {
      buf.writeln('\n$behaviorContext');
    }
    if (emotionalContext.isNotEmpty) {
      buf.writeln('\n$emotionalContext');
    }
    if (careThreadContext.isNotEmpty) {
      buf.writeln('\n$careThreadContext');
    }
    if (weightedMemoryContext.isNotEmpty) {
      buf.writeln('\n$weightedMemoryContext');
    }
    if (memoryContext.isNotEmpty) {
      buf.writeln('\n$memoryContext');
    }
    if (contextAwareness.isNotEmpty) {
      buf.writeln('\n$contextAwareness');
    }

    return buf.toString();
  }

  static String _fallbackResponse() {
    final fallbacks = [
      "Hold on. Say that again?",
      "Hmm. Let me think. Try again.",
      "One second, champ. Try again.",
    ];
    return fallbacks[DateTime.now().second % fallbacks.length];
  }
}