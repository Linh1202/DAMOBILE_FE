import '../Repositories/ChatRepository.dart';
import '../Models/Chat.dart';
import '../Models/Message.dart';
import '../Models/HistoryMessage.dart';

class ChatService {
  final ChatRepository _chatRepository = ChatRepository();

  Future<List<Chat>> getChats() async {
    return await _chatRepository.getChats();
  }

  Future<Chat> getChatById(String id) async {
    return await _chatRepository.getChatById(id);
  }

  Future<Chat> createChat({
    required ChatType type,
    String? name,
    required List<String> participants,
  }) async {
    return await _chatRepository.createChat(
      type: type,
      name: name,
      participants: participants,
    );
  }

  Future<List<Message>> getMessages(String conversationId) async {
    return await _chatRepository.getMessages(conversationId);
  }

  Future<String> uploadMedia(String filePath) async {
    return await _chatRepository.uploadMedia(filePath);
  }

  Future<List<Chat>> getGroupsByCreator(String creatorId) async {
    return await _chatRepository.getGroupsByCreator(creatorId);
  }

  /// Search chats by name or participant username
  Future<List<Chat>> searchChats(String query, {String type = 'all'}) async {
    return await _chatRepository.searchChats(query, type: type);
  }
}