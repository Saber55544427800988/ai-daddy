import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-Speech service — works on both mobile and web.
/// On web it uses the Web Speech API via flutter_tts.
class TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(kIsWeb ? 0.9 : 0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() {
      _isSpeaking = true;
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
    });

    _isInitialized = true;
  }

  bool get isSpeaking => _isSpeaking;

  /// Speak text with personality-aware voice settings
  Future<void> speak(String text, {String personality = 'caring'}) async {
    try {
      await init();
      await _applyPersonalityVoice(personality);
      await _tts.speak(text);
    } catch (e) {
      // TTS may fail on some platforms — don't crash
      debugPrint('TTS error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (_) {}
  }

  Future<void> _applyPersonalityVoice(String personality) async {
    // Web uses different rate scale (0.1-10, default 1.0)
    // Mobile uses (0.0-1.0, default 0.5)
    const isWeb = kIsWeb;
    switch (personality.toLowerCase()) {
      case 'caring':
        await _tts.setSpeechRate(isWeb ? 0.85 : 0.45);
        await _tts.setPitch(1.0);
        break;
      case 'strict':
        await _tts.setSpeechRate(isWeb ? 0.9 : 0.5);
        await _tts.setPitch(0.9);
        break;
      case 'playful':
        await _tts.setSpeechRate(isWeb ? 1.0 : 0.55);
        await _tts.setPitch(1.15);
        break;
      case 'motivational':
        await _tts.setSpeechRate(isWeb ? 0.95 : 0.5);
        await _tts.setPitch(1.05);
        break;
      default:
        await _tts.setSpeechRate(isWeb ? 0.9 : 0.5);
        await _tts.setPitch(1.0);
    }
  }

  /// Adjust voice based on self-learning parameters
  Future<void> setCustomVoice({double? speed, double? pitch}) async {
    await init();
    if (speed != null) await _tts.setSpeechRate(speed);
    if (pitch != null) await _tts.setPitch(pitch);
  }

  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
