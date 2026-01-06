import 'package:doanmobile/Interfaces/Repositories/IAuthRepository.dart';
import 'package:doanmobile/Models/Api/AuthResponse.dart';
import 'package:doanmobile/Models/Api/BaseResponse.dart';
import 'package:doanmobile/Models/User.dart';
import 'package:doanmobile/Services/ApiService.dart';
import 'package:doanmobile/Utils/Constants/ApiEndpoints.dart';

class AuthRepository implements IAuthRepository {
  final ApiService _apiService = ApiService();

  @override
  Future<BaseResponse<AuthResponse>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _apiService.post(ApiEndpoints.signin, {
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
    required String phoneNumber,
  }) async {
    try {
      final response = await _apiService.post(ApiEndpoints.signup, {
        'email': email,
        'password': password,
        'username': fullName,
        'phoneNumber': phoneNumber,
      });

      if (response == null || response['data'] == null) {
        final fallback = AuthResponse(
          token: '',
          user: User(
            id: '',
            email: email,
            fullName: fullName,
            phoneNumber: phoneNumber,
          ),
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
      final response = await _apiService.post(ApiEndpoints.forgotPassword, {
        'email': email,
      });
      return BaseResponse<dynamic>.fromJson(response, (data) => data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BaseResponse<dynamic>> verifyCode(String email, String code) async {
    return BaseResponse<dynamic>(
      success: true,
      message: "Mã xác thực hợp lệ",
    );
  }

  @override
  Future<BaseResponse<dynamic>> resetPassword({
    required String email,
    required String newPassword,
    required String code,
  }) async {
    try {
      final response = await _apiService.post(ApiEndpoints.resetPassword, {
        'email': email,
        'new_password': newPassword,
        'otp': code,
      });
      return BaseResponse<dynamic>.fromJson(response, (data) => data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BaseResponse<dynamic>> logout() async {
    return BaseResponse<dynamic>(
      success: true,
      message: "Đăng xuất thành công",
    );
  }

  @override
  Future<String?> getCurrentUserId() async {
    return null;
  }

  @override
  Future<bool> isSignedIn() async {
    return false;
  }
}