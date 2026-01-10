import '../Services/ApiService.dart';
import '../Models/Chat.dart';
import '../Models/Message.dart';
import '../Utils/Constants/ApiEndpoints.dart';

class ChatRepository {
  final ApiService _apiService = ApiService();

  Future<List<Chat>> getChats() async {
    try {
      final response = await _apiService.getWithAuth(ApiEndpoints.chat);
      if (response['success'] == true && response['data'] != null) {
        final chatsData = response['data']['chats'];
        if (chatsData is List) {
          return chatsData.map((json) {
            if (json is Map<String, dynamic>) {
              return Chat.fromJson(json);
            }
            return Chat.fromJson(Map<String, dynamic>.from(json as Map));
          }).where((chat) => !chat.isDeleted).toList(); // Lọc bỏ chats đã bị xóa
        }
      }
      return [];
    } catch (e, stackTrace) {
      throw Exception('Không thể tải danh sách cuộc trò chuyện: $e');
    }
  }

  Future<Chat> getChatById(String id) async {
    try {
      final response = await _apiService.getWithAuth(ApiEndpoints.chatById(id));
      if (response['success'] == true && response['data'] != null) {
        return Chat.fromJson(response['data']['chat'] ?? response['data']);
      }
      throw Exception('Không tìm thấy cuộc trò chuyện');
    } catch (e) {
      throw Exception('Không thể tải thông tin cuộc trò chuyện: $e');
    }
  }

  Future<Chat> createChat({
    required ChatType type,
    String? name,
    required List<String> participants,
  }) async {
    try {
      final response = await _apiService.postWithAuth(ApiEndpoints.chat, {
        'type': type == ChatType.group ? 'group' : 'private',
        if (name != null) 'name': name,
        'participants': participants,
      });
      
      // BE returns success but may not return chat data
      if (response['success'] == true) {
        if (response['data'] != null) {
          return Chat.fromJson(response['data']['chat'] ?? response['data']);
        }
        // Return a placeholder - caller should reload chat list
        return Chat(
          id: '',
          type: type,
          name: name,
          participants: participants,
          updatedAt: DateTime.now(),
        );
      }
      throw Exception(response['message'] ?? 'Không thể tạo cuộc trò chuyện');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi tạo cuộc trò chuyện: $e');
    }
  }

  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final response = await _apiService.getWithAuth(
        ApiEndpoints.messagesByConversationId(conversationId),
      );
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> messagesJson = response['data']['messages'] ?? [];
        return messagesJson.map((json) => Message.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải tin nhắn: $e');
    }
  }

  Future<String> uploadMedia(String filePath) async {
    try {
      final response = await _apiService.postMultipartWithAuth(
        ApiEndpoints.uploadMedia,
        filePath,
      );
      if (response['success'] == true && response['data'] != null) {
        return response['data']['url'];
      }
      throw Exception('Không thể tải tệp lên');
    } catch (e) {
      throw Exception('Lỗi tải tệp: $e');
    }
  }

  Future<List<Chat>> getGroupsByCreator(String creatorId) async {
    try {
      final response = await _apiService.getWithAuth(
        ApiEndpoints.groupByCreator(creatorId),
      );
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> groupsJson = response['data']['groups'] ?? [];
        return groupsJson.map((json) => Chat.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải danh sách nhóm: $e');
    }
  }
}