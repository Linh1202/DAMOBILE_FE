import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';
import '../Avatars/UserAvatar.dart';

class MessageBubble extends StatelessWidget {
  final String content;
  final String createdAt;
  final String senderId;
  final String currentUserId;
  final String avatarUrl;
  final bool showAvatar;
  final String? mediaUrl;

  const MessageBubble({
    Key? key,
    required this.content,
    required this.createdAt,
    required this.senderId,
    required this.currentUserId,
    required this.avatarUrl,
    this.showAvatar = true,
    this.mediaUrl,
  }) : super(key: key);

  bool get isMine => senderId == currentUserId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine && showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: UserAvatar(
                imagePath: avatarUrl,
                name: "",
                size: 32,
                showOnlineIndicator: false,
              ),
            )
          else if (!isMine && !showAvatar)
            const SizedBox(width: 40),
          Column(
            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: mediaUrl != null ? 4 : 16,
                  vertical: mediaUrl != null ? 4 : 10,
                ),
                decoration: BoxDecoration(
                  color: isMine ? AppColors.primary : AppColors.inputBackground,
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
                    // Show image if mediaUrl exists
                    if (mediaUrl != null && mediaUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          mediaUrl!,
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
                        ),
                      ),
                    // Show content text
                    if (content.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: mediaUrl != null ? 8 : 0,
                          left: mediaUrl != null ? 8 : 0,
                          right: mediaUrl != null ? 8 : 0,
                          bottom: mediaUrl != null ? 4 : 0,
                        ),
                        child: Text(
                          content,
                          style: TextStyle(
                            fontSize: 15,
                            color: isMine ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                createdAt,
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
}
