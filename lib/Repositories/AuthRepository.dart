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
      // Đổi từ /auth/forgot-password -> /user/forgot-password (theo BE API)
      final response = await _apiService.post('/user/forgot-password', {
        'email': email,
      });
      return BaseResponse<dynamic>.fromJson(response, (data) => data);
    } catch (e) {
      rethrow;
    }
  }

  // NOTE: BE không có API verify-code riêng.
  // BE dùng 1 API /user/reset-password nhận cả email + otp + new_password
  // Giữ lại method này để không break code, nhưng sẽ trả về success luôn
  @override
  Future<BaseResponse<dynamic>> verifyCode(String email, String code) async {
    // Tạm thời trả về success, việc verify sẽ được thực hiện trong resetPassword
    return BaseResponse<dynamic>(
      success: true,
      message: "Mã xác thực hợp lệ",
      data: null,
    );
  }

  @override
  Future<BaseResponse<dynamic>> resetPassword({
    required String email,
    required String newPassword,
    required String code,
  }) async {
    try {
      // Đổi từ /auth/reset-password -> /user/reset-password (theo BE API)
      // Đổi field 'code' -> 'otp' (theo BE API yêu cầu)
      final response = await _apiService.post('/user/reset-password', {
        'email': email,
        'new_password': newPassword,
        'otp': code, // BE dùng 'otp' thay vì 'code'
      });
      return BaseResponse<dynamic>.fromJson(response, (data) => data);
    } catch (e) {
      rethrow;
    }
  }

  // NOTE: BE không có API logout riêng. 
  // Logout chỉ cần xóa token ở local storage
  @override
  Future<BaseResponse<dynamic>> logout() async {
    // TODO: Xóa token từ local storage
    return BaseResponse<dynamic>(
      success: true,
      message: "Đăng xuất thành công",
      data: null,
    );
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
