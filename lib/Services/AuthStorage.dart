import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const String _kJwt = 'auth_token';
  static const String _kRefreshToken = 'refresh_token';
  static const String _kUser = 'auth_user';

  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _kJwt, value: token);
  }

  static Future<String?> readToken() async {
    return await _storage.read(key: _kJwt);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _kJwt);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _kRefreshToken, value: token);
  }

  static Future<String?> readRefreshToken() async {
    return await _storage.read(key: _kRefreshToken);
  }

  static Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _kRefreshToken);
  }

  static Future<void> saveUser(Map<String, dynamic> userJson) async {
    await _storage.write(key: _kUser, value: jsonEncode(userJson));
  }

  static Future<Map<String, dynamic>?> readUser() async {
    final jsonStr = await _storage.read(key: _kUser);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteUser() async {
    await _storage.delete(key: _kUser);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<Map<String, String>> authHeaders() async {
    final token = await readToken();
    if (token == null || token.isEmpty) return {};
    return {'Authorization': 'Bearer $token'};
  }

  static Future<bool> hasToken() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }
}
