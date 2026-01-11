import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:doanmobile/Providers/SocketProvider.dart';
import 'package:doanmobile/Providers/ChatController.dart';
import 'package:doanmobile/Services/EmojiService.dart';
import 'package:doanmobile/Utils/Constants/AppColors.dart';
import 'package:doanmobile/Widgets/Chat/ChatInputBar.dart';
import 'package:doanmobile/Widgets/Chat/ChatAppBar.dart';
import 'package:doanmobile/Widgets/Chat/ChatMessageList.dart';
import 'package:doanmobile/Widgets/Chat/ChatActionSheets.dart';
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
  ConsumerState<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends ConsumerState<ChatDetailView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _getNotifier().toggleEmoji(false);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeChatIdProvider.notifier).state = widget.chatId;
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      if (ref.read(activeChatIdProvider) == widget.chatId) {
        ref.read(activeChatIdProvider.notifier).state = null;
      }
    });

    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  ChatController _getNotifier() {
    return ref.read(chatControllerProvider((chatId: widget.chatId, isGroup: widget.isGroup)).notifier);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _handleVideoCall(String? targetUserId) {
    final targetId = widget.isGroup ? widget.chatId : targetUserId;
    if (targetId != null && targetId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallView(
            targetUserId: targetId,
            userName: widget.name,
            isIncoming: false,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider((chatId: widget.chatId, isGroup: widget.isGroup)));
    final chatNotifier = _getNotifier();

    ref.listen(socketMessageStreamProvider, (previous, next) {
      next.whenData(chatNotifier.handleSocketMessage);
    });

    ref.listen(chatControllerProvider((chatId: widget.chatId, isGroup: widget.isGroup)).select((s) => s.messages.length), (prev, next) {
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ChatAppBar(
        name: widget.name,
        avatarUrl: widget.avatarUrl,
        isOnline: widget.isOnline,
        isGroup: widget.isGroup,
        state: chatState,
        onVideoCall: () => _handleVideoCall(chatState.targetUserId),
        onViewMembers: () => ChatActionSheets.showGroupMembers(
          context: context,
          chatId: widget.chatId,
          currentUserId: chatState.currentUserId,
          creatorId: chatState.creatorId,
          onRemoveMember: _removeMember,
        ),
        onAddMember: () => ChatActionSheets.showAddMemberDialog(
          context: context,
          chatId: widget.chatId,
          onAddMember: _addMember,
        ),
        onDissolveGroup: _dissolveGroup,
        onInfo: () {},
      ),
      body: WillPopScope(
        onWillPop: () {
          if (chatState.showEmoji) {
            chatNotifier.toggleEmoji(false);
            return Future.value(false);
          }
          return Future.value(true);
        },
        child: Column(
          children: [
            Expanded(
              child: ChatMessageList(
                scrollController: _scrollController,
                chatState: chatState,
                isGroup: widget.isGroup,
                avatarUrl: widget.avatarUrl,
                name: widget.name,
                onReaction: chatNotifier.sendReaction,
              ),
            ),
            if (chatState.isUploading)
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
                      chatState.uploadingLabel,
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    ChatInputBar(
                      controller: _messageController,
                      focusNode: _focusNode,
                      onSend: () {
                        chatNotifier.sendMessage(_messageController.text);
                        _messageController.clear();
                        _scrollToBottom();
                      },
                      onChanged: (_) => chatNotifier.sendTyping(),
                      onAttachment: () => ChatActionSheets.showMediaPicker(
                        context: context,
                        onPickImage: _pickAndSendImage,
                        onPickFile: _pickAndSendFile,
                      ),
                      onEmoji: () {
                        final show = !chatState.showEmoji;
                        chatNotifier.toggleEmoji(show);
                        if (show) {
                          _focusNode.unfocus();
                        } else {
                          _focusNode.requestFocus();
                        }
                      },
                      onVoice: () {},
                    ),
                    if (chatState.showEmoji)
                      SizedBox(
                        height: 250,
                        child: EmojiPicker(
                          onEmojiSelected: (_, emoji) {
                            _messageController.text += emoji.emoji;
                            chatNotifier.sendTyping();
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
                              backgroundColor: AppColors.background,
                              noRecents: const Text(
                                'Chưa có emoji gần đây',
                                style: TextStyle(fontSize: 20, color: Colors.black26),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            categoryViewConfig: CategoryViewConfig(
                              indicatorColor: AppColors.primary,
                              iconColorSelected: AppColors.primary,
                              backspaceColor: AppColors.primary,
                              backgroundColor: AppColors.background,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Logic Handlers ---

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (pickedFile == null) return;
      await _getNotifier().uploadAndSendMedia(File(pickedFile.path), isImage: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gửi ảnh: $e'), backgroundColor: Colors.red),
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

      if (result == null || result.files.isEmpty || result.files.first.path == null) return;

      final pickedFile = result.files.first;
      await _getNotifier().uploadAndSendMedia(
        File(pickedFile.path!),
        isImage: false,
        fileName: pickedFile.name,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gửi file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _addMember(String userId, String name) async {
    try {
      final success = await _getNotifier().addMember(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Đã thêm $name' : 'Không thể thêm thành viên'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeMember(String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa thành viên'),
        content: Text('Bạn có chắc muốn xóa $name khỏi nhóm?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _getNotifier().removeMember(userId);
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã xóa $name'), backgroundColor: Colors.green),
          );
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

  void _dissolveGroup() async {
    final confirm = await ChatActionSheets.showDissolveConfirm(context, widget.name);
    if (confirm == true) {
      try {
        final success = await _getNotifier().dissolveGroup();
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã giải tán nhóm'), backgroundColor: Colors.green),
          );
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
}