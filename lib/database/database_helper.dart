import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/personality_model.dart';
import '../models/message_model.dart';
import '../models/reminder_model.dart';
import '../models/smart_reminder_model.dart';
import '../models/mood_log_model.dart';
import '../models/check_in_log_model.dart';
import '../models/mission_model.dart';
import '../models/ai_token_model.dart';
import '../models/user_profile_model.dart';
import '../models/dad_memory_model.dart';
import '../models/habit_model.dart';
import '../models/goal_model.dart';
import '../models/dad_report_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ai_daddy.db');
    return _database!;
  }

  /// Run migrations for new tables (safe to call multiple times)
  Future<void> runMigrations() async {
    final db = await database;
    // care_threads table — added for Care Thread Engine
    await db.execute('''
      CREATE TABLE IF NOT EXISTS care_threads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        sub_type TEXT DEFAULT '',
        status TEXT DEFAULT 'active',
        intensity TEXT DEFAULT 'medium',
        escalation_level INTEGER DEFAULT 0,
        follow_up_count INTEGER DEFAULT 0,
        ignored_count INTEGER DEFAULT 0,
        start_time TEXT NOT NULL,
        end_time TEXT,
        last_follow_up TEXT,
        trigger_message TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Emotional State Log — AI Daddy's internal state transitions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS emotional_state_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        state TEXT NOT NULL DEFAULT 'calm',
        previous_state TEXT DEFAULT 'calm',
        trigger TEXT DEFAULT '',
        state_intensity REAL DEFAULT 0.5,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // User Emotional Profile — dynamic emotional model per user
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_emotional_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        baseline_mood REAL DEFAULT 0.0,
        current_mood_score REAL DEFAULT 0.0,
        stress_count_24h INTEGER DEFAULT 0,
        loneliness_count_7d INTEGER DEFAULT 0,
        sleep_pattern TEXT DEFAULT 'unknown',
        health_incidents_30d INTEGER DEFAULT 0,
        emotional_openness REAL DEFAULT 0.3,
        attachment_score INTEGER DEFAULT 20,
        last_mood_update TEXT DEFAULT '',
        mood_trend TEXT DEFAULT 'stable',
        recent_moods TEXT DEFAULT '[]',
        support_mode_active INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Memory Weights — emotional weight per stored memory
    await db.execute('''
      CREATE TABLE IF NOT EXISTS memory_weights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        memory_id INTEGER NOT NULL,
        memory_type TEXT DEFAULT 'preference',
        emotional_weight INTEGER DEFAULT 5,
        recency_score REAL DEFAULT 1.0,
        frequency_score REAL DEFAULT 0.0,
        last_calculated TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (memory_id) REFERENCES dad_memories(id)
      )
    ''');

    // Behavior Stats — user behavioral preferences for adaptation
    await db.execute('''
      CREATE TABLE IF NOT EXISTS behavior_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        preferred_msg_length REAL DEFAULT 60.0,
        preferred_strictness REAL DEFAULT 0.4,
        preferred_reminder_timing TEXT DEFAULT 'adaptive',
        emotional_sensitivity REAL DEFAULT 0.5,
        reminder_response_rate REAL DEFAULT 0.5,
        conversation_depth REAL DEFAULT 0.3,
        inactivity_days INTEGER DEFAULT 0,
        last_adaptation TEXT DEFAULT '',
        weekly_trends TEXT DEFAULT '{}',
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
  }

  Future<Database> _initDB(String fileName) async {
    if (kIsWeb) {
      // On web, use in-memory or default path
      return await openDatabase(
        fileName,
        version: 1,
        onCreate: _createDB,
      );
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nickname TEXT NOT NULL,
        dad_personality TEXT NOT NULL DEFAULT 'caring',
        created_at TEXT NOT NULL,
        last_opened TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE personality (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        tone TEXT NOT NULL,
        behavior_json TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        text TEXT NOT NULL,
        sender_type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        engagement_score REAL DEFAULT 0.0,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        text TEXT NOT NULL,
        scheduled_time TEXT NOT NULL,
        sent_flag INTEGER DEFAULT 0,
        read_flag INTEGER DEFAULT 0,
        tone TEXT NOT NULL DEFAULT 'caring',
        engagement_score REAL DEFAULT 0.0,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE smart_reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        text TEXT NOT NULL,
        scheduled_time TEXT NOT NULL,
        sent_flag INTEGER DEFAULT 0,
        voice_played_flag INTEGER DEFAULT 0,
        event_type TEXT NOT NULL DEFAULT 'custom',
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE mood_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        mood_score INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE check_in_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        last_open_time TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE missions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        xp_reward INTEGER DEFAULT 50,
        token_reward INTEGER DEFAULT 50
      )
    ''');

    await db.execute('''
      CREATE TABLE mission_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        mission_id INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        date TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (mission_id) REFERENCES missions(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_tokens (
        user_id INTEGER PRIMARY KEY,
        total_tokens INTEGER DEFAULT 5000,
        spent_tokens INTEGER DEFAULT 0,
        last_reset TEXT NOT NULL,
        spending_mode TEXT DEFAULT 'slow',
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nickname TEXT NOT NULL,
        favorite_tone TEXT DEFAULT 'caring',
        preferred_message_length TEXT DEFAULT 'short',
        activity_patterns TEXT DEFAULT '{}',
        caring_score REAL DEFAULT 50.0,
        strict_score REAL DEFAULT 50.0,
        playful_score REAL DEFAULT 50.0,
        motivational_score REAL DEFAULT 50.0,
        best_active_hours TEXT DEFAULT '{}',
        interaction_streak INTEGER DEFAULT 0,
        total_interactions INTEGER DEFAULT 0,
        preferred_reminder_times TEXT DEFAULT '[]',
        last_weekly_analysis TEXT DEFAULT '',
        avg_user_msg_length REAL DEFAULT 0.0,
        avg_response_time REAL DEFAULT 0.0,
        top_intents TEXT DEFAULT '{}',
        mood_history TEXT DEFAULT '[]'
      )
    ''');

    // Detailed per-interaction log for reinforcement learning
    await db.execute('''
      CREATE TABLE interaction_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        hour_of_day INTEGER NOT NULL,
        day_of_week INTEGER NOT NULL,
        user_message_length INTEGER DEFAULT 0,
        response_time_seconds REAL DEFAULT 0.0,
        tone_used TEXT NOT NULL,
        intent_detected TEXT NOT NULL DEFAULT 'general',
        sentiment_score REAL DEFAULT 0.0,
        engagement_score REAL DEFAULT 0.0,
        user_replied INTEGER DEFAULT 0,
        reply_was_positive INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Dad Memory Vault — long-term memories
    await db.execute('''
      CREATE TABLE dad_memories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category TEXT NOT NULL DEFAULT 'preference',
        content TEXT NOT NULL,
        context TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        last_mentioned TEXT DEFAULT '',
        mention_count INTEGER DEFAULT 0,
        importance REAL DEFAULT 0.5,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Habit Formation Engine
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT DEFAULT 'custom',
        total_days INTEGER DEFAULT 0,
        completed_days INTEGER DEFAULT 0,
        current_streak INTEGER DEFAULT 0,
        best_streak INTEGER DEFAULT 0,
        last_completed TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Long-Term Goal Tracking
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        category TEXT DEFAULT 'personal',
        milestones TEXT DEFAULT '[]',
        progress REAL DEFAULT 0.0,
        status TEXT DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT DEFAULT '',
        target_date TEXT DEFAULT '',
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Weekly Dad Reports
    await db.execute('''
      CREATE TABLE dad_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        week_start TEXT NOT NULL,
        week_end TEXT NOT NULL,
        total_messages INTEGER DEFAULT 0,
        missions_completed INTEGER DEFAULT 0,
        missions_total INTEGER DEFAULT 0,
        avg_mood REAL DEFAULT 3.0,
        mood_trend TEXT DEFAULT 'stable',
        tokens_used INTEGER DEFAULT 0,
        reminders_missed INTEGER DEFAULT 0,
        engagement_score REAL DEFAULT 0.0,
        growth_score REAL DEFAULT 0.0,
        daddy_message TEXT DEFAULT '',
        highlights TEXT DEFAULT '[]',
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Care Thread Engine — persistent care situation tracking
    await db.execute('''
      CREATE TABLE IF NOT EXISTS care_threads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        sub_type TEXT DEFAULT '',
        status TEXT DEFAULT 'active',
        intensity TEXT DEFAULT 'medium',
        escalation_level INTEGER DEFAULT 0,
        follow_up_count INTEGER DEFAULT 0,
        ignored_count INTEGER DEFAULT 0,
        start_time TEXT NOT NULL,
        end_time TEXT,
        last_follow_up TEXT,
        trigger_message TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Emotional State Log — AI internal state transitions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS emotional_state_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        state TEXT NOT NULL DEFAULT 'calm',
        previous_state TEXT DEFAULT 'calm',
        trigger TEXT DEFAULT '',
        state_intensity REAL DEFAULT 0.5,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // User Emotional Profile — dynamic emotional model per user
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_emotional_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        baseline_mood REAL DEFAULT 0.0,
        current_mood_score REAL DEFAULT 0.0,
        stress_count_24h INTEGER DEFAULT 0,
        loneliness_count_7d INTEGER DEFAULT 0,
        sleep_pattern TEXT DEFAULT 'unknown',
        health_incidents_30d INTEGER DEFAULT 0,
        emotional_openness REAL DEFAULT 0.3,
        attachment_score INTEGER DEFAULT 20,
        last_mood_update TEXT DEFAULT '',
        mood_trend TEXT DEFAULT 'stable',
        recent_moods TEXT DEFAULT '[]',
        support_mode_active INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Memory Weights — emotional weight per stored memory
    await db.execute('''
      CREATE TABLE IF NOT EXISTS memory_weights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        memory_id INTEGER NOT NULL,
        memory_type TEXT DEFAULT 'preference',
        emotional_weight INTEGER DEFAULT 5,
        recency_score REAL DEFAULT 1.0,
        frequency_score REAL DEFAULT 0.0,
        last_calculated TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (memory_id) REFERENCES dad_memories(id)
      )
    ''');

    // Behavior Stats — user behavioral preferences for adaptation
    await db.execute('''
      CREATE TABLE IF NOT EXISTS behavior_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        preferred_msg_length REAL DEFAULT 60.0,
        preferred_strictness REAL DEFAULT 0.4,
        preferred_reminder_timing TEXT DEFAULT 'adaptive',
        emotional_sensitivity REAL DEFAULT 0.5,
        reminder_response_rate REAL DEFAULT 0.5,
        conversation_depth REAL DEFAULT 0.3,
        inactivity_days INTEGER DEFAULT 0,
        last_adaptation TEXT DEFAULT '',
        weekly_trends TEXT DEFAULT '{}',
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Insert default personalities
    for (final p in PersonalityModel.defaultPersonalities()) {
      await db.insert('personality', p.toMap());
    }

    // Insert default missions
    for (final m in MissionModel.dailyDefaults()) {
      await db.insert('missions', m.toMap());
    }
  }

  // ─── USERS ──────────────────────────────────────────

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> getUser(int id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> getFirstUser() async {
    final db = await database;
    final maps = await db.query('users', limit: 1);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update('users', user.toMap(),
        where: 'id = ?', whereArgs: [user.id]);
  }

  // ─── MESSAGES ───────────────────────────────────────

  Future<int> insertMessage(MessageModel message) async {
    final db = await database;
    return await db.insert('messages', message.toMap());
  }

  Future<List<MessageModel>> getMessages(int userId, {int limit = 50}) async {
    final db = await database;
    final maps = await db.query(
      'messages',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp ASC',
      limit: limit,
    );
    return maps.map((m) => MessageModel.fromMap(m)).toList();
  }

  Future<List<MessageModel>> getRecentMessages(int userId,
      {int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      'messages',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((m) => MessageModel.fromMap(m)).toList().reversed.toList();
  }

  Future<void> deleteAllMessages(int userId) async {
    final db = await database;
    await db.delete('messages', where: 'user_id = ?', whereArgs: [userId]);
  }

  // ─── REMINDERS ──────────────────────────────────────

  Future<int> insertReminder(ReminderModel reminder) async {
    final db = await database;
    return await db.insert('reminders', reminder.toMap());
  }

  Future<List<ReminderModel>> getPendingReminders(int userId) async {
    final db = await database;
    final maps = await db.query(
      'reminders',
      where: 'user_id = ? AND sent_flag = 0',
      whereArgs: [userId],
      orderBy: 'scheduled_time ASC',
    );
    return maps.map((m) => ReminderModel.fromMap(m)).toList();
  }

  Future<int> markReminderSent(int id) async {
    final db = await database;
    return await db
        .update('reminders', {'sent_flag': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> markReminderRead(int id) async {
    final db = await database;
    return await db
        .update('reminders', {'read_flag': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ─── SMART REMINDERS ───────────────────────────────

  Future<int> insertSmartReminder(SmartReminderModel reminder) async {
    final db = await database;
    return await db.insert('smart_reminders', reminder.toMap());
  }

  Future<List<SmartReminderModel>> getPendingSmartReminders(int userId) async {
    final db = await database;
    final maps = await db.query(
      'smart_reminders',
      where: 'user_id = ? AND sent_flag = 0',
      whereArgs: [userId],
      orderBy: 'scheduled_time ASC',
    );
    return maps.map((m) => SmartReminderModel.fromMap(m)).toList();
  }

  Future<int> markSmartReminderSent(int id) async {
    final db = await database;
    return await db.update('smart_reminders', {'sent_flag': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Get ALL smart reminders for a user (both pending and sent)
  Future<List<SmartReminderModel>> getAllSmartReminders(int userId) async {
    final db = await database;
    final maps = await db.query(
      'smart_reminders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'scheduled_time DESC',
    );
    return maps.map((m) => SmartReminderModel.fromMap(m)).toList();
  }

  /// Get ALL regular reminders for a user
  Future<List<ReminderModel>> getAllReminders(int userId) async {
    final db = await database;
    final maps = await db.query(
      'reminders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'scheduled_time DESC',
    );
    return maps.map((m) => ReminderModel.fromMap(m)).toList();
  }

  /// Delete a smart reminder
  Future<int> deleteSmartReminder(int id) async {
    final db = await database;
    return await db.delete('smart_reminders', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete a regular reminder
  Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  /// Update a regular reminder (text + scheduled_time)
  Future<int> updateReminder(int id, String text, String scheduledTime) async {
    final db = await database;
    return await db.update(
      'reminders',
      {'text': text, 'scheduled_time': scheduledTime, 'sent_flag': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── MOOD LOG ──────────────────────────────────────

  Future<int> insertMoodLog(MoodLogModel mood) async {
    final db = await database;
    return await db.insert('mood_log', mood.toMap());
  }

  Future<List<MoodLogModel>> getMoodLogs(int userId, {int days = 7}) async {
    final db = await database;
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final maps = await db.query(
      'mood_log',
      where: 'user_id = ? AND timestamp >= ?',
      whereArgs: [userId, since],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => MoodLogModel.fromMap(m)).toList();
  }

  // ─── CHECK-IN LOG ─────────────────────────────────

  Future<int> insertCheckIn(CheckInLogModel checkIn) async {
    final db = await database;
    return await db.insert('check_in_log', checkIn.toMap());
  }

  Future<CheckInLogModel?> getLastCheckIn(int userId) async {
    final db = await database;
    final maps = await db.query(
      'check_in_log',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'last_open_time DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CheckInLogModel.fromMap(maps.first);
  }

  // ─── MISSIONS ─────────────────────────────────────

  Future<List<MissionModel>> getMissions() async {
    final db = await database;
    final maps = await db.query('missions');
    return maps.map((m) => MissionModel.fromMap(m)).toList();
  }

  Future<int> insertMissionLog(MissionLogModel log) async {
    final db = await database;
    return await db.insert('mission_log', log.toMap());
  }

  Future<List<MissionLogModel>> getTodayMissionLogs(int userId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final maps = await db.query(
      'mission_log',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, today],
    );
    return maps.map((m) => MissionLogModel.fromMap(m)).toList();
  }

  Future<int> updateMissionLog(MissionLogModel log) async {
    final db = await database;
    return await db.update('mission_log', log.toMap(),
        where: 'id = ?', whereArgs: [log.id]);
  }

  Future<int> getCompletedMissionCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM mission_log WHERE user_id = ? AND status = ?',
      [userId, 'completed'],
    );
    return result.first['count'] as int? ?? 0;
  }

  // ─── AI TOKENS ────────────────────────────────────

  // Helper methods for web token persistence
  Future<void> _saveTokensToPrefs(AITokenModel tokens) async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('token_user_id', tokens.userId);
    await prefs.setInt('token_total', tokens.totalTokens);
    await prefs.setInt('token_spent', tokens.spentTokens);
    await prefs.setString('token_last_reset', tokens.lastReset);
    await prefs.setString('token_spending_mode', tokens.spendingMode.name);
  }

  Future<AITokenModel?> _loadTokensFromPrefs(int userId) async {
    if (!kIsWeb) return null;
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getInt('token_user_id');
    if (storedUserId != userId) return null;
    
    return AITokenModel(
      userId: userId,
      totalTokens: prefs.getInt('token_total') ?? 5000,
      spentTokens: prefs.getInt('token_spent') ?? 0,
      lastReset: prefs.getString('token_last_reset') ?? DateTime.now().toIso8601String(),
      spendingMode: SpendingMode.values.firstWhere(
        (m) => m.name == prefs.getString('token_spending_mode'),
        orElse: () => SpendingMode.slow,
      ),
    );
  }

  Future<void> initTokens(int userId) async {
    // On web, try to restore from SharedPreferences first
    if (kIsWeb) {
      final stored = await _loadTokensFromPrefs(userId);
      if (stored != null) {
        // Already initialized, save to DB
        final db = await database;
        await db.insert(
          'ai_tokens',
          stored.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return;
      }
    }

    final db = await database;
    final existing = await db.query('ai_tokens',
        where: 'user_id = ?', whereArgs: [userId]);
    if (existing.isEmpty) {
      final newTokens = AITokenModel(
        userId: userId,
        lastReset: DateTime.now().toIso8601String(),
      );
      await db.insert('ai_tokens', newTokens.toMap());
      if (kIsWeb) await _saveTokensToPrefs(newTokens);
    }
  }

  Future<AITokenModel?> getTokens(int userId) async {
    final db = await database;
    final maps = await db.query('ai_tokens',
        where: 'user_id = ?', whereArgs: [userId]);
    if (maps.isEmpty) return null;
    final tokens = AITokenModel.fromMap(maps.first);
    // Save to SharedPreferences on web for persistence across reloads
    if (kIsWeb) await _saveTokensToPrefs(tokens);
    return tokens;
  }

  Future<void> spendTokens(int userId, int amount) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE ai_tokens SET spent_tokens = spent_tokens + ? WHERE user_id = ?',
      [amount, userId],
    );
    // Update SharedPreferences on web
    if (kIsWeb) {
      final tokens = await getTokens(userId);
      if (tokens != null) await _saveTokensToPrefs(tokens);
    }
  }

  Future<void> earnTokens(int userId, int amount) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE ai_tokens SET spent_tokens = MAX(0, spent_tokens - ?) WHERE user_id = ?',
      [amount, userId],
    );
    // Update SharedPreferences on web
    if (kIsWeb) {
      final tokens = await getTokens(userId);
      if (tokens != null) await _saveTokensToPrefs(tokens);
    }
  }

  Future<void> resetTokensIfNeeded(int userId) async {
    final tokens = await getTokens(userId);
    if (tokens == null) return;

    final lastReset = DateTime.parse(tokens.lastReset);
    final now = DateTime.now();
    if (now.difference(lastReset).inHours >= 24) {
      final db = await database;
      await db.update(
        'ai_tokens',
        {
          'spent_tokens': 0,
          'last_reset': now.toIso8601String(),
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      // Update SharedPreferences on web
      if (kIsWeb) {
        final updatedTokens = await getTokens(userId);
        if (updatedTokens != null) await _saveTokensToPrefs(updatedTokens);
      }
    }
  }

  Future<void> updateSpendingMode(int userId, SpendingMode mode) async {
    final db = await database;
    await db.update(
      'ai_tokens',
      {'spending_mode': mode.name},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    // Update SharedPreferences on web
    if (kIsWeb) {
      final tokens = await getTokens(userId);
      if (tokens != null) await _saveTokensToPrefs(tokens);
    }
  }

  // ─── USER PROFILE ─────────────────────────────────

  Future<int> insertUserProfile(UserProfileModel profile) async {
    final db = await database;
    return await db.insert('user_profile', profile.toMap());
  }

  Future<UserProfileModel?> getUserProfile(int id) async {
    final db = await database;
    final maps =
        await db.query('user_profile', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return UserProfileModel.fromMap(maps.first);
  }

  Future<int> updateUserProfile(UserProfileModel profile) async {
    final db = await database;
    return await db.update('user_profile', profile.toMap(),
        where: 'id = ?', whereArgs: [profile.id]);
  }

  // ─── INTERACTION LOG (Self-Learning) ──────────────

  Future<int> insertInteractionLog(Map<String, dynamic> log) async {
    final db = await database;
    return await db.insert('interaction_log', log);
  }

  /// Mark the previous AI interaction as "user replied" with sentiment
  Future<void> markLastInteractionReplied(
      int userId, bool wasPositive) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE interaction_log
      SET user_replied = 1, reply_was_positive = ?
      WHERE id = (
        SELECT id FROM interaction_log
        WHERE user_id = ? ORDER BY id DESC LIMIT 1
      )
    ''', [wasPositive ? 1 : 0, userId]);
  }

  /// Average engagement per tone in the last N days
  Future<Map<String, double>> getEngagementByTone(int userId,
      {int days = 14}) async {
    final db = await database;
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final rows = await db.rawQuery('''
      SELECT tone_used, AVG(engagement_score) as avg_eng, COUNT(*) as cnt
      FROM interaction_log
      WHERE user_id = ? AND timestamp >= ?
      GROUP BY tone_used
    ''', [userId, since]);

    final map = <String, double>{};
    for (final r in rows) {
      map[r['tone_used'] as String] = (r['avg_eng'] as num).toDouble();
    }
    return map;
  }

  /// Engagement grouped by hour of day
  Future<Map<int, double>> getEngagementByHour(int userId,
      {int days = 14}) async {
    final db = await database;
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final rows = await db.rawQuery('''
      SELECT hour_of_day, AVG(engagement_score) as avg_eng
      FROM interaction_log
      WHERE user_id = ? AND timestamp >= ?
      GROUP BY hour_of_day
    ''', [userId, since]);

    final map = <int, double>{};
    for (final r in rows) {
      map[r['hour_of_day'] as int] = (r['avg_eng'] as num).toDouble();
    }
    return map;
  }

  /// Intent frequency in the last N days
  Future<Map<String, int>> getIntentFrequency(int userId,
      {int days = 14}) async {
    final db = await database;
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final rows = await db.rawQuery('''
      SELECT intent_detected, COUNT(*) as cnt
      FROM interaction_log
      WHERE user_id = ? AND timestamp >= ?
      GROUP BY intent_detected
      ORDER BY cnt DESC
    ''', [userId, since]);

    final map = <String, int>{};
    for (final r in rows) {
      map[r['intent_detected'] as String] = (r['cnt'] as num).toInt();
    }
    return map;
  }

  /// Reinforcement data: per-tone reply positivity rate
  Future<Map<String, double>> getToneReplyPositivity(int userId,
      {int days = 14}) async {
    final db = await database;
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final rows = await db.rawQuery('''
      SELECT tone_used,
             SUM(reply_was_positive) as pos,
             COUNT(*) as total
      FROM interaction_log
      WHERE user_id = ? AND timestamp >= ? AND user_replied = 1
      GROUP BY tone_used
    ''', [userId, since]);

    final map = <String, double>{};
    for (final r in rows) {
      final total = (r['total'] as num).toDouble();
      final pos = (r['pos'] as num).toDouble();
      if (total > 0) {
        map[r['tone_used'] as String] = pos / total;
      }
    }
    return map;
  }

  /// Average user message length over N days
  Future<double> getAvgUserMessageLength(int userId,
      {int days = 14}) async {
    final db = await database;
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final result = await db.rawQuery('''
      SELECT AVG(user_message_length) as avg_len
      FROM interaction_log
      WHERE user_id = ? AND timestamp >= ? AND user_message_length > 0
    ''', [userId, since]);
    return (result.first['avg_len'] as num?)?.toDouble() ?? 0.0;
  }

  /// Average response time over N days
  Future<double> getAvgResponseTime(int userId, {int days = 14}) async {
    final db = await database;
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final result = await db.rawQuery('''
      SELECT AVG(response_time_seconds) as avg_rt
      FROM interaction_log
      WHERE user_id = ? AND timestamp >= ? AND response_time_seconds > 0
    ''', [userId, since]);
    return (result.first['avg_rt'] as num?)?.toDouble() ?? 0.0;
  }

  /// Count distinct active days in last N days (for streak calc)
  Future<List<String>> getActiveDays(int userId, {int days = 30}) async {
    final db = await database;
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final rows = await db.rawQuery('''
      SELECT DISTINCT SUBSTR(timestamp, 1, 10) as day
      FROM interaction_log
      WHERE user_id = ? AND timestamp >= ?
      ORDER BY day DESC
    ''', [userId, since]);
    return rows.map((r) => r['day'] as String).toList();
  }

  /// Get recent interaction logs for detailed analysis
  Future<List<Map<String, dynamic>>> getRecentInteractionLogs(int userId,
      {int limit = 50}) async {
    final db = await database;
    return await db.query(
      'interaction_log',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
      limit: limit,
    );
  }

  // ─── PERSONALITY ──────────────────────────────────

  Future<List<PersonalityModel>> getPersonalities() async {
    final db = await database;
    final maps = await db.query('personality');
    return maps.map((m) => PersonalityModel.fromMap(m)).toList();
  }

  Future<PersonalityModel?> getPersonalityByName(String name) async {
    final db = await database;
    final maps = await db.query('personality',
        where: 'name = ?', whereArgs: [name], limit: 1);
    if (maps.isEmpty) return null;
    return PersonalityModel.fromMap(maps.first);
  }

  // ─── ANALYTICS ────────────────────────────────────

  Future<double> getAverageEngagement(int userId, {int days = 7}) async {
    final db = await database;
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final result = await db.rawQuery(
      'SELECT AVG(engagement_score) as avg FROM messages WHERE user_id = ? AND timestamp >= ?',
      [userId, since],
    );
    return (result.first['avg'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> getMessageCount(int userId, {int days = 1}) async {
    final db = await database;
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE user_id = ? AND timestamp >= ?',
      [userId, since],
    );
    return result.first['count'] as int? ?? 0;
  }

  // ─── DAD MEMORIES (Memory Vault) ──────────────────

  Future<int> insertDadMemory(DadMemoryModel memory) async {
    final db = await database;
    return await db.insert('dad_memories', memory.toMap());
  }

  Future<List<DadMemoryModel>> getDadMemories(int userId) async {
    final db = await database;
    final maps = await db.query('dad_memories',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'importance DESC, mention_count DESC');
    return maps.map((m) => DadMemoryModel.fromMap(m)).toList();
  }

  Future<List<DadMemoryModel>> getDadMemoriesByCategory(
      int userId, String category) async {
    final db = await database;
    final maps = await db.query('dad_memories',
        where: 'user_id = ? AND category = ?',
        whereArgs: [userId, category],
        orderBy: 'importance DESC');
    return maps.map((m) => DadMemoryModel.fromMap(m)).toList();
  }

  Future<List<DadMemoryModel>> getTopMemories(int userId,
      {int limit = 10}) async {
    final db = await database;
    final maps = await db.query('dad_memories',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'importance DESC',
        limit: limit);
    return maps.map((m) => DadMemoryModel.fromMap(m)).toList();
  }

  Future<int> updateDadMemory(DadMemoryModel memory) async {
    final db = await database;
    return await db.update('dad_memories', memory.toMap(),
        where: 'id = ?', whereArgs: [memory.id]);
  }

  Future<void> touchMemory(int memoryId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE dad_memories SET mention_count = mention_count + 1,
      last_mentioned = ? WHERE id = ?
    ''', [DateTime.now().toIso8601String(), memoryId]);
  }

  Future<int> deleteDadMemory(int id) async {
    final db = await database;
    return await db.delete('dad_memories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllMemories(int userId) async {
    final db = await database;
    await db.delete('dad_memories', where: 'user_id = ?', whereArgs: [userId]);
  }

  // ─── HABITS (Habit Formation Engine) ──────────────

  Future<int> insertHabit(HabitModel habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap());
  }

  Future<List<HabitModel>> getHabits(int userId) async {
    final db = await database;
    final maps = await db.query('habits',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC');
    return maps.map((m) => HabitModel.fromMap(m)).toList();
  }

  Future<int> updateHabit(HabitModel habit) async {
    final db = await database;
    return await db.update('habits', habit.toMap(),
        where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> completeHabitToday(int habitId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.rawUpdate('''
      UPDATE habits SET
        completed_days = completed_days + 1,
        total_days = total_days + 1,
        current_streak = current_streak + 1,
        best_streak = MAX(best_streak, current_streak + 1),
        last_completed = ?
      WHERE id = ?
    ''', [now, habitId]);
  }

  Future<void> skipHabitToday(int habitId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE habits SET
        total_days = total_days + 1,
        current_streak = 0
      WHERE id = ?
    ''', [habitId]);
  }

  // ─── GOALS (Long-Term Goal Tracking) ──────────────

  Future<int> insertGoal(GoalModel goal) async {
    final db = await database;
    return await db.insert('goals', goal.toMap());
  }

  Future<List<GoalModel>> getGoals(int userId,
      {String? status}) async {
    final db = await database;
    String where = 'user_id = ?';
    List<dynamic> args = [userId];
    if (status != null) {
      where += ' AND status = ?';
      args.add(status);
    }
    final maps = await db.query('goals',
        where: where, whereArgs: args, orderBy: 'created_at DESC');
    return maps.map((m) => GoalModel.fromMap(m)).toList();
  }

  Future<int> updateGoal(GoalModel goal) async {
    final db = await database;
    return await db.update('goals', goal.toMap(),
        where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // ─── DAD REPORTS (Weekly Reports) ─────────────────

  Future<int> insertDadReport(DadReportModel report) async {
    final db = await database;
    return await db.insert('dad_reports', report.toMap());
  }

  Future<List<DadReportModel>> getDadReports(int userId,
      {int limit = 10}) async {
    final db = await database;
    final maps = await db.query('dad_reports',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
        limit: limit);
    return maps.map((m) => DadReportModel.fromMap(m)).toList();
  }

  Future<DadReportModel?> getLatestDadReport(int userId) async {
    final db = await database;
    final maps = await db.query('dad_reports',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
        limit: 1);
    if (maps.isEmpty) return null;
    return DadReportModel.fromMap(maps.first);
  }

  // ─── ADVANCED ANALYTICS QUERIES ───────────────────

  /// Messages per day for last N days
  Future<Map<String, int>> getMessagesPerDay(int userId,
      {int days = 7}) async {
    final db = await database;
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final rows = await db.rawQuery('''
      SELECT SUBSTR(timestamp, 1, 10) as day, COUNT(*) as cnt
      FROM messages
      WHERE user_id = ? AND timestamp >= ?
      GROUP BY day ORDER BY day ASC
    ''', [userId, since]);
    final map = <String, int>{};
    for (final r in rows) {
      map[r['day'] as String] = (r['cnt'] as num).toInt();
    }
    return map;
  }

  /// Mood scores per day for last N days
  Future<Map<String, double>> getMoodPerDay(int userId,
      {int days = 7}) async {
    final db = await database;
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final rows = await db.rawQuery('''
      SELECT SUBSTR(timestamp, 1, 10) as day, AVG(mood_score) as avg_mood
      FROM mood_log
      WHERE user_id = ? AND timestamp >= ?
      GROUP BY day ORDER BY day ASC
    ''', [userId, since]);
    final map = <String, double>{};
    for (final r in rows) {
      map[r['day'] as String] = (r['avg_mood'] as num).toDouble();
    }
    return map;
  }

  /// Total interaction count
  Future<int> getTotalInteractions(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM interaction_log WHERE user_id = ?',
      [userId],
    );
    return (result.first['cnt'] as num?)?.toInt() ?? 0;
  }

  /// Tokens spent per day for last N days
  Future<Map<String, int>> getTokensPerDay(int userId,
      {int days = 7}) async {
    final db = await database;
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final rows = await db.rawQuery('''
      SELECT SUBSTR(timestamp, 1, 10) as day,
             SUM(user_message_length * 2) as tokens
      FROM interaction_log
      WHERE user_id = ? AND timestamp >= ?
      GROUP BY day ORDER BY day ASC
    ''', [userId, since]);
    final map = <String, int>{};
    for (final r in rows) {
      map[r['day'] as String] = (r['tokens'] as num?)?.toInt() ?? 0;
    }
    return map;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
