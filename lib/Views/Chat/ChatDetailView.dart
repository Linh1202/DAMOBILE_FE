import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:doanmobile/Providers/SocketProvider.dart';
import 'package:doanmobile/Services/SocketService.dart';
import 'package:doanmobile/Services/AuthStorage.dart';
import 'package:doanmobile/Services/ChatService.dart';
import 'package:doanmobile/Services/MediaService.dart';
import 'package:doanmobile/Services/EmojiService.dart';
import 'package:doanmobile/Services/FriendService.dart';
import 'package:doanmobile/Services/GroupService.dart';
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
  final FocusNode _focusNode = FocusNode();

  List<Message> _messages = [];
  String _currentUserId = "";
  String? _targetUserId;
  bool _isLoading = true;
  bool _isTyping = false;
  bool _isUploading = false;
  bool _showEmoji = false;
  String _uploadingLabel = 'Đang gửi...';
  String? _typingUser;
  Map<String, String> _participantNames = {};
  Map<String, String> _participantAvatars = {}; // Lưu avatar của từng người tham gia
  SocketService? _socketService;
  String? _creatorId;

  bool get _isCreator => _creatorId != null && _creatorId == _currentUserId;

  @override
  void initState() {
    super.initState();
    _initChat();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showEmoji = false;
        });
      }
    });
  }

  Future<void> _initChat() async {
    // Load current user
    final user = await AuthStorage.readUser();
    _currentUserId = user?['id']?.toString() ?? user?['_id']?.toString() ?? "";
    print('👤 _initChat: user=$user, _currentUserId=$_currentUserId');

    // Load chat details để lấy participant names
    try {
      final chat = await _chatService.getChatById(widget.chatId);
      if (mounted) {
        setState(() {
          if (!widget.isGroup) {
            _targetUserId = chat.participants.firstWhere(
              (id) => id != _currentUserId,
              orElse: () => "",
            );
          }
          // Tạo map participantNames và participantAvatars từ participantDetails
          if (chat.participantDetails != null) {
            for (final participant in chat.participantDetails!) {
              _participantNames[participant.id] = participant.fullName;
              if (participant.avatarUrl != null && participant.avatarUrl!.isNotEmpty) {
                _participantAvatars[participant.id] = participant.avatarUrl!;
              }
            }
          }
        });
      }
    } catch (e) {
      print("Error fetching chat details: $e");
    }

    // Load creatorId từ Group API (vì Chat entity không có creator_id)
    if (widget.isGroup) {
      try {
        final groupService = GroupService();
        final group = await groupService.getGroupById(widget.chatId);
        if (mounted) {
          setState(() {
            _creatorId = group.creatorId;
            print('🔍 DEBUG: group.creatorId=${group.creatorId}, _creatorId=$_creatorId, _currentUserId=$_currentUserId, _isCreator=$_isCreator');
          });
        }
      } catch (e) {
        print("Error fetching group details: $e");
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

  void _showGroupMembers() async {
    final groupService = GroupService();
    
    try {
      final chat = await _chatService.getChatById(widget.chatId);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Thành viên nhóm (${chat.participantDetails?.length ?? 0})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: chat.participantDetails?.length ?? 0,
                  itemBuilder: (context, index) {
                    final user = chat.participantDetails![index];
                    final isCurrentUser = user.id == _currentUserId;
                    final isCreatorMember = user.id == _creatorId;
                    
                    return ListTile(
                      leading: UserAvatar(
                        imagePath: user.avatarUrl,
                        name: user.fullName,
                        size: 40,
                      ),
                      title: Row(
                        children: [
                          Text(
                            user.fullName,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (isCreatorMember) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      // Nút xóa thành viên (chỉ creator thấy, không xóa được chính mình hoặc creator khác)
                      trailing: (_isCreator && !isCurrentUser && !isCreatorMember)
                          ? IconButton(
                              icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('Xóa thành viên'),
                                    content: Text('Bạn có chắc muốn xóa ${user.fullName} khỏi nhóm?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: Text('Xóa', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await groupService.removeMember(widget.chatId, user.id);
                                    Navigator.pop(sheetContext);
                                    if (mounted) {
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(content: Text('Đã xóa ${user.fullName}'), backgroundColor: Colors.green),
                                      );
                                      _showGroupMembers(); // Refresh list
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                }
                              },
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải thành viên: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDissolveGroupConfirm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Giải tán nhóm'),
        content: Text(
          'Bạn có chắc muốn giải tán nhóm "${widget.name}"?\n\n'
          'Tất cả tin nhắn và dữ liệu nhóm sẽ bị xóa vĩnh viễn. '
          'Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Giải tán', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final groupService = GroupService();
        final success = await groupService.dissolveGroup(widget.chatId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã giải tán nhóm'), backgroundColor: Colors.green),
          );
          // Quay về màn hình trước
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showAddMemberDialog() async {
    // Import FriendService to get friends list
    final friendService = FriendService();
    final groupService = GroupService();

    try {
      final friends = await friendService.getFriends();
      final chat = await _chatService.getChatById(widget.chatId);
      
      // Filter out users who are already members
      final existingMemberIds = chat.participants.toSet();
      final availableFriends = friends.where((f) => !existingMemberIds.contains(f.id)).toList();

      if (!mounted) return;

      if (availableFriends.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tất cả bạn bè đã là thành viên nhóm'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.background,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Thêm thành viên',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableFriends.length,
                  itemBuilder: (context, index) {
                    final friend = availableFriends[index];
                    return ListTile(
                      leading: UserAvatar(
                        imagePath: friend.avatarUrl,
                        name: friend.fullName,
                        size: 40,
                      ),
                      title: Text(
                        friend.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        friend.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.person_add, color: AppColors.primary),
                        onPressed: () async {
                          try {
                            final success = await groupService.addMember(widget.chatId, friend.id);
                            Navigator.pop(context);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? 'Đã thêm ${friend.fullName}' : 'Không thể thêm thành viên'),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            Navigator.pop(context);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lưu reference socket service để sử dụng trong dispose()
    _socketService ??= ref.read(socketServiceProvider);
    
    // Listen for incoming messages reactively
    ref.listen(socketMessageStreamProvider, (previous, next) {
      next.whenData(_handleSocketMessage);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: WillPopScope(
        onWillPop: () {
          if (_showEmoji) {
            setState(() {
              _showEmoji = false;
            });
            return Future.value(false);
          }
          return Future.value(true);
        },
        child: Column(
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
                            
                            // Kiểm tra xem tin nhắn trước đó có phải từ cùng người gửi không
                            final bool prevSameSender = messageIndex > 0 
                                ? _messages[messageIndex - 1].senderId == message.senderId
                                : false;
                            // Hiển thị tên người gửi nếu là group chat và là tin đầu tiên trong chuỗi
                            final bool showSenderName = widget.isGroup && !isMine && !prevSameSender;

                            // Lấy avatar của người gửi: trong group chat lấy từ _participantAvatars, chat 1-1 dùng widget.avatarUrl
                            final senderAvatarUrl = widget.isGroup
                                ? (message.senderAvatarUrl ?? _participantAvatars[message.senderId] ?? widget.avatarUrl)
                                : widget.avatarUrl;

                            return MessageBubble(
                              id: message.id,
                              content: message.content,
                              createdAt: message.formattedTime,
                              senderId: message.senderId,
                              currentUserId: _currentUserId,
                              avatarUrl: senderAvatarUrl,
                              showAvatar: showAvatar,
                              mediaUrl: message.mediaUrl,
                              reactions: message.reactions,
                              onReaction: (emoji) => _sendReaction(message.id, emoji),
                              senderName: message.senderName ?? _participantNames[message.senderId],
                              showSenderName: showSenderName,
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
              focusNode: _focusNode,
              onSend: _sendMessage,
              onChanged: (_) => _onTyping(),
              onAttachment: _showMediaPicker,
              onEmoji: () {
                setState(() {
                  _showEmoji = !_showEmoji;
                  if (_showEmoji) {
                    _focusNode.unfocus();
                  } else {
                    _focusNode.requestFocus();
                  }
                });
              },
              onVoice: () {
                // TODO: Voice message
              },
            ),
            if (_showEmoji)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (Category? category, Emoji emoji) {
                    _messageController.text = _messageController.text + emoji.emoji;
                    _onTyping();
                    EmojiService.addRecentEmoji(emoji.emoji);
                  },
                  onBackspacePressed: () {
                    final text = _messageController.text;
                    if (text.isNotEmpty) {
                      _messageController.text = text.characters.skipLast(1).toString();
                    }
                  },
                  config: Config(
                    height: 256,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      columns: 7,
                      emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                      verticalSpacing: 0,
                      horizontalSpacing: 0,
                      gridPadding: EdgeInsets.zero,
                      backgroundColor: AppColors.background,
                      buttonMode: ButtonMode.MATERIAL,
                      loadingIndicator: const SizedBox.shrink(),
                      noRecents: const Text(
                        'Chưa có emoji gần đây',
                        style: TextStyle(fontSize: 20, color: Colors.black26),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    categoryViewConfig: CategoryViewConfig(
                      indicatorColor: AppColors.primary,
                      iconColor: Colors.grey,
                      iconColorSelected: AppColors.primary,
                      backspaceColor: AppColors.primary,
                      backgroundColor: AppColors.background,
                    ),
                    skinToneConfig: const SkinToneConfig(
                      dialogBackgroundColor: Colors.white,
                      indicatorColor: Colors.grey,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
        if (widget.isGroup)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (value) {
              switch (value) {
                case 'view_members':
                  _showGroupMembers();
                  break;
                case 'add_member':
                  _showAddMemberDialog();
                  break;
                case 'dissolve_group':
                  _showDissolveGroupConfirm();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'view_members',
                child: Row(
                  children: [
                    Icon(Icons.people_outline, color: AppColors.textPrimary),
                    SizedBox(width: 12),
                    Text('Xem thành viên'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'add_member',
                child: Row(
                  children: [
                    Icon(Icons.person_add_outlined, color: AppColors.textPrimary),
                    SizedBox(width: 12),
                    Text('Thêm thành viên'),
                  ],
                ),
              ),
              // Chỉ creator mới thấy option giải tán nhóm
              if (_isCreator)
                PopupMenuItem(
                  value: 'dissolve_group',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Giải tán nhóm', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          )
        else
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
    _socketService?.leaveRoom(widget.chatId);
    
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
