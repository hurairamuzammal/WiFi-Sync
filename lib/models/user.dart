class User {
  final String id;
  final String email;
  final String createdAt;

  User({
    required this.id,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? json['user_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'created_at': createdAt,
    };
  }
}

class AuthSession {
  final String accessToken;
  final String tokenType;
  final String userId;
  final String email;

  AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.userId,
    required this.email,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'bearer',
      userId: json['user_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}
