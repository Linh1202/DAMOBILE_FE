import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Services/EmojiService.dart';
import '../../Models/Reaction.dart';
import '../Avatars/UserAvatar.dart';

class MessageBubble extends StatefulWidget {
  final String id;
  final String content;
  final String createdAt;
  final String senderId;
  final String currentUserId;
  final String avatarUrl;
  final bool showAvatar;
  final String? mediaUrl;
  final List<Reaction> reactions;
  final Function(String emoji)? onReaction;

  const MessageBubble({
    Key? key,
    required this.id,
    required this.content,
    required this.createdAt,
    required this.senderId,
    required this.currentUserId,
    required this.avatarUrl,
    this.showAvatar = true,
    this.mediaUrl,
    this.reactions = const [],
    this.onReaction,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isDownloading = false;
  double _downloadProgress = 0;

  bool get isMine => widget.senderId == widget.currentUserId;

  // Check if mediaUrl is an image
  bool get _isImage {
    if (widget.mediaUrl == null) return false;
    final lower = widget.mediaUrl!.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.gif') ||
        lower.contains('.webp') ||
        lower.contains('.bmp') ||
        lower.contains('/image/upload/');
  }

  bool get _isFile => widget.content.startsWith('📎');

  String get _fileName {
    if (_isFile && widget.content.contains('📎')) {
      return widget.content.replaceFirst('📎 ', '');
    }
    if (widget.mediaUrl != null) {
      final uri = Uri.parse(widget.mediaUrl!);
      return uri.pathSegments.last;
    }
    return 'downloaded_file';
  }

  void _openFullScreenImage(BuildContext context) {
    if (widget.mediaUrl == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageView(
          imageUrl: widget.mediaUrl!,
          onDownload: () => _downloadFile(context),
        ),
      ),
    );
  }

  Future<void> _downloadFile(BuildContext context) async {
    if (widget.mediaUrl == null || _isDownloading) return;

    // Request storage permission on Android
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cần quyền truy cập bộ nhớ để tải file')),
          );
        }
        return;
      }
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      // Get download directory
      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory();
        }
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir == null) {
        throw Exception('Không thể truy cập thư mục tải về');
      }

      final filePath = '${downloadDir.path}/$_fileName';

      // Download with progress
      final dio = Dio();
      await dio.download(
        widget.mediaUrl!,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tải: $_fileName'),
            action: SnackBarAction(
              label: 'Mở',
              onPressed: () => OpenFilex.open(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMediaTap(BuildContext context) {
    if (_isImage && !_isFile) {
      _openFullScreenImage(context);
    } else {
      _downloadFile(context);
    }
  }

  void _showReactionPicker(BuildContext context) {
    final List<String> defaultEmojis = EmojiService.getDefaultReactions();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: defaultEmojis.map((emoji) {
              return GestureDetector(
                onTap: () {
                  widget.onReaction?.call(emoji);
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine && widget.showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: UserAvatar(
                imagePath: widget.avatarUrl,
                name: "",
                size: 32,
                showOnlineIndicator: false,
              ),
            )
          else if (!isMine && !widget.showAvatar)
            const SizedBox(width: 40),
          Column(
            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onLongPress: () => _showReactionPicker(context),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: (widget.mediaUrl != null || EmojiService.isOnlyEmojis(widget.content)) ? 4 : 16,
                    vertical: (widget.mediaUrl != null || EmojiService.isOnlyEmojis(widget.content)) ? 4 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: widget.mediaUrl == null && EmojiService.isOnlyEmojis(widget.content)
                        ? Colors.transparent
                        : (isMine ? AppColors.primary : AppColors.inputBackground),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMine ? 18 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.mediaUrl != null && widget.mediaUrl!.isNotEmpty)
                        GestureDetector(
                          onTap: () => _handleMediaTap(context),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _isImage && !_isFile
                                    ? Image.network(
                                        widget.mediaUrl!,
                                        width: 200,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return SizedBox(
                                            width: 200,
                                            height: 150,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 200,
                                            height: 100,
                                            color: AppColors.inputBackground,
                                            child: const Icon(Icons.broken_image, size: 40),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 200,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isMine 
                                              ? Colors.white.withOpacity(0.2) 
                                              : AppColors.background,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.insert_drive_file,
                                              size: 48,
                                              color: isMine ? Colors.white : AppColors.primary,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _isDownloading 
                                                  ? 'Đang tải ${(_downloadProgress * 100).toInt()}%'
                                                  : 'Nhấn để tải về',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isMine 
                                                    ? Colors.white.withOpacity(0.8)
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                // Download progress overlay
                                if (_isDownloading)
                                  Container(
                                    width: 200,
                                    height: _isImage ? 150 : 100,
                                    color: Colors.black.withOpacity(0.5),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: _downloadProgress,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (widget.content.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: widget.mediaUrl != null ? 8 : 0,
                            left: widget.mediaUrl != null ? 8 : 0,
                            right: widget.mediaUrl != null ? 8 : 0,
                            bottom: widget.mediaUrl != null ? 4 : 0,
                          ),
                          child: Text(
                            widget.content,
                            style: TextStyle(
                              fontSize: EmojiService.isOnlyEmojis(widget.content) ? 32 : 15,
                              color: isMine ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (widget.reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    children: _buildReactionWidgets(),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                widget.createdAt,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReactionWidgets() {
    // Group reactions by emoji
    final Map<String, int> counts = {};
    for (var r in widget.reactions) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }

    return counts.entries.map((entry) {
      final bool alreadyReacted = widget.reactions.any(
        (r) => r.userId == widget.currentUserId && r.emoji == entry.key
      );

      return GestureDetector(
        onTap: () => widget.onReaction?.call(entry.key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: alreadyReacted 
                ? AppColors.primary.withOpacity(0.1) 
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: alreadyReacted ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(entry.key, style: const TextStyle(fontSize: 12)),
              if (entry.value > 1) ...[
                const SizedBox(width: 2),
                Text(
                  entry.value.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: alreadyReacted ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onDownload;

  const _FullScreenImageView({
    required this.imageUrl,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              Navigator.pop(context);
              onDownload();
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.broken_image,
                size: 80,
                color: Colors.white54,
              );
            },
          ),
        ),
      ),
    );
  }
}
