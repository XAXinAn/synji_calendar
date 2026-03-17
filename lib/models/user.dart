class User {
  final String id;
  final String username;
  final String nickname;
  final String token;

  User({
    required this.id,
    required this.username,
    required this.nickname,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? '').toString(),
      username: json['username'] ?? '',
      nickname: json['nickname'] ?? '',
      // 兼容性处理：支持后端返回 token 或 accessToken
      token: json['token'] ?? json['accessToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'token': token,
    };
  }
}
