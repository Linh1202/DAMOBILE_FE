import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';
import '../Avatars/UserAvatar.dart';

class MessageBubble extends StatelessWidget {
  final String content;
  final String createdAt; 
  final String senderId;
  final String avatarUrl;
  final bool showAvatar;

  const MessageBubble({
    Key? key,
    required this.content,
    required this.createdAt,
    required this.senderId,
    required this.avatarUrl,
    this.showAvatar = true,
  }) : super(key: key);

  bool get isMine => senderId == "current_user";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine && showAvatar)
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: UserAvatar(
                imagePath: avatarUrl,
                name: "",
                size: 32,
                showOnlineIndicator: false,
              ),
            )
          else if (!isMine && !showAvatar)
            SizedBox(width: 40),
          Column(
            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isMine ? AppColors.primary : AppColors.inputBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                ),
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    color: isMine ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: 4),
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

