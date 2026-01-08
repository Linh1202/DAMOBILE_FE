import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:doanmobile/Providers/SocketProvider.dart';
import 'package:doanmobile/Services/AuthStorage.dart';
import 'package:doanmobile/Services/ChatService.dart';
import 'package:doanmobile/Services/MediaService.dart';
import 'package:doanmobile/Models/Message.dart';
import 'package:doanmobile/Models/Reaction.dart';
import 'package:doanmobile/Models/Api/SocketMessage.dart';
import 'package:doanmobile/Utils/Constants/AppColors.dart';
import 'package:doanmobile/Utils/Constants/AppEnums.dart';
import 'package:doanmobile/Utils/Handlers/NavigationHandler.dart';
import 'package:doanmobile/Widgets/Chat/MessageBubble.dart';
import 'package:doanmobile/Widgets/Chat/ChatInputBar.dart';
import 'package:doanmobile/Widgets/Avatars/UserAvatar.dart';
import 'package:doanmobile/Views/Main/CallView.dart';

class ChatDetailView extends ConsumerStatefulWidget {
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

class _ChatDetailViewState extends ConsumerState<ChatDetailView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final MediaService _mediaService = MediaService();
  final ImagePicker _imagePicker = ImagePicker();

  List<Message> _messages = [];
  String _currentUserId = "";
  String? _targetUserId;
  bool _isLoading = true;
  bool _isTyping = false;
  bool _isUploading = false;
  String _uploadingLabel = 'Đang gửi...';
  String? _typingUser;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    // Load current user
    final user = await AuthStorage.readUser();
    _currentUserId = user?['id']?.toString() ?? user?['_id']?.toString() ?? "";
    print('👤 _initChat: user=$user, _currentUserId=$_currentUserId');

