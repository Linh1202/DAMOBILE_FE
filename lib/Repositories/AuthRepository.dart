import 'package:doanmobile/Base/BaseResponse.dart';
import 'package:doanmobile/Interfaces/Repositories/IAuthRepository.dart';
import 'package:doanmobile/Models/Api/AuthResponse.dart';
import 'package:doanmobile/Models/User.dart';
import 'package:doanmobile/Services/ApiService.dart';

class AuthRepository implements IAuthRepository {
  final ApiService _apiService = ApiService();

  @override
  Future<BaseResponse<AuthResponse>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _apiService.post('/auth/signin', {
        'email': email,
        'password': password,
      });
      return BaseResponse<AuthResponse>.fromJson(
        response,
        (data) => AuthResponse.fromJson(data),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BaseResponse<AuthResponse>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _apiService.post('/auth/signup', {
        'email': email,
        'password': password,
        'username': fullName,
      });

      if (response == null || response['data'] == null) {
        final fallback = AuthResponse(
          token: '',
          user: User(id: '', email: email, fullName: fullName),
        );
        return BaseResponse<AuthResponse>(
          success: response?['success'] ?? false,
          message: response?['message'] ?? '',
          data: fallback,
        );
      }

      return BaseResponse<AuthResponse>.fromJson(
        response,
        (data) => AuthResponse.fromJson(data),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BaseResponse<dynamic>> forgotPassword(String email) async {
    try {
      final response = await _apiService.post('/auth/forgot-password', {
        'email': email,
      });
      return BaseResponse<dynamic>.fromJson(response, (data) => data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BaseResponse<dynamic>> verifyCode(String email, String code) async {
    try {
      final response = await _apiService.post('/auth/verify-code', {
        'email': email,
        'code': code,
      });
      return BaseResponse<dynamic>.fromJson(response, (data) => data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BaseResponse<dynamic>> resetPassword({
    required String email,
    required String newPassword,
    required String code,
  }) async {
    try {
      final response = await _apiService.post('/auth/reset-password', {
        'email': email,
        'new_password': newPassword,
        'code': code,
      });
      return BaseResponse<dynamic>.fromJson(response, (data) => data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BaseResponse<dynamic>> logout() async {
    try {
      final response = await _apiService.post('/auth/logout', {});
      return BaseResponse<dynamic>.fromJson(response, (data) => data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String?> getCurrentUserId() async {
    // TODO: Implement getting user ID from local storage or token
    return null;
  }

  @override
  Future<bool> isSignedIn() async {
    // TODO: Implement checking if user is signed in
    return false;
  }
}
