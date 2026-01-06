import 'package:doanmobile/Models/User.dart';

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  // Sửa để xử lý dynamic type từ JSON
  factory AuthResponse.fromJson(dynamic json) {
    final Map<String, dynamic> data = json is Map<String, dynamic> 
        ? json 
        : Map<String, dynamic>.from(json as Map);
    
    String token = data['accessToken']?.toString() ?? 
                   data['access_token']?.toString() ?? 
                   data['token']?.toString() ?? '';
    
    var userJson = data['user'] ?? data['data'] ?? {};
    
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
