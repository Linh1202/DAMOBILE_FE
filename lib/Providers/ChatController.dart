import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Models/Message.dart';
import '../Models/Reaction.dart';
import '../Models/Api/SocketMessage.dart';
import '../Services/ChatService.dart';
import '../Services/MediaService.dart';
import '../Services/GroupService.dart';
import '../Services/AuthStorage.dart';
import '../Providers/SocketProvider.dart';
import '../Utils/Constants/AppEnums.dart';

class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isTyping;
  final String? typingUser;
  final bool isUploading;
  final String uploadingLabel;
  final Map<String, String> participantNames;
  final Map<String, String> participantAvatars;
  final String? creatorId;
  final bool targetUserIsOnline;
  final bool showEmoji;
  final String currentUserId;
  final String? targetUserId;

  ChatState({
    this.messages = const [],
    this.isLoading = true,
    this.isTyping = false,
    this.typingUser,
    this.isUploading = false,
    this.uploadingLabel = 'Đang gửi...',
    this.participantNames = const {},
    this.participantAvatars = const {},
    this.creatorId,
    this.targetUserIsOnline = false,
    this.showEmoji = false,
    this.currentUserId = "",
    this.targetUserId,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isTyping,
    String? typingUser,
    bool? isUploading,
    String? uploadingLabel,
    Map<String, String>? participantNames,
    Map<String, String>? participantAvatars,
    String? creatorId,
    bool? targetUserIsOnline,
    bool? showEmoji,
    String? currentUserId,
    String? targetUserId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      typingUser: typingUser ?? this.typingUser,
      isUploading: isUploading ?? this.isUploading,
      uploadingLabel: uploadingLabel ?? this.uploadingLabel,
      participantNames: participantNames ?? this.participantNames,
      participantAvatars: participantAvatars ?? this.participantAvatars,
      creatorId: creatorId ?? this.creatorId,
      targetUserIsOnline: targetUserIsOnline ?? this.targetUserIsOnline,
      showEmoji: showEmoji ?? this.showEmoji,
      currentUserId: currentUserId ?? this.currentUserId,
      targetUserId: targetUserId ?? this.targetUserId,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  final ChatService _chatService = ChatService();
  final MediaService _mediaService = MediaService();
  final GroupService _groupService = GroupService();
  final Ref _ref;
  final String chatId;
  final bool isGroup;

  ChatController(this._ref, this.chatId, this.isGroup) : super(ChatState()) {
    initChat();
  }

  Future<void> initChat() async {
    // Load current user
    final user = await AuthStorage.readUser();
    final currentUserId = user?['id']?.toString() ?? user?['_id']?.toString() ?? "";
    
    state = state.copyWith(currentUserId: currentUserId);

    // Load chat details
    try {
      final chat = await _chatService.getChatById(chatId);
      
      String? targetUserId;
      Map<String, String> participantNames = {};
      Map<String, String> participantAvatars = {};

      if (!isGroup) {
        targetUserId = chat.participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => "",
        );
      }

      if (chat.participantDetails != null) {
        for (final participant in chat.participantDetails!) {
          participantNames[participant.id] = participant.fullName;
          if (participant.avatarUrl != null && participant.avatarUrl!.isNotEmpty) {
            participantAvatars[participant.id] = participant.avatarUrl!;
          }
        }
      }

      state = state.copyWith(
        targetUserId: targetUserId,
        participantNames: participantNames,
        participantAvatars: participantAvatars,
      );
    } catch (e) {
      //
    }

    // Load creatorId if group
    if (isGroup) {
      try {
        final group = await _groupService.getGroupById(chatId);
        state = state.copyWith(creatorId: group.creatorId);
      } catch (e) {
        //
      }
    }

    // Load messages
    try {
      final messages = await _chatService.getMessages(chatId);
      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }

    // Join room
    _ref.read(socketServiceProvider).joinRoom(chatId);
  }

  void handleSocketMessage(SocketMessage message) {
    if (message.isOnline != null && message.senderId != null) {
      if (!isGroup && message.senderId == state.targetUserId) {
        state = state.copyWith(targetUserIsOnline: message.isOnline!);
      }
    }

    switch (message.type) {
      case MessageType.chatMessage:
        if (message.roomId == chatId) {
          if (message.senderId == state.currentUserId) return;
          
          final incomingMediaUrl = message.payload?['media_url']?.toString();
          final isDuplicate = state.messages.any((m) =>
            m.senderId == message.senderId &&
            m.content == (message.content ?? '') &&
            (m.mediaUrl ?? '') == (incomingMediaUrl ?? '') &&
            DateTime.now().difference(m.createdAt).inSeconds.abs() < 5
          );
          
          if (!isDuplicate) {
            final newMessage = Message(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              chatId: chatId,
              senderId: message.senderId ?? "",
              content: message.content ?? "",
              mediaUrl: incomingMediaUrl,
              createdAt: message.timestamp ?? DateTime.now(),
              senderName: message.senderName,
              chatName: message.chatName,
            );
            state = state.copyWith(
              messages: [...state.messages, newMessage],
              isTyping: false,
              typingUser: null,
            );
          }
        }
        break;

      case MessageType.reaction:
        _handleReactionMessage(message);
        break;

      case MessageType.history:
        if (message.payload is List) {
          final historyMessages = (message.payload as List)
              .map((json) => Message.fromJson(json))
              .toList();
          state = state.copyWith(messages: historyMessages);
        }
        break;

      case MessageType.typing:
        if (message.roomId == chatId && message.senderId != state.currentUserId) {
          state = state.copyWith(
            isTyping: true,
            typingUser: message.senderName,
          );
          Future.delayed(const Duration(seconds: 3), () {
            if (state.typingUser == message.senderName) {
              state = state.copyWith(isTyping: false, typingUser: null);
            }
          });
        }
        break;

      default:
        break;
    }
  }

  void _handleReactionMessage(SocketMessage message) {
    if (message.roomId != chatId) return;
    
    final payload = message.payload as Map<String, dynamic>?;
    if (payload == null) return;

    final messageId = payload['message_id']?.toString();
    final userId = payload['user_id']?.toString();
    final emoji = payload['emoji']?.toString();
    final action = payload['action']?.toString();
    final reactionCountsData = payload['reaction_counts'] as Map<String, dynamic>?;

    if (messageId == null || userId == null || emoji == null || action == null) return;

    final messageIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final msg = state.messages[messageIndex];
    List<Reaction> updatedReactions = List.from(msg.reactions);

    switch (action) {
      case 'added':
        if (!updatedReactions.any((r) => r.userId == userId && r.emoji == emoji)) {
          updatedReactions.add(Reaction(userId: userId, emoji: emoji, createdAt: DateTime.now()));
        }
        break;
      case 'removed':
        updatedReactions.removeWhere((r) => r.userId == userId && r.emoji == emoji);
        break;
      case 'updated':
        updatedReactions.removeWhere((r) => r.userId == userId);
        updatedReactions.add(Reaction(userId: userId, emoji: emoji, createdAt: DateTime.now()));
        break;
    }

    // Parse reaction counts if provided
    Map<String, int> updatedCounts = msg.reactionCounts;
    if (reactionCountsData != null) {
      updatedCounts = {};
      reactionCountsData.forEach((key, value) {
        updatedCounts[key] = value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }

    final updatedMessage = Message(
      id: msg.id,
      chatId: msg.chatId,
      senderId: msg.senderId,
      content: msg.content,
      mediaUrl: msg.mediaUrl,
      readBy: msg.readBy,
      createdAt: msg.createdAt,
      isEdited: msg.isEdited,
      senderName: msg.senderName,
      senderAvatarUrl: msg.senderAvatarUrl,
      reactions: updatedReactions,
      reactionCounts: updatedCounts,
      chatName: msg.chatName,
    );

    final newMessages = [...state.messages];
    newMessages[messageIndex] = updatedMessage;
    state = state.copyWith(messages: newMessages);
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final newMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderId: state.currentUserId,
      content: text,
      createdAt: DateTime.now(),
    );
    
    state = state.copyWith(messages: [...state.messages, newMessage]);
    _ref.read(socketServiceProvider).sendChatMessage(chatId, text);
  }

  void sendReaction(String messageId, String emoji) {
    _ref.read(socketServiceProvider).sendReaction(chatId, messageId, emoji);
  }

  void sendTyping() {
    _ref.read(socketServiceProvider).sendTyping(chatId);
  }

  Future<void> uploadAndSendMedia(File file, {required bool isImage, String? fileName}) async {
    state = state.copyWith(
      isUploading: true,
      uploadingLabel: isImage ? 'Đang gửi ảnh...' : 'Đang gửi file...',
    );

    try {
      final mediaUrl = await _mediaService.uploadMedia(file);
      final content = fileName != null ? '📎 $fileName' : '';

      final newMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId,
        senderId: state.currentUserId,
        content: content,
        mediaUrl: mediaUrl,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, newMessage],
        isUploading: false,
      );

      _ref.read(socketServiceProvider).sendChatMessage(
        chatId,
        content,
        mediaUrl: mediaUrl,
      );
    } catch (e) {
      state = state.copyWith(isUploading: false);
      rethrow;
    }
  }

  void toggleEmoji(bool show) {
    state = state.copyWith(showEmoji: show);
  }

  Future<bool> addMember(String userId) async {
    try {
      final success = await _groupService.addMember(chatId, userId);
      if (success) {
        await initChat(); // Refresh participant lists
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> removeMember(String userId) async {
    try {
      final success = await _groupService.removeMember(chatId, userId);
      if (success) {
        await initChat(); // Refresh participant lists
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> dissolveGroup() async {
    try {
      return await _groupService.dissolveGroup(chatId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _ref.read(socketServiceProvider).leaveRoom(chatId);
    super.dispose();
  }
}

final chatControllerProvider = StateNotifierProvider.family<ChatController, ChatState, ({String chatId, bool isGroup})>((ref, args) {
  return ChatController(ref, args.chatId, args.isGroup);
});