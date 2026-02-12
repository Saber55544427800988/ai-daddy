import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/message_model.dart';
import '../models/smart_reminder_model.dart';
import '../models/ai_token_model.dart';
import '../models/user_model.dart';
import '../models/user_profile_model.dart';
import '../models/dad_report_model.dart';
import '../services/ai_engine.dart';
import '../services/longcat_ai_service.dart';
import '../services/tts_service.dart';
import '../services/self_learning_service.dart';
import '../services/emotional_intelligence_service.dart';
import '../services/context_awareness_service.dart';
import '../services/memory_extraction_service.dart';
import '../services/dad_report_service.dart';
import '../services/daddy_lifecycle_service.dart';

class ChatProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final AIEngine _aiEngine = AIEngine();
  final TTSService _ttsService = TTSService();
  final SelfLearningService _learning = SelfLearningService();
  final DaddyLifecycleService _lifecycle = DaddyLifecycleService.instance;

  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _autoReadEnabled = true;
  bool _privacyMode = false;
  UserModel? _currentUser;
  AITokenModel? _tokens;
  String _personality = 'caring';
  UserProfileModel? _learnedProfile;
  int _totalInteractions = 0;

  /// Timestamp of last user message (for response-time tracking)
  DateTime? _lastUserMessageTime;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get autoReadEnabled => _autoReadEnabled;
  bool get privacyMode => _privacyMode;
  UserModel? get currentUser => _currentUser;
  AITokenModel? get tokens => _tokens;
  String get personality => _personality;
  UserProfileModel? get learnedProfile => _learnedProfile;
  int get totalInteractions => _totalInteractions;

  /// Initialize chat for user
  Future<void> init(int userId) async {
    // Load persisted settings
    final prefs = await SharedPreferences.getInstance();
    _autoReadEnabled = prefs.getBool('auto_read_enabled') ?? true;

    _currentUser = await _db.getUser(userId);
    if (_currentUser != null) {
      _personality = _currentUser!.dadPersonality;
      await _db.resetTokensIfNeeded(userId);
      _tokens = await _db.getTokens(userId);
      _learnedProfile = await _db.getUserProfile(userId);
      _totalInteractions = await _db.getTotalInteractions(userId);
      await loadMessages(userId);

      // Check if weekly report is due
      _checkWeeklyReport(userId);

      // ── Lifecycle: record app open, setup daily schedule, check inactivity ──
      _lifecycle.recordAppOpen(userId);
      if (!kIsWeb) {
        _lifecycle.setupDailySchedule(userId, _currentUser!.nickname);
        _lifecycle.checkInactivityAndNotify(userId, _currentUser!.nickname);
        _lifecycle.analyzeBehaviorPatterns(userId);
      }
    }
    notifyListeners();
  }

  /// Check and generate weekly report if needed
  Future<void> _checkWeeklyReport(int userId) async {
    try {
      if (await DadReportService.shouldGenerateReport(userId)) {
        await DadReportService.generateReport(
            userId, _currentUser!.nickname);
      }
    } catch (_) {
      // Non-critical, don't crash
    }
  }

  void setPrivacyMode(bool value) {
    _privacyMode = value;
    notifyListeners();
  }

  Future<void> loadMessages(int userId) async {
    _messages = await _db.getMessages(userId);
    notifyListeners();
  }

  /// Send a user message and get AI response
  Future<void> sendMessage(String text) async {
    if (_currentUser == null || text.trim().isEmpty) return;

    final userId = _currentUser!.id!;
    final now = DateTime.now();

    // ── Retroactive reinforcement: mark previous AI turn as "replied" ──
    final sentiment = _learning.sentimentScore(text);
    await _learning.recordReply(userId, sentiment >= 0);

    // Track response time (seconds since last user message)
    final responseTimeSec = _lastUserMessageTime != null
        ? now.difference(_lastUserMessageTime!).inMilliseconds / 1000.0
        : 0.0;
    _lastUserMessageTime = now;

    // ── Emotional Intelligence: analyze mood ──
    final moodAnalysis = EmotionalIntelligenceService.analyzeMood(text);

    // ── Crisis Detection ──
    if (moodAnalysis.isCrisis) {
      final crisisResponse =
          EmotionalIntelligenceService.getCrisisResponse(_currentUser!.nickname);
      final crisisMsg = MessageModel(
        userId: userId,
        text: crisisResponse,
        senderType: SenderType.ai,
        timestamp: DateTime.now().toIso8601String(),
        engagementScore: 1.0,
      );
      // Save user message first
      final userMsg = MessageModel(
        userId: userId,
        text: text.trim(),
        senderType: SenderType.user,
        timestamp: now.toIso8601String(),
      );
      await _db.insertMessage(userMsg);
      _messages.add(userMsg);
      await _db.insertMessage(crisisMsg);
      _messages.add(crisisMsg);
      await EmotionalIntelligenceService.recordMoodFromChat(
          userId, moodAnalysis.score);
      notifyListeners();
      if (_autoReadEnabled) {
        await _ttsService.speak(crisisResponse, personality: 'caring');
      }
      return;
    }

    // ── Record mood from chat ──
    await EmotionalIntelligenceService.recordMoodFromChat(
        userId, moodAnalysis.score);

    // ── Memory Extraction (non-blocking) ──
    if (!_privacyMode) {
      MemoryExtractionService.extractAndStore(userId, text);
    }

    // Create user message
    final userMsg = MessageModel(
      userId: userId,
      text: text.trim(),
      senderType: SenderType.user,
      timestamp: now.toIso8601String(),
      engagementScore: 1.0,
    );

    await _db.insertMessage(userMsg);
    _messages.add(userMsg);
    notifyListeners();

    // Check for smart reminders
    final smartReminder = _aiEngine.detectSmartReminder(text);
    if (smartReminder != null) {
      await _handleSmartReminder(userId, smartReminder);
      return; // Don't generate a second AI response after reminder
    }

    // Check token budget — accurate estimation based on message length
    _tokens = await _db.getTokens(userId);
    final estimatedCost =
        text.length < 30 ? 10 : (text.length < 80 ? 30 : (text.length < 150 ? 60 : 100));

    if (_tokens != null && !_tokens!.canSpend(estimatedCost)) {
      final lowTokenMsg = MessageModel(
        userId: userId,
        text:
            "Let's talk more tomorrow, ${_currentUser!.nickname}. Daddy's tired. ❤️",
        senderType: SenderType.ai,
        timestamp: DateTime.now().toIso8601String(),
      );
      await _db.insertMessage(lowTokenMsg);
      _messages.add(lowTokenMsg);
      notifyListeners();
      return;
    }

    // Soft limit: warn when below 500 tokens (still reply but shorter)
    final bool softLimit = _tokens != null && _tokens!.remainingTokens < 500;

    // Generate AI response — use LongCat AI API with offline fallback
    _isLoading = true;
    notifyListeners();

    // Refresh learned profile before generation
    _learnedProfile = await _db.getUserProfile(userId);
    _totalInteractions = await _db.getTotalInteractions(userId);

    final recentMessages = await _db.getRecentMessages(userId, limit: 5);

    // Build conversation history for LongCat API
    final history = recentMessages.map((m) {
      return {
        'role': m.senderType == SenderType.user ? 'user' : 'assistant',
        'content': m.text,
      };
    }).toList();

    // ── Build enriched system prompt ──
    String emotionalCtx = '';
    String memoryCtx = '';
    try {
      emotionalCtx =
          await EmotionalIntelligenceService.buildEmotionalContext(userId);
      if (!_privacyMode) {
        memoryCtx =
            await MemoryExtractionService.buildMemoryPrompt(userId);
      }
    } catch (_) {}

    final contextCtx = ContextAwarenessService.buildContextPrompt();
    final relationshipStage =
        RelationshipStage.getStage(_totalInteractions);
    final stageLabel =
        '${relationshipStage['title']} (Level ${relationshipStage['level']})';

    // Try LongCat AI API first, fallback to offline engine
    String response;
    try {
      response = await LongCatAIService.chat(
        systemPrompt: LongCatAIService.buildDaddyPrompt(
          personality: _personality,
          nickname: _currentUser!.nickname,
          emotionalContext: emotionalCtx,
          memoryContext: memoryCtx,
          contextAwareness: contextCtx,
          relationshipStage: stageLabel,
          totalInteractions: _totalInteractions,
        ),
        userMessage: text,
        conversationHistory: history,
        maxTokens: softLimit ? 60 : (_tokens?.spendingMode == SpendingMode.slow ? 150 : 300),
        temperature: _personality == 'playful' ? 0.9 : 0.7,
      );
    } catch (_) {
      // Offline fallback
      response = _aiEngine.generateResponse(
        userMessage: text,
        personality: _personality,
        nickname: _currentUser!.nickname,
        recentMessages: recentMessages,
        tokens: _tokens,
        learnedProfile: _learnedProfile,
      );
    }

    // ── Sleep Mode: soften response ──
    if (ContextAwarenessService.isSleepTime()) {
      response = _applySleepMode(response);
    }

    // ── Late-night escalation: schedule sleep reminders (0 tokens) ──
    if (ContextAwarenessService.isLateNight() && !kIsWeb) {
      final now = DateTime.now();
      if (now.hour >= 23 || now.hour < 3) {
        _lifecycle.scheduleLateNightEscalation(
          _currentUser!.nickname,
          now,
        );
      }
    }

    // Engagement score for this interaction
    final engScore = _learning.calculateEngagement(
      responseTimeSeconds: responseTimeSec,
      messageLength: text.length,
      isPositive: _learning.isPositiveSentiment(text),
    );

    final aiMsg = MessageModel(
      userId: userId,
      text: response,
      senderType: SenderType.ai,
      timestamp: DateTime.now().toIso8601String(),
      engagementScore: engScore,
    );

    await _db.insertMessage(aiMsg);
    _messages.add(aiMsg);

    // Spend tokens
    if (_tokens != null) {
      await _db.spendTokens(userId, estimatedCost);
      _tokens = await _db.getTokens(userId);
    }

    _isLoading = false;
    notifyListeners();

    // ── Surprise moment (5% chance) ──
    final surprise = DadReportService.generateSurpriseMoment(
        _currentUser!.nickname, _totalInteractions);
    if (surprise != null) {
      await Future.delayed(const Duration(seconds: 2));
      final surpriseMsg = MessageModel(
        userId: userId,
        text: surprise,
        senderType: SenderType.ai,
        timestamp: DateTime.now().toIso8601String(),
      );
      await _db.insertMessage(surpriseMsg);
      _messages.add(surpriseMsg);
      notifyListeners();
    }

    // ── Record interaction for self-learning ──
    final detectedIntent = _aiEngine.detectIntent(text.toLowerCase().trim());
    await _learning.recordInteraction(
      userId: userId,
      toneUsed: _learnedProfile?.bestTone ?? _personality,
      intentDetected: detectedIntent,
      userMessageLength: text.length,
      responseTimeSeconds: responseTimeSec,
      sentimentScore: sentiment,
      engagementScore: engScore,
    );

    // Quick reinforcement update (every message)
    await _learning.quickUpdate(userId);

    // Auto-read response
    if (_autoReadEnabled) {
      await _ttsService.speak(response, personality: _personality);
    }

    // Deep analysis every 10 messages
    final msgCount = await _db.getMessageCount(userId, days: 1);
    if (msgCount % 10 == 0) {
      await _learning.analyzeAndAdapt(userId);
      _learnedProfile = await _db.getUserProfile(userId);
    }
  }

  /// Apply sleep mode — softens responses at night
  String _applySleepMode(String response) {
    // Shorten if too long for nighttime
    if (response.length > 200) {
      final sentences = response.split(RegExp(r'[.!?]+'));
      if (sentences.length > 2) {
        response = '${sentences.take(2).join('. ').trim()}. 🌙';
      }
    }
    return response;
  }

  Future<void> _handleSmartReminder(
      int userId, SmartReminderParsed parsed) async {
    // Check token budget for reminder
    if (_tokens == null || !_tokens!.canSpend(SmartReminderModel.tokenCost)) {
      final noTokenMsg = MessageModel(
        userId: userId,
        text:
            "I noticed a reminder in your message, ${_currentUser!.nickname}, "
            "but I don't have enough tokens to set it up right now. "
            "We'll get more tomorrow! ❤️",
        senderType: SenderType.ai,
        timestamp: DateTime.now().toIso8601String(),
      );
      await _db.insertMessage(noTokenMsg);
      _messages.add(noTokenMsg);
      notifyListeners();
      return;
    }

    // Spend tokens for smart reminder
    await _db.spendTokens(userId, SmartReminderModel.tokenCost);
    _tokens = await _db.getTokens(userId);

    // Store smart reminder
    final reminder = SmartReminderModel(
      userId: userId,
      text: parsed.originalText,
      scheduledTime: parsed.scheduledTime.toIso8601String(),
      eventType: parsed.eventType,
    );
    final reminderId = await _db.insertSmartReminder(reminder);

    // Schedule notification (mobile only)
    if (!kIsWeb) {
      // Double reminder: 30min + 5min before the event
      await _lifecycle.scheduleDoubleReminder(
        baseId: 500 + reminderId * 10,
        nickname: _currentUser!.nickname,
        eventDescription: parsed.originalText,
        eventTime: parsed.scheduledTime,
      );

      // If it's an exam/study event, also schedule multi-day reminders
      if (parsed.eventType == 'study') {
        await _lifecycle.scheduleExamReminders(
          baseId: 600 + reminderId * 10,
          nickname: _currentUser!.nickname,
          examDescription: parsed.originalText,
          examTime: parsed.scheduledTime,
        );
      }
    }

    // Build a dad-like confirmation message
    final nickname = _currentUser!.nickname;
    final timeStr = _formatTime(parsed.scheduledTime);
    final isTomorrow =
        parsed.scheduledTime.day != DateTime.now().day;
    final dayStr = isTomorrow ? 'tomorrow' : 'today';

    final confirmTexts = <String>[
      "Got it. I'll remind you at $timeStr.",
      "Done, $nickname. $timeStr. I won't forget.",
      "Noted. $timeStr $dayStr. Daddy's on it.",
      "You got it. $timeStr. I'll be there.",
      "$timeStr. Consider it handled.",
    ];

    final confirmText =
        confirmTexts[DateTime.now().millisecond % confirmTexts.length];

    const costNote =
        '\n\n⚡ -${SmartReminderModel.tokenCost} tokens for smart reminder';

    final confirmMsg = MessageModel(
      userId: userId,
      text: '$confirmText$costNote',
      senderType: SenderType.ai,
      timestamp: DateTime.now().toIso8601String(),
    );
    await _db.insertMessage(confirmMsg);
    _messages.add(confirmMsg);
    notifyListeners();

    // Auto-read the confirmation aloud
    if (_autoReadEnabled) {
      await _ttsService.speak(confirmText, personality: _personality);
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  void toggleAutoRead() async {
    _autoReadEnabled = !_autoReadEnabled;
    if (!_autoReadEnabled) {
      _ttsService.stop();
    }
    // Persist the setting
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_read_enabled', _autoReadEnabled);
    notifyListeners();
  }

  /// Update personality without full re-init (called from Settings)
  void updatePersonality(String newPersonality) {
    _personality = newPersonality;
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    await _ttsService.stop();
  }

  Future<void> refreshTokens() async {
    if (_currentUser == null) return;
    await _db.resetTokensIfNeeded(_currentUser!.id!);
    _tokens = await _db.getTokens(_currentUser!.id!);
    notifyListeners();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
