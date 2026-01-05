import 'package:doanmobile/Models/User.dart';

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    String token = json['accessToken'] ?? json['access_token'] ?? json['token'] ?? '';
    var userJson = json['user'] ?? json['data'] ?? {};
    return AuthResponse(
      token: token,
      user: User.fromJson(userJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}
