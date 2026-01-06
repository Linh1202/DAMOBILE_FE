import '../Services/ApiService.dart';
import '../Models/Chat.dart';
import '../Utils/Constants/ApiEndpoints.dart';

class GroupRepository {
  final ApiService _apiService = ApiService();

  Future<Chat> createGroup({
    required String name,
    required String description,
    required String creatorId,
  }) async {
    try {
      final response = await _apiService.postWithAuth(ApiEndpoints.group, {
        'name': name,
        'description': description,
        'creatorId': creatorId,
      });
      if (response['success'] == true && response['data'] != null) {
        return Chat.fromJson(response['data']['group'] ?? response['data']);
      }
      throw Exception('Không thể tạo nhóm');
    } catch (e) {
      throw Exception('Lỗi tạo nhóm: $e');
    }
  }

  Future<Chat> getGroupById(String id) async {
    try {
      final response = await _apiService.getWithAuth(ApiEndpoints.groupById(id));
      if (response['success'] == true && response['data'] != null) {
        return Chat.fromJson(response['data']['group'] ?? response['data']);
      }
      throw Exception('Không tìm thấy thông tin nhóm');
    } catch (e) {
      throw Exception('Lỗi lấy thông tin nhóm: $e');
    }
  }

  Future<List<Chat>> getGroupsByCreator(String creatorId) async {
    try {
      final response = await _apiService.getWithAuth(ApiEndpoints.groupByCreator(creatorId));
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> groupsJson = response['data']['groups'] ?? [];
        return groupsJson.map((json) => Chat.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi lấy danh sách nhóm của người tạo: $e');
    }
  }

  Future<bool> addMember(String groupId, String userId) async {
    try {
      final response = await _apiService.postWithAuth(ApiEndpoints.groupMember, {
        'groupId': groupId,
        'userId': userId,
      });
      return response['success'] == true;
    } catch (e) {
      throw Exception('Lỗi thêm thành viên vào nhóm: $e');
    }
  }

  Future<bool> removeMember(String groupId, String userId) async {
    try {
      final response = await _apiService.deleteWithAuth(ApiEndpoints.groupMember, {
        'groupId': groupId,
        'userId': userId,
      });
      return response['success'] == true;
    } catch (e) {
      throw Exception('Lỗi xóa thành viên khỏi nhóm: $e');
    }
  }
}