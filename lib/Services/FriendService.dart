import '../Repositories/FriendRepository.dart';
import '../Models/User.dart';
import '../Models/FriendRequest.dart';
import '../Models/Api/BaseResponse.dart';

class FriendService {
  final FriendRepository _friendRepository = FriendRepository();

  Future<List<User>> getFriends() async {
    return await _friendRepository.getFriendList();
  }

  Future<List<FriendRequest>> getPendingRequests() async {
    return await _friendRepository.getPendingRequests();
  }

  Future<BaseResponse> sendFriendRequest(String receiverId) async {
    return await _friendRepository.sendFriendRequest(receiverId);
  }

  Future<BaseResponse> acceptFriendRequest(String requestId) async {
    return await _friendRepository.acceptFriendRequest(requestId);
  }

  Future<BaseResponse> rejectFriendRequest(String requestId) async {
    return await _friendRepository.rejectFriendRequest(requestId);
  }

  Future<BaseResponse> cancelFriendRequest(String requestId) async {
    return await _friendRepository.cancelFriendRequest(requestId);
  }

  Future<BaseResponse> unfriend(String friendId) async {
    return await _friendRepository.unfriend(friendId);
  }
}