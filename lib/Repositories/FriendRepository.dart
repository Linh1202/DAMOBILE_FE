import '../Services/ApiService.dart';
import '../Models/User.dart';
import '../Models/FriendRequest.dart';
import '../Models/Api/BaseResponse.dart';
import '../Utils/Constants/ApiEndpoints.dart';

class FriendRepository {
  final ApiService _apiService = ApiService();

  Future<List<User>> getFriendList() async {
    try {
      final response = await _apiService.getWithAuth(ApiEndpoints.friendList);
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> friendsJson = response['data']['friends'] ?? [];
        return friendsJson.map((json) => User.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Không thể tải danh sách bạn bè: $e');
    }
  }

  Future<List<FriendRequest>> getPendingRequests() async {
    try {
      final response = await _apiService.getWithAuth(ApiEndpoints.friendRequests);
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> requestsJson = response['data']['requests'] ?? [];
        return requestsJson.map((json) => FriendRequest.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Không thể tải lời mời kết bạn: $e');
    }
  }

  Future<BaseResponse> sendFriendRequest(String receiverId) async {
    try {
      final response = await _apiService.postWithAuth(ApiEndpoints.friendRequest, {
        'receiver_id': receiverId,
      });
      
      return BaseResponse.fromJson(response);
    } catch (e) {
      throw Exception('Không thể gửi lời mời kết bạn: $e');
    }
  }

  Future<BaseResponse> acceptFriendRequest(String requestId) async {
    try {
      final response = await _apiService.postWithAuth(ApiEndpoints.friendAccept, {
        'request_id': requestId,
      });
      
      return BaseResponse.fromJson(response);
    } catch (e) {
      throw Exception('Không thể chấp nhận lời mời: $e');
    }
  }

  Future<BaseResponse> rejectFriendRequest(String requestId) async {
    try {
      final response = await _apiService.postWithAuth(ApiEndpoints.friendReject, {
        'request_id': requestId,
      });
      
      return BaseResponse.fromJson(response);
    } catch (e) {
      throw Exception('Không thể từ chối lời mời: $e');
    }
  }

  Future<BaseResponse> cancelFriendRequest(String requestId) async {
    try {
      final response = await _apiService.postWithAuth(ApiEndpoints.friendCancel, {
        'request_id': requestId,
      });
      
      return BaseResponse.fromJson(response);
    } catch (e) {
      throw Exception('Không thể hủy lời mời: $e');
    }
  }

  Future<BaseResponse> unfriend(String friendId) async {
    try {
      final response = await _apiService.deleteWithAuth(ApiEndpoints.friendUnfriend, {
        'friend_id': friendId,
      });
      
      return BaseResponse.fromJson(response);
    } catch (e) {
      throw Exception('Không thể hủy kết bạn: $e');
    }
  }
}