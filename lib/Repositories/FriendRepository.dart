import '../Services/ApiService.dart';
import '../Models/User.dart';
import '../Models/FriendRequest.dart';
import '../Models/Api/BaseResponse.dart';

class FriendRepository {
  final ApiService _apiService = ApiService();

  /// GET /friend/list - Lấy danh sách bạn bè
  Future<List<User>> getFriendList() async {
    try {
      final response = await _apiService.getWithAuth('/friend/list');
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> friendsJson = response['data']['friends'] ?? [];
        return friendsJson.map((json) => User.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Không thể tải danh sách bạn bè: $e');
    }
  }

  /// GET /friend/requests - Lấy danh sách lời mời kết bạn đang chờ
  Future<List<FriendRequest>> getPendingRequests() async {
    try {
      final response = await _apiService.getWithAuth('/friend/requests');
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> requestsJson = response['data']['requests'] ?? [];
        return requestsJson.map((json) => FriendRequest.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Không thể tải lời mời kết bạn: $e');
    }
  }

  /// POST /friend/request - Gửi lời mời kết bạn
  Future<BaseResponse> sendFriendRequest(String receiverId) async {
    try {
      final response = await _apiService.postWithAuth('/friend/request', {
        'receiver_id': receiverId,
      });
      
      return BaseResponse.fromJson(response);
    } catch (e) {
      throw Exception('Không thể gửi lời mời kết bạn: $e');
    }
  }

  /// POST /friend/accept - Chấp nhận lời mời kết bạn
  Future<BaseResponse> acceptFriendRequest(String requestId) async {
    try {
      final response = await _apiService.postWithAuth('/friend/accept', {
        'request_id': requestId,
      });
      
      return BaseResponse.fromJson(response);
    } catch (e) {
      throw Exception('Không thể chấp nhận lời mời: $e');
    }
  }

  /// POST /friend/reject - Từ chối lời mời kết bạn
  Future<BaseResponse> rejectFriendRequest(String requestId) async {
    try {
      final response = await _apiService.postWithAuth('/friend/reject', {
        'request_id': requestId,
      });
      
      return BaseResponse.fromJson(response);
    } catch (e) {
      throw Exception('Không thể từ chối lời mời: $e');
    }
  }

  /// POST /friend/cancel - Hủy lời mời đã gửi
  Future<BaseResponse> cancelFriendRequest(String requestId) async {
    try {
      final response = await _apiService.postWithAuth('/friend/cancel', {
        'request_id': requestId,
      });
      
      return BaseResponse.fromJson(response);
    } catch (e) {
      throw Exception('Không thể hủy lời mời: $e');
    }
  }

  /// DELETE /friend/unfriend - Hủy kết bạn
  Future<BaseResponse> unfriend(String friendId) async {
    try {
      final response = await _apiService.deleteWithAuth('/friend/unfriend', {
        'friend_id': friendId,
      });
      
      return BaseResponse.fromJson(response);
    } catch (e) {
      throw Exception('Không thể hủy kết bạn: $e');
    }
  }
}
