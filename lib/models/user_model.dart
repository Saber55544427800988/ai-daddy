class UserModel {
  final int? id;
  final String nickname;
  final String dadPersonality;
  final String createdAt;
  final String lastOpened;

  UserModel({
    this.id,
    required this.nickname,
    required this.dadPersonality,
    required this.createdAt,
    required this.lastOpened,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'dad_personality': dadPersonality,
      'created_at': createdAt,
      'last_opened': lastOpened,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      nickname: map['nickname'] as String,
      dadPersonality: map['dad_personality'] as String,
      createdAt: map['created_at'] as String,
      lastOpened: map['last_opened'] as String,
    );
  }

  UserModel copyWith({
    int? id,
    String? nickname,
    String? dadPersonality,
    String? createdAt,
    String? lastOpened,
  }) {
    return UserModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      dadPersonality: dadPersonality ?? this.dadPersonality,
      createdAt: createdAt ?? this.createdAt,
      lastOpened: lastOpened ?? this.lastOpened,
    );
  }
}
