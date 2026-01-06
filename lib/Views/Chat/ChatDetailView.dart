import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Utils/Handlers/NavigationHandler.dart';
import '../../Widgets/Chat/MessageBubble.dart';
import '../../Widgets/Chat/ChatInputBar.dart';
import '../../Widgets/Avatars/UserAvatar.dart';

class ChatDetailView extends StatefulWidget {
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final bool isGroup;

  const ChatDetailView({
    Key? key,
    required this.name,
    required this.avatarUrl,
    this.isOnline = false,
    this.isGroup = false,
  }) : super(key: key);

  @override
  _ChatDetailViewState createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      "content": "Chào bạn!",
      "createdAt": "09:00",
      "senderId": "other_user",
    },
    {
      "content": "Hi, bạn khỏe không?",
      "createdAt": "09:05",
      "senderId": "current_user",
    },
    {
      "content": "Mình khỏe! Bạn thì sao?",
      "createdAt": "09:10",
      "senderId": "other_user",
    },
    {
      "content": "Chiều nay đi cafe nhé!",
      "createdAt": "10:30",
      "senderId": "other_user",
    },
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        "content": _messageController.text.trim(),
        "createdAt": "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
        "senderId": "current_user",
      });
    });

    _messageController.clear();

    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isMine(String senderId) {
    return senderId == "current_user";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final bool isMine = _isMine(message["senderId"]);
                final bool prevIsMine = index > 0 ? _isMine(_messages[index - 1]["senderId"]) : !isMine;
                final bool showAvatar = !isMine && (index == 0 || prevIsMine != isMine);
                
                return MessageBubble(
                  content: message["content"],
                  createdAt: message["createdAt"],
                  senderId: message["senderId"],
                  avatarUrl: widget.avatarUrl,
                  showAvatar: showAvatar,
                );
              },
            ),
          ),
          ChatInputBar(
            controller: _messageController,
            onSend: _sendMessage,
            onAttachment: () {
            },
            onEmoji: () {
            },
            onVoice: () {
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: NavigationHandler.goBack,
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          UserAvatar(
            imagePath: widget.avatarUrl,
            name: widget.name,
            size: 40,
            isOnline: widget.isOnline,
            isGroup: widget.isGroup,
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (widget.isOnline)
                Text(
                  "Đang hoạt động",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.videocam_outlined, color: AppColors.textPrimary),
          onPressed: () {
          },
        ),
        IconButton(
          icon: Icon(Icons.info_outline, color: AppColors.textPrimary),
          onPressed: () {
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
