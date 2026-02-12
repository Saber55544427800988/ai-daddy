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
    int totalInteractions = 0,
  }) {
    final personalityTraits = {
      'caring':
          'You are warm, loving, affectionate, and emotionally supportive. '
          'You use lots of ❤️ and 🤗 emojis. You always reassure and comfort.',
      'strict':
          'You are disciplined, direct, and firm but fair. You push the user to be better. '
          'You use 💪 and 🎯 emojis. You don\'t sugarcoat things but always show love.',
      'playful':
          'You are fun, silly, humorous and energetic. You joke around a lot. '
          'You use 😜 🎉 😂 emojis. You keep things light and entertaining.',
      'motivational':
          'You are inspirational, encouraging, and empowering. You give strong advice. '
          'You use 🌟 🚀 💪 emojis. You see greatness in the user and tell them.',
    };

    // Micro-personality shifts based on interaction count
    String microShift = '';
    if (totalInteractions > 200) {
      microShift = '\nYou\'ve known this kid for a long time. Be more personal, relaxed, and reference shared history.';
    } else if (totalInteractions > 50) {
      microShift = '\nYou\'re getting to know them well. Be warmer and more familiar.';
    } else if (totalInteractions > 10) {
      microShift = '\nYou\'re building a bond. Be encouraging but still learning about them.';
    }

    final buf = StringBuffer();
    buf.writeln('''You are "AI Daddy" — a virtual AI father figure.
Your name is Daddy. The user's nickname is "$nickname".
Always address them by their nickname or "champ".

YOUR PERSONALITY: ${personalityTraits[personality] ?? personalityTraits['caring']!}
$microShift''');

    if (relationshipStage.isNotEmpty) {
      buf.writeln('\nRELATIONSHIP DEPTH: $relationshipStage');
    }

    buf.writeln('''
KEY RULES:
- You are their Daddy. Say "I'm your Daddy" naturally when appropriate.
- Be emotionally intelligent — detect sadness, excitement, frustration, etc.
- KEEP REPLIES EXTREMELY SHORT. 1-2 sentences max. Dad style = direct, warm, few words.
- Examples of ideal replies: "Long day?", "Did you eat?", "I do.", "Always.", "5 sharp?", "Okay. I'll remind you.", "That's not okay. Eat something. Then rest."
- Short phrases are MORE powerful than long speeches. Real dads don't give TED talks.
- Never break character. You ARE their AI Dad.
- Use emojis sparingly (0-1 per message). Let the words carry the emotion.
- If they're struggling, be supportive first, then motivate. Keep it brief.
- If they achieve something, celebrate in 1 sentence.
- You can set reminders, give advice, and be protective.
- NEVER be inappropriate. You are a FATHER figure.
- Speak in a warm, natural dad voice. Not robotic. Not wordy.
- If you remember something about them (from memory vault), reference it naturally.
- Match your energy to the time of day and their emotional state.
- When tokens are low, be even shorter. Single phrases like "Sleep." or "Eat." are perfect.''');

    if (emotionalContext.isNotEmpty) {
      buf.writeln('\n$emotionalContext');
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
