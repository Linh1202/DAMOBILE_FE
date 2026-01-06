import '../Repositories/FriendRepository.dart';
import '../Models/User.dart';
import '../Models/FriendRequest.dart';
import '../Models/Api/BaseResponse.dart';

class FriendService {
  final FriendRepository _friendRepository = FriendRepository();

  /// Lấy danh sách bạn bè
  Future<List<User>> getFriends() async {
    return await _friendRepository.getFriendList();
  }

  /// Lấy danh sách lời mời kết bạn đang chờ
  Future<List<FriendRequest>> getPendingRequests() async {
    return await _friendRepository.getPendingRequests();
  }

  /// Gửi lời mời kết bạn
  Future<BaseResponse> sendFriendRequest(String receiverId) async {
    return await _friendRepository.sendFriendRequest(receiverId);
  }

  /// Chấp nhận lời mời kết bạn
  Future<BaseResponse> acceptFriendRequest(String requestId) async {
    return await _friendRepository.acceptFriendRequest(requestId);
  }

  /// Từ chối lời mời kết bạn
  Future<BaseResponse> rejectFriendRequest(String requestId) async {
    return await _friendRepository.rejectFriendRequest(requestId);
  }

  /// Hủy lời mời đã gửi
  Future<BaseResponse> cancelFriendRequest(String requestId) async {
    return await _friendRepository.cancelFriendRequest(requestId);
  }

  /// Hủy kết bạn
  Future<BaseResponse> unfriend(String friendId) async {
    return await _friendRepository.unfriend(friendId);
  }
}
