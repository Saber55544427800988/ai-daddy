import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/ai_token_model.dart';

class TokenProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  AITokenModel? _tokens;

  AITokenModel? get tokens => _tokens;
  int get remaining => _tokens?.remainingTokens ?? 0;
  int get total => _tokens?.totalTokens ?? 5000;
  double get percentRemaining => _tokens?.percentRemaining ?? 1.0;
  bool get isLow => _tokens?.isLow ?? false;
  SpendingMode get spendingMode =>
      _tokens?.spendingMode ?? SpendingMode.slow;

  Future<void> init(int userId) async {
    await _db.initTokens(userId);
    await _db.resetTokensIfNeeded(userId);
    _tokens = await _db.getTokens(userId);
    notifyListeners();
  }

  Future<void> refresh(int userId) async {
    await _db.resetTokensIfNeeded(userId);
    _tokens = await _db.getTokens(userId);
    notifyListeners();
  }

  Future<void> setSpendingMode(int userId, SpendingMode mode) async {
    await _db.updateSpendingMode(userId, mode);
    _tokens = await _db.getTokens(userId);
    notifyListeners();
  }

  Duration get timeUntilRefill {
    if (_tokens == null) return Duration.zero;
    final lastReset = DateTime.parse(_tokens!.lastReset);
    final nextReset = lastReset.add(const Duration(hours: 24));
    final diff = nextReset.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String get refillCountdown {
    final d = timeUntilRefill;
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
