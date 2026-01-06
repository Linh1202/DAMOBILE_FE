import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';
import '../Avatars/UserAvatar.dart';

class ChatListItem extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final String content;
  final String updatedAt;
  final int unreadCount;
  final bool isGroup;
  final VoidCallback onTap;

  const ChatListItem({
    Key? key,
    required this.name,
    required this.avatarUrl,
    required this.content,
    required this.updatedAt,
    required this.unreadCount,
    required this.isGroup,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            UserAvatar(
              imagePath: avatarUrl,
              name: name,
              size: 56,
              isGroup: isGroup,
              showOnlineIndicator: false,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: unreadCount > 0 
                                ? FontWeight.bold 
                                : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        updatedAt,
                        style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0 
                              ? AppColors.primary 
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          content,
                          style: TextStyle(
                            fontSize: 14,
                            color: unreadCount > 0 
                                ? AppColors.textPrimary 
                                : AppColors.textSecondary,
                            fontWeight: unreadCount > 0 
                                ? FontWeight.w500 
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

