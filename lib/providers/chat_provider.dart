import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/message_model.dart';
import '../models/smart_reminder_model.dart';
import '../models/ai_token_model.dart';
import '../models/user_model.dart';
import '../models/user_profile_model.dart';
import '../models/user_emotional_profile.dart';
import '../models/dad_report_model.dart';
import '../services/ai_engine.dart';
import '../services/longcat_ai_service.dart';
import '../services/self_learning_service.dart';
import '../services/emotional_intelligence_service.dart';
import '../services/context_awareness_service.dart';
import '../services/memory_extraction_service.dart';
import '../services/dad_report_service.dart';
import '../services/daddy_lifecycle_service.dart';
import '../services/situational_intelligence_service.dart';
import '../services/care_thread_engine.dart';
import '../services/emotional_state_engine.dart';
import '../services/user_emotional_model_service.dart';
import '../services/attachment_system.dart';
import '../services/memory_weight_system.dart';
import '../services/behavior_adaptation_engine.dart';

class ChatProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final AIEngine _aiEngine = AIEngine();
  final SelfLearningService _learning = SelfLearningService();
  final DaddyLifecycleService _lifecycle = DaddyLifecycleService.instance;
  final SituationalIntelligenceService _situational =
      SituationalIntelligenceService.instance;
  final CareThreadEngine _careEngine = CareThreadEngine.instance;
  final EmotionalStateEngine _emotionalState = EmotionalStateEngine.instance;
  final UserEmotionalModelService _emotionalModel =
      UserEmotionalModelService.instance;
  final AttachmentSystem _attachment = AttachmentSystem.instance;
  final MemoryWeightSystem _memoryWeights = MemoryWeightSystem.instance;
  final BehaviorAdaptationEngine _behaviorEngine =
      BehaviorAdaptationEngine.instance;

  List<MessageModel> _messages = [];
  bool _isLoading = false;
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
  bool get privacyMode => _privacyMode;
  UserModel? get currentUser => _currentUser;
  AITokenModel? get tokens => _tokens;
  String get personality => _personality;
  UserProfileModel? get learnedProfile => _learnedProfile;
  int get totalInteractions => _totalInteractions;

  /// Initialize chat for user
  Future<void> init(int userId) async {
    _currentUser = await _db.getUser(userId);
    if (_currentUser != null) {
      // Run database migrations for new tables
      await _db.runMigrations();
      _personality = _currentUser!.dadPersonality;
      // Token initialization is handled by TokenProvider
      _tokens = await _db.getTokens(userId);
      _learnedProfile = await _db.getUserProfile(userId);
      _totalInteractions = await _db.getTotalInteractions(userId);
      await loadMessages(userId);

      // Check if weekly report is due
      _checkWeeklyReport(userId);

      // ── Initialize emotional architecture ──
      await _emotionalState.loadState(userId);
      await _emotionalModel.getProfile(userId);
      await _attachment.getScore(userId);
      await _behaviorEngine.getStats(userId);

      // ── Lifecycle: record app open, setup daily schedule, check inactivity ──
      _lifecycle.recordAppOpen(userId).then((_) {}, onError: (_) {});
      _attachment.recordAppOpen(userId).then((_) {}, onError: (_) {});
      _lifecycle.setupDailySchedule(userId, _currentUser!.nickname).then((_) {}, onError: (_) {});
      _lifecycle.checkInactivityAndNotify(userId, _currentUser!.nickname).then((_) {}, onError: (_) {});
      _lifecycle.analyzeBehaviorPatterns(userId).then((_) {}, onError: (_) {});

      // ── Situational Intelligence: milestones, love notes ──
      _situational.initialize(
        userId: userId,
        nickname: _currentUser!.nickname,
        createdAt: _currentUser!.createdAt,
      ).then((_) {}, onError: (_) {});

      // ── Detect sleep pattern ──
      _emotionalModel.detectSleepPattern(userId).then((_) {}, onError: (_) {});
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
    final uid = _currentUser!.id;
    if (uid == null) return;
    final userId = uid;
    final now = DateTime.now();

    // ── Retroactive reinforcement: mark previous AI turn as "replied" ──
    final sentiment = _learning.sentimentScore(text);
    try { await _learning.recordReply(userId, sentiment >= 0); } catch (_) {}

    // Track response time (seconds since last user message)
    final responseTimeSec = _lastUserMessageTime != null
        ? now.difference(_lastUserMessageTime!).inMilliseconds / 1000.0
        : 0.0;
    _lastUserMessageTime = now;

    // ── Emotional Intelligence: analyze mood ──
    final moodAnalysis = EmotionalIntelligenceService.analyzeMood(text);

    // ── Advanced Emotional Architecture Updates ──
    UserEmotionalProfile? profile;
    try {
      // Update user emotional profile with sentiment
      profile = await _emotionalModel.updateMood(userId, sentiment);
      // Update attachment based on message
      await _attachment.processMessage(userId, text);
      // Update emotional openness
      await _emotionalModel.updateOpenness(userId, text);
      // Record message for behavior tracking
      await _behaviorEngine.recordMessage(userId, text, sentiment);
    } catch (e) {
      debugPrint('Emotional architecture update error: $e');
    }

    // ── Protective Instinct Detection ──
    try {
      if (EmotionalStateEngine.shouldTriggerProtection(text)) {
        await _emotionalState.transitionState(
          userId: userId,
          moodScore: profile?.currentMoodScore ?? 0.0,
          careThreadType: 'emotion',
          careThreadIntensity: 'high',
        );
      }
    } catch (_) {}

    // ── Crisis Detection ──
    if (moodAnalysis.isCrisis) {
      try {
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
      } catch (e) {
        debugPrint('Crisis handling error: $e');
      }
      return;
    }

    // ── Record mood from chat ──
    try {
      await EmotionalIntelligenceService.recordMoodFromChat(
          userId, moodAnalysis.score);
    } catch (_) {}

    // ── Care Thread Engine: detect situations + schedule reminders ──
    try {
      final feedback = await _careEngine.processMessage(
        userId, text, _currentUser!.nickname,
      );
      if (feedback != null) {
        final sysMsg = MessageModel(
          userId: userId,
          text: feedback,
          senderType: SenderType.ai,
          timestamp: DateTime.now().toIso8601String(),
        );
        await _db.insertMessage(sysMsg);
        _messages.add(sysMsg);
        notifyListeners();
      }
      // Also check escalation on existing threads
      await _careEngine.checkEscalation(userId, _currentUser!.nickname);
    } catch (_) {}

    // ── Memory Extraction (non-blocking) ──
    if (!_privacyMode) {
      MemoryExtractionService.extractAndStore(userId, text).then((_) {}, onError: (_) {});
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

    try {

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
    String careThreadCtx = '';
    String emotionalStateCtx = '';
    String emotionalModelCtx = '';
    String attachmentCtx = '';
    String behaviorCtx = '';
    String weightedMemoryCtx = '';
    try { emotionalCtx = await EmotionalIntelligenceService.buildEmotionalContext(userId); } catch (_) {}
    if (!_privacyMode) {
      try { memoryCtx = await MemoryExtractionService.buildMemoryPrompt(userId); } catch (_) {}
      try { weightedMemoryCtx = await _memoryWeights.buildWeightedMemoryContext(userId); } catch (_) {}
    }
    try { careThreadCtx = await _careEngine.buildCareContext(userId); } catch (_) {}
    try { emotionalStateCtx = _emotionalState.buildStateContext(userId); } catch (_) {}
    try { emotionalModelCtx = await _emotionalModel.buildEmotionalModelContext(userId); } catch (_) {}
    try { attachmentCtx = await _attachment.buildAttachmentContext(userId); } catch (_) {}
    try { behaviorCtx = await _behaviorEngine.buildBehaviorContext(userId); } catch (_) {}
    // Periodically recalculate memory weights (every 10 messages)
    if (_totalInteractions % 10 == 0) {
      _memoryWeights.recalculateWeights(userId).then((_) {}, onError: (_) {});
    }
    // Periodically run weekly adaptation (every 50 interactions)
    if (_totalInteractions % 50 == 0) {
      _behaviorEngine.weeklyAdapt(userId).then((_) {}, onError: (_) {});
    }

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
          careThreadContext: careThreadCtx,
          emotionalStateContext: emotionalStateCtx,
          emotionalModelContext: emotionalModelCtx,
          attachmentContext: attachmentCtx,
          behaviorContext: behaviorCtx,
          weightedMemoryContext: weightedMemoryCtx,
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
    if (ContextAwarenessService.isLateNight()) {
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

    // ── Post-response emotional state transition ──
    try {
      final activeThreads = await _careEngine.getActiveThreads(userId);
      await _emotionalState.transitionState(
        userId: userId,
        moodScore: profile?.currentMoodScore ?? 0.0,
        careThreadType: activeThreads.isNotEmpty ? activeThreads.first.type : null,
        careThreadIntensity: activeThreads.isNotEmpty ? activeThreads.first.intensity : null,
      );
    } catch (e) {
      debugPrint('Post-response state transition error: $e');
    }

    // ── Surprise moment (5% chance) ──
    try {
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
    } catch (_) {}

    // ── Record interaction for self-learning ──
    try {
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

      // Deep analysis every 10 messages
      final msgCount = await _db.getMessageCount(userId, days: 1);
      if (msgCount % 10 == 0) {
        await _learning.analyzeAndAdapt(userId);
        _learnedProfile = await _db.getUserProfile(userId);
      }
    } catch (e) {
      debugPrint('Self-learning record error: $e');
    }
    } finally {
      _isLoading = false;
      notifyListeners();
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

    // Schedule notification (no-op on web via conditional import)
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

    // ── Follow-up Memory: "How did it go?" 1 hour after event ──
    await _situational.scheduleFollowUp(
      nickname: _currentUser!.nickname,
      eventDescription: parsed.originalText,
      eventTime: parsed.scheduledTime,
    );

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

    final confirmMsg = MessageModel(
      userId: userId,
      text: confirmText,
      senderType: SenderType.ai,
      timestamp: DateTime.now().toIso8601String(),
    );
    await _db.insertMessage(confirmMsg);
    _messages.add(confirmMsg);
    notifyListeners();

  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  /// Update personality without full re-init (called from Settings)
  void updatePersonality(String newPersonality) {
    _personality = newPersonality;
    notifyListeners();
  }

  Future<void> refreshTokens() async {
    if (_currentUser == null) return;
    final uid = _currentUser!.id;
    if (uid == null) return;
    try {
      await _db.resetTokensIfNeeded(uid);
      _tokens = await _db.getTokens(uid);
      notifyListeners();
    } catch (_) {}
  }
}
