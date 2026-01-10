import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doanmobile/Providers/ChatController.dart';
import 'package:doanmobile/Widgets/Chat/MessageBubble.dart';
import 'package:doanmobile/Widgets/Avatars/UserAvatar.dart';
import 'package:doanmobile/Utils/Constants/AppColors.dart';

class ChatMessageList extends StatelessWidget {
  final ScrollController scrollController;
  final ChatState chatState;
  final bool isGroup;
  final String avatarUrl;
  final String name;
  final Function(String messageId, String emoji) onReaction;

  const ChatMessageList({
    Key? key,
    required this.scrollController,
    required this.chatState,
    required this.isGroup,
    required this.avatarUrl,
    required this.name,
    required this.onReaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (chatState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chatState.messages.isEmpty) {
      return const Center(child: Text('Chưa có tin nhắn'));
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chatState.messages.length + (chatState.isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Show typing indicator at the top (index 0) when reversed
        if (chatState.isTyping && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
            child: Row(
              children: [
                UserAvatar(
                  imagePath: avatarUrl,
                  name: name,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  '${chatState.typingUser ?? name} đang gõ...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }

        // Adjust index for reversed list
        final messageIndex = chatState.isTyping 
            ? chatState.messages.length - index 
            : chatState.messages.length - 1 - index;
        
        if (messageIndex < 0 || messageIndex >= chatState.messages.length) {
          return const SizedBox.shrink();
        }

        final message = chatState.messages[messageIndex];
        final bool isMine = message.senderId == chatState.currentUserId;
        
        // Check if previous message (later in time, so index - 1 in sorted list) was from same sender
        final bool prevSameSender = messageIndex > 0 
            ? chatState.messages[messageIndex - 1].senderId == message.senderId
            : false;
        
        final bool showAvatar = !isMine && (messageIndex == 0 || !prevSameSender);
        
        // Show sender name if it's a group chat, not mine, and first message in a sequence
        final bool showSenderName = isGroup && !isMine && !prevSameSender;

        // Resolve sender avatar
        final senderAvatarUrl = isGroup
            ? (message.senderAvatarUrl ?? chatState.participantAvatars[message.senderId] ?? "")
            : avatarUrl;

        return MessageBubble(
          id: message.id,
          content: message.content,
          createdAt: message.formattedTime,
          senderId: message.senderId,
          currentUserId: chatState.currentUserId,
          avatarUrl: senderAvatarUrl,
          showAvatar: showAvatar,
          mediaUrl: message.mediaUrl,
          reactions: message.reactions,
          reactionCounts: message.reactionCounts,
          onReaction: (emoji) => onReaction(message.id, emoji),
          senderName: message.senderName ?? chatState.participantNames[message.senderId],
          showSenderName: showSenderName,
        );
      },
    );
  }
}