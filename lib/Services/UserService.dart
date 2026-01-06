import '../Repositories/UserRepository.dart';
import '../Models/User.dart';

class UserService {
  final UserRepository _userRepository = UserRepository();

  Future<List<User>> findUserByEmail(String email) async {
    return await _userRepository.findUserByEmail(email);
  }

  Future<List<User>> findUserByUsername(String username) async {
    return await _userRepository.findUserByUsername(username);
  }

  Future<User> getProfile() async {
    return await _userRepository.getProfile();
  }

  Future<User> updateProfile({
    String? username,
    String? bio,
    String? avatarUrl,
    String? phoneNumber,
  }) async {
    return await _userRepository.updateProfile(
      username: username,
      bio: bio,
      avatarUrl: avatarUrl,
      phoneNumber: phoneNumber,
    );
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    return await _userRepository.changePassword(currentPassword, newPassword);
  }
}