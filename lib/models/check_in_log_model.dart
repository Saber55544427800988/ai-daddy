class CheckInLogModel {
  final int? id;
  final int userId;
  final String lastOpenTime;

  CheckInLogModel({
    this.id,
    required this.userId,
    required this.lastOpenTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'last_open_time': lastOpenTime,
    };
  }

  factory CheckInLogModel.fromMap(Map<String, dynamic> map) {
    return CheckInLogModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      lastOpenTime: map['last_open_time'] as String,
    );
  }

  /// Token cost for check-in
  static const int tokenCost = 20;
}
