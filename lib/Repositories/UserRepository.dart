import '../Services/ApiService.dart';
import '../Models/User.dart';

class UserRepository {
  final ApiService _apiService = ApiService();

  /// POST /user/find-by-email - Tìm kiếm user theo email
  Future<List<User>> findUserByEmail(String email) async {
    try {
      final response = await _apiService.postWithAuth('/user/find-by-email', {
        'email': email,
      });
      
      if (response['success'] == true && response['data'] != null) {
        // Nếu trả về 1 user
        if (response['data']['user'] != null) {
          return [User.fromJson(response['data']['user'])];
        }
        // Nếu trả về danh sách users
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

  /// GET /user/profile - Lấy thông tin profile
  Future<User> getProfile() async {
    try {
      final response = await _apiService.getWithAuth('/user/profile');
      
      if (response['success'] == true && response['data'] != null) {
        return User.fromJson(response['data']['user'] ?? response['data']);
      }
      
      throw Exception('Không thể lấy thông tin profile');
    } catch (e) {
      throw Exception('Không thể lấy thông tin profile: $e');
    }
  }

  /// PUT /user/profile - Cập nhật profile
  Future<User> updateProfile({
    String? username,
    String? avatarUrl,
    String? phoneNumber,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      
      final response = await _apiService.putWithAuth('/user/profile', data);
      
      if (response['success'] == true && response['data'] != null) {
        return User.fromJson(response['data']['user'] ?? response['data']);
      }
      
      throw Exception('Không thể cập nhật profile');
    } catch (e) {
      throw Exception('Không thể cập nhật profile: $e');
    }
  }

  /// POST /user/change-password - Đổi mật khẩu
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _apiService.postWithAuth('/user/change-password', {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      
      return response['success'] == true;
    } catch (e) {
      throw Exception('Không thể đổi mật khẩu: $e');
    }
  }
}
