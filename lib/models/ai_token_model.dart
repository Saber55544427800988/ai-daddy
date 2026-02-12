enum SpendingMode { fast, slow }

class AITokenModel {
  final int userId;
  final int totalTokens;
  final int spentTokens;
  final String lastReset;
  final SpendingMode spendingMode;

  AITokenModel({
    required this.userId,
    this.totalTokens = 5000,
    this.spentTokens = 0,
    required this.lastReset,
    this.spendingMode = SpendingMode.slow,
  });

  int get remainingTokens => totalTokens - spentTokens;

  double get percentRemaining =>
      totalTokens > 0 ? remainingTokens / totalTokens : 0.0;

  bool get isLow => remainingTokens < 1000;

  bool canSpend(int amount) => remainingTokens >= amount;

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'total_tokens': totalTokens,
      'spent_tokens': spentTokens,
      'last_reset': lastReset,
      'spending_mode': spendingMode.name,
    };
  }

  factory AITokenModel.fromMap(Map<String, dynamic> map) {
    return AITokenModel(
      userId: map['user_id'] as int,
      totalTokens: map['total_tokens'] as int? ?? 5000,
      spentTokens: map['spent_tokens'] as int? ?? 0,
      lastReset: map['last_reset'] as String,
      spendingMode: SpendingMode.values.firstWhere(
        (e) => e.name == map['spending_mode'],
        orElse: () => SpendingMode.slow,
      ),
    );
  }

  AITokenModel copyWith({
    int? userId,
    int? totalTokens,
    int? spentTokens,
    String? lastReset,
    SpendingMode? spendingMode,
  }) {
    return AITokenModel(
      userId: userId ?? this.userId,
      totalTokens: totalTokens ?? this.totalTokens,
      spentTokens: spentTokens ?? this.spentTokens,
      lastReset: lastReset ?? this.lastReset,
      spendingMode: spendingMode ?? this.spendingMode,
    );
  }
}
