class User {
  final String id;
  final String username;
  final String nickname;
  final String token;
  final String refreshToken;

  User({
    required this.id,
    required this.username,
    required this.nickname,
    required this.token,
    required this.refreshToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? '').toString(),
      username: json['username'] ?? '',
      nickname: json['nickname'] ?? '',
      token: json['token'] ?? json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'token': token,
      'refreshToken': refreshToken,
    };
  }
}
