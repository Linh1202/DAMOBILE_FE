import '../Services/ApiService.dart';
import '../Models/User.dart';
import '../Utils/Constants/ApiEndpoints.dart';

class UserRepository {
  final ApiService _apiService = ApiService();

  Future<List<User>> findUserByEmail(String email) async {
    try {
      final response = await _apiService.postWithAuth(ApiEndpoints.findUserByEmail, {
        'email': email,
      });
      
      if (response['success'] == true && response['data'] != null) {
        if (response['data']['user'] != null) {
          return [User.fromJson(response['data']['user'])];
        }
        if (response['data']['users'] != null) {
          final List<dynamic> usersJson = response['data']['users'];
          return usersJson.map((json) => User.fromJson(json)).toList();
        }
      }
      
      return [];
    } catch (e) {
      throw Exception('Không thể tìm kiếm người dùng: $e');
    }
  }

  Future<List<User>> findUserByUsername(String username) async {
    try {
      final response = await _apiService.postWithAuth(ApiEndpoints.findUserByName, {
        'userName': username,
      });

      if (response['success'] == true && response['data'] != null) {
        if (response['data']['user'] != null) {
          return [User.fromJson(response['data']['user'])];
        }
        if (response['data']['users'] != null) {
          final List<dynamic> usersJson = response['data']['users'];
          return usersJson.map((json) => User.fromJson(json)).toList();
        }
      }

      return [];
    } catch (e) {
      throw Exception('Không thể tìm kiếm người dùng: $e');
    }
  }

  Future<User> getProfile() async {
    try {
      final response = await _apiService.getWithAuth(ApiEndpoints.userProfile);
      
      if (response['success'] == true && response['data'] != null) {
        return User.fromJson(response['data']['user'] ?? response['data']);
      }
      
      throw Exception('Không thể lấy thông tin profile');
    } catch (e) {
      throw Exception('Không thể lấy thông tin profile: $e');
    }
  }

  Future<User> updateProfile({
    String? username,
    String? bio,
    String? avatarUrl,
    String? phoneNumber,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (bio != null) data['bio'] = bio;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      
      final response = await _apiService.putWithAuth(ApiEndpoints.userProfile, data);
      
      if (response['success'] == true && response['data'] != null) {
        return User.fromJson(response['data']['user'] ?? response['data']);
      }
      
      throw Exception('Không thể cập nhật profile');
    } catch (e) {
      throw Exception('Không thể cập nhật profile: $e');
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _apiService.postWithAuth(ApiEndpoints.changePassword, {
        'old_password': currentPassword,
        'new_password': newPassword,
      });
      
      return response['success'] == true;
    } catch (e) {
      throw Exception('Không thể đổi mật khẩu: $e');
    }
  }
}