    if (!widget.isGroup) {
      try {
        final chat = await _chatService.getChatById(widget.chatId);
        if (mounted) {
          setState(() {
            _targetUserId = chat.participants.firstWhere(
              (id) => id != _currentUserId,
              orElse: () => "",
            );
          });
        }
      } catch (e) {
        print("Error fetching chat details: $e");
      }
    }

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
    ref.read(socketServiceProvider).joinRoom(widget.chatId);
  }

  void _handleSocketMessage(SocketMessage message) {
    if (!mounted) return;

    switch (message.type) {
      case MessageType.chatMessage:
        print('💬 CHAT_MESSAGE: roomId=${message.roomId}, chatId=${widget.chatId}, match=${message.roomId == widget.chatId}');
        // Only add if it's for this room
        if (message.roomId == widget.chatId) {
          // Skip messages from current user (already added optimistically)
          if (message.senderId == _currentUserId) {
            print('💬 Skipping own message (optimistic update already added)');
            return;
          }
          
          // Check for duplicate (same content/media from same sender within 5 seconds)
          final incomingMediaUrl = message.payload?['media_url']?.toString();
          final isDuplicate = _messages.any((m) =>
            m.senderId == message.senderId &&
            m.content == (message.content ?? '') &&
            (m.mediaUrl ?? '') == (incomingMediaUrl ?? '') &&
            DateTime.now().difference(m.createdAt).inSeconds.abs() < 5
          );
          
          if (!isDuplicate) {
            final newMessage = Message(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              chatId: widget.chatId,
              senderId: message.senderId ?? "",
              content: message.content ?? "",
              mediaUrl: incomingMediaUrl,
              createdAt: message.timestamp ?? DateTime.now(),
              senderName: message.senderName,
              chatName: message.chatName,
            );
            setState(() {
              _messages = [..._messages, newMessage];
              _isTyping = false;
              _typingUser = null;
            });
            _scrollToBottom();
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

  void _handleReactionMessage(SocketMessage message) {
    if (message.roomId != widget.chatId) return;
    
    final payload = message.payload as Map<String, dynamic>?;
    if (payload == null) return;

    final messageId = payload['message_id']?.toString();
    final userId = payload['user_id']?.toString();
    final emoji = payload['emoji']?.toString();
    final action = payload['action']?.toString(); // "added", "removed", or "updated"

    if (messageId == null || userId == null || emoji == null || action == null) {
      print('❌ Invalid reaction payload: $payload');
      return;
    }

    print('👍 Reaction update: messageId=$messageId, action=$action, emoji=$emoji');

    setState(() {
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex == -1) {
        print('⚠️ Message not found for reaction: $messageId');
        return;
      }

      final message = _messages[messageIndex];
      List<Reaction> updatedReactions = List.from(message.reactions);

      switch (action) {
        case 'added':
          // Add new reaction if not already present
          if (!updatedReactions.any((r) => r.userId == userId && r.emoji == emoji)) {
            updatedReactions.add(Reaction(
              userId: userId,
              emoji: emoji,
              createdAt: DateTime.now(),
            ));
            print('✅ Reaction added');
          }
          break;

        case 'removed':
          // Remove the reaction
          updatedReactions.removeWhere((r) => r.userId == userId && r.emoji == emoji);
          print('✅ Reaction removed');
          break;

        case 'updated':
          // Update: remove old emoji from this user and add new one
          updatedReactions.removeWhere((r) => r.userId == userId);
          updatedReactions.add(Reaction(
            userId: userId,
            emoji: emoji,
            createdAt: DateTime.now(),
          ));
          print('✅ Reaction updated');
          break;

        default:
          print('⚠️ Unknown reaction action: $action');
      }

      // Update the message with new reactions
      final updatedMessage = Message(
        id: message.id,
        chatId: message.chatId,
        senderId: message.senderId,
        content: message.content,
        mediaUrl: message.mediaUrl,
        readBy: message.readBy,
        createdAt: message.createdAt,
        isEdited: message.isEdited,
        senderName: message.senderName,
        senderAvatarUrl: message.senderAvatarUrl,
        reactions: updatedReactions,
        chatName: message.chatName,
      );

      _messages[messageIndex] = updatedMessage;
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    print('📩 _sendMessage: text=$text, currentUserId=$_currentUserId');

    // Add message optimistically for instant UI feedback
    final newMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.chatId,
      senderId: _currentUserId,
      content: text,
      createdAt: DateTime.now(),
    );
    
    print('📩 Adding message to list: ${newMessage.content}, total messages: ${_messages.length + 1}');
    
    setState(() {
      _messages = [..._messages, newMessage];
    });

    // Send via WebSocket
    ref.read(socketServiceProvider).sendChatMessage(widget.chatId, text);

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    // With reverse: true, position 0 is the bottom (newest messages)
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _onTyping() {
    ref.read(socketServiceProvider).sendTyping(widget.chatId);
  }

  bool _isMine(String senderId) {
    return senderId == _currentUserId;
  }

  void _sendReaction(String messageId, String emoji) {
    print('👍 Sending reaction: messageId=$messageId, emoji=$emoji');
    ref.read(socketServiceProvider).sendReaction(
      widget.chatId,
      messageId,
      emoji,
    );
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Chọn ảnh từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.attach_file, color: AppColors.primary),
                title: const Text('Chọn file'),
                subtitle: Text(
                  'PDF, DOC, ZIP, ...',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
        _uploadingLabel = 'Đang gửi ảnh...';
      });

      // Upload image
      final file = File(pickedFile.path);
      final mediaUrl = await _mediaService.uploadMedia(file);

      // Add optimistic message
      final newMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        chatId: widget.chatId,
        senderId: _currentUserId,
        content: '',
        mediaUrl: mediaUrl,
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages = [..._messages, newMessage];
        _isUploading = false;
      });

      // Send via WebSocket with media_url
      ref.read(socketServiceProvider).sendChatMessage(
        widget.chatId,
        '',
        mediaUrl: mediaUrl,
      );

      _scrollToBottom();
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      if (pickedFile.path == null) return;

      setState(() {
        _isUploading = true;
        _uploadingLabel = 'Đang gửi file...';
      });

      // Upload file
      final file = File(pickedFile.path!);
      final mediaUrl = await _mediaService.uploadMedia(file);

      // Add optimistic message with file name as content
      final fileName = pickedFile.name;
      final newMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        chatId: widget.chatId,
        senderId: _currentUserId,
        content: '📎 $fileName',
        mediaUrl: mediaUrl,
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages = [..._messages, newMessage];
        _isUploading = false;
      });

      // Send via WebSocket with media_url and file name
      ref.read(socketServiceProvider).sendChatMessage(
        widget.chatId,
        '📎 $fileName',
        mediaUrl: mediaUrl,
      );

      _scrollToBottom();
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for incoming messages reactively
    ref.listen(socketMessageStreamProvider, (previous, next) {
      next.whenData(_handleSocketMessage);
    });

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
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show typing indicator at the top (index 0) when reversed
                          if (_isTyping && index == 0) {
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

                          // Adjust index for reversed list
                          final messageIndex = _isTyping 
                              ? _messages.length - index 
                              : _messages.length - 1 - index;
                          
                          if (messageIndex < 0 || messageIndex >= _messages.length) {
                            return const SizedBox.shrink();
                          }

                          final message = _messages[messageIndex];
                          final bool isMine = _isMine(message.senderId);
                          final bool prevIsMine = messageIndex > 0 
                              ? _isMine(_messages[messageIndex - 1].senderId) 
                              : !isMine;
                          final bool showAvatar = !isMine && (messageIndex == 0 || prevIsMine != isMine);

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
          // Upload loading indicator
          if (_isUploading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withOpacity(0.1),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _uploadingLabel,
                    style: TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ChatInputBar(
            controller: _messageController,
            onSend: _sendMessage,
            onChanged: (_) => _onTyping(),
            onAttachment: _showMediaPicker,
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
            if (widget.isGroup) {
              // Group call
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallView(
                    targetUserId: widget.chatId,
                    userName: widget.name,
                    isIncoming: false,
                  ),
                ),
              );
            } else if (_targetUserId != null && _targetUserId!.isNotEmpty) {
              // Direct call
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallView(
                    targetUserId: _targetUserId,
                    userName: widget.name,
                    isIncoming: false,
                  ),
                ),
              );
            }
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
    ref.read(socketServiceProvider).leaveRoom(widget.chatId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
