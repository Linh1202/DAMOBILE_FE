import '../../Models/Api/BaseResponse.dart';
import '../../Models/Api/AuthResponse.dart';

abstract interface class IAuthService {
  Future<BaseResponse<AuthResponse>> login(String email, String password);

  Future<BaseResponse<AuthResponse>> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  });

  Future<BaseResponse<dynamic>> forgotPassword(String email);

  Future<BaseResponse<dynamic>> verifyCode(String email, String code);

  Future<BaseResponse<dynamic>> resetPassword({
    required String email,
    required String newPassword,
    required String code,
  });

  Future<BaseResponse<dynamic>> logout();

  Future<String?> getCurrentUserId();

  Future<bool> isSignedIn();
}