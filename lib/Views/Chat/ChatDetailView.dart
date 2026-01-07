import 'dart:async';
import 'package:flutter/material.dart';
import 'package:doanmobile/Services/AuthStorage.dart';
import 'package:doanmobile/Services/ChatService.dart';
import 'package:doanmobile/Services/SocketService.dart';
import 'package:doanmobile/Models/Message.dart';
import 'package:doanmobile/Models/Api/SocketMessage.dart';
import 'package:doanmobile/Utils/Constants/AppColors.dart';
import 'package:doanmobile/Utils/Constants/AppEnums.dart';
import 'package:doanmobile/Utils/Handlers/NavigationHandler.dart';
import 'package:doanmobile/Widgets/Chat/MessageBubble.dart';
import 'package:doanmobile/Widgets/Chat/ChatInputBar.dart';
import 'package:doanmobile/Widgets/Avatars/UserAvatar.dart';

class ChatDetailView extends StatefulWidget {
  final String chatId;
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final bool isGroup;

  const ChatDetailView({
    Key? key,
    required this.chatId,
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
  final ChatService _chatService = ChatService();
  final SocketService _socketService = SocketService.instance;

  List<Message> _messages = [];
  String _currentUserId = "";
  bool _isLoading = true;
  bool _isTyping = false;
  String? _typingUser;
  StreamSubscription<SocketMessage>? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    // Load current user
    final user = await AuthStorage.readUser();
    _currentUserId = user?['id']?.toString() ?? user?['_id']?.toString() ?? "";

    // Load message history from API
    try {
      final messages = await _chatService.getMessages(widget.chatId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    // Join room via WebSocket
    _socketService.joinRoom(widget.chatId);

    // Listen for incoming messages
    _socketSubscription = _socketService.messageStream.listen(_handleSocketMessage);
  }

  void _handleSocketMessage(SocketMessage message) {
    if (!mounted) return;

    switch (message.type) {
      case MessageType.chatMessage:
        print('💬 CHAT_MESSAGE: roomId=${message.roomId}, chatId=${widget.chatId}, match=${message.roomId == widget.chatId}');
        // Only add if it's for this room
        if (message.roomId == widget.chatId) {
          // Check for duplicate (same content from same sender within 5 seconds)
          final isDuplicate = _messages.any((m) =>
            m.senderId == message.senderId &&
            m.content == message.content &&
            DateTime.now().difference(m.createdAt).inSeconds.abs() < 5
          );
          
          if (!isDuplicate) {
            final newMessage = Message(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              chatId: widget.chatId,
              senderId: message.senderId ?? "",
              content: message.content ?? "",
              mediaUrl: message.payload?['media_url'],
              createdAt: message.timestamp ?? DateTime.now(),
              senderName: message.senderName,
            );
            setState(() {
              _messages.add(newMessage);
              _isTyping = false;
              _typingUser = null;
            });
            _scrollToBottom();
          }
        }
        break;

      case MessageType.history:
        // Handle history message (list of messages)
        if (message.payload is List) {
          final historyMessages = (message.payload as List)
              .map((json) => Message.fromJson(json))
              .toList();
          setState(() {
            _messages = historyMessages;
          });
          _scrollToBottom();
        }
        break;

      case MessageType.typing:
        if (message.roomId == widget.chatId && 
            message.senderId != _currentUserId) {
          setState(() {
            _isTyping = true;
            _typingUser = message.senderName;
          });
          // Hide typing indicator after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _isTyping = false;
                _typingUser = null;
              });
            }
          });
        }
        break;

      default:
        break;
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add message optimistically for instant UI feedback
    final newMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.chatId,
      senderId: _currentUserId,
      content: text,
      createdAt: DateTime.now(),
    );
    
    setState(() {
      _messages.add(newMessage);
    });

    // Send via WebSocket
    _socketService.sendChatMessage(widget.chatId, text);

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTyping() {
    _socketService.sendTyping(widget.chatId);
  }

  bool _isMine(String senderId) {
    return senderId == _currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('Chưa có tin nhắn'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show typing indicator at the end
                          if (_isTyping && index == _messages.length) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8, top: 8),
                              child: Row(
                                children: [
                                  UserAvatar(
                                    imagePath: widget.avatarUrl,
                                    name: widget.name,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_typingUser ?? widget.name} đang gõ...',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final message = _messages[index];
                          final bool isMine = _isMine(message.senderId);
                          final bool prevIsMine = index > 0 
                              ? _isMine(_messages[index - 1].senderId) 
                              : !isMine;
                          final bool showAvatar = !isMine && (index == 0 || prevIsMine != isMine);

                          return MessageBubble(
                            content: message.content,
                            createdAt: message.formattedTime,
                            senderId: message.senderId,
                            currentUserId: _currentUserId,
                            avatarUrl: widget.avatarUrl,
                            showAvatar: showAvatar,
                            mediaUrl: message.mediaUrl,
                          );
                        },
                      ),
          ),
          ChatInputBar(
            controller: _messageController,
            onSend: _sendMessage,
            onChanged: (_) => _onTyping(),
            onAttachment: () {
              // TODO: Upload media
            },
            onEmoji: () {
              // TODO: Emoji picker
            },
            onVoice: () {
              // TODO: Voice message
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_isTyping)
                  Text(
                    "Đang gõ...",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (widget.isOnline)
                  Text(
                    "Đang hoạt động",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.videocam_outlined, color: AppColors.textPrimary),
          onPressed: () {
            // TODO: Video call
          },
        ),
        IconButton(
          icon: Icon(Icons.info_outline, color: AppColors.textPrimary),
          onPressed: () {
            // TODO: Chat info
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Leave room when closing chat
    _socketService.leaveRoom(widget.chatId);
    _socketSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
