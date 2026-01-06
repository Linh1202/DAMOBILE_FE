import 'package:doanmobile/Interfaces/Repositories/IAuthRepository.dart';
import 'package:doanmobile/Interfaces/Services/IAuthServices.dart';
import 'package:doanmobile/Models/Api/AuthResponse.dart';
import 'package:doanmobile/Models/Api/BaseResponse.dart';
import 'package:doanmobile/Repositories/AuthRepository.dart';

class AuthService implements IAuthService {
  final IAuthRepository _authRepository;

  AuthService({IAuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  @override
  Future<BaseResponse<AuthResponse>> login(String email, String password) async {
    try {
      final response = await _authRepository.login(email, password);
      return response;
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
      return await _authRepository.register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BaseResponse<dynamic>> forgotPassword(String email) async {
    try {
      return await _authRepository.forgotPassword(email);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BaseResponse<dynamic>> verifyCode(String email, String code) async {
    try {
      return await _authRepository.verifyCode(email, code);
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
      return await _authRepository.resetPassword(
        email: email,
        newPassword: newPassword,
        code: code,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BaseResponse<dynamic>> logout() async {
    try {
      final response = await _authRepository.logout();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String?> getCurrentUserId() async {
    return await _authRepository.getCurrentUserId();
  }

  @override
  Future<bool> isSignedIn() async {
    return await _authRepository.isSignedIn();
  }
}