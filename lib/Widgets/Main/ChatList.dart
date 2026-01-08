import 'package:flutter/material.dart';
import 'package:doanmobile/Services/AuthStorage.dart';
import 'package:doanmobile/Services/ChatService.dart';
import 'package:doanmobile/Models/Chat.dart';
import 'package:doanmobile/Widgets/Chat/ChatListItem.dart';
import 'package:doanmobile/Views/Chat/ChatDetailView.dart';

class ChatList extends StatefulWidget {
  const ChatList({Key? key}) : super(key: key);

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final ChatService _chatService = ChatService();
  Future<List<Chat>>? _chatsFuture;
  String _currentUserId = "";

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final user = await AuthStorage.readUser();
    if (mounted) {
      setState(() {
        _currentUserId = user?['id']?.toString() ?? user?['_id']?.toString() ?? "";
        _chatsFuture = _chatService.getChats();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chatsFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _chatsFuture = _chatService.getChats();
        });
      },
      child: FutureBuilder<List<Chat>>(
        future: _chatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Lỗi: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chưa có cuộc hội thoại nào'));
          }

          final chats = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final isGroup = chat.type == ChatType.group;
              final name = chat.getChatName(_currentUserId);
              final avatar = chat.getChatAvatar(_currentUserId) ?? "Assets/Images/anh1.png";
              final lastMsg = chat.lastMessage?.content ?? "Chưa có tin nhắn";
              final time = chat.lastMessage?.formattedTime ?? "";

              return ChatListItem(
                name: name,
                avatarUrl: avatar,
                content: lastMsg,
                updatedAt: time,
                unreadCount: 0,
                isGroup: isGroup,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailView(
                        chatId: chat.id,
                        name: name,
                        avatarUrl: avatar,
                        isOnline: !isGroup,
                        isGroup: isGroup,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
