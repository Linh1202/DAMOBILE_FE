import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Models/Notification.dart';

/// Widget hiển thị một thông báo
class NotificationItem extends StatelessWidget {
  final NotificationType type;
  final String title;
  final String content;
  final String time;
  final bool isRead;
  final VoidCallback? onTap;

  const NotificationItem({
    Key? key,
    required this.type,
    required this.title,
    required this.content,
    required this.time,
    this.isRead = false,
    this.onTap,
  }) : super(key: key);

  IconData get _icon {
    switch (type) {
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.friendRequest:
        return Icons.person_add_outlined;
    }
  }

  Color get _iconColor {
    switch (type) {
      case NotificationType.message:
        return AppColors.primary;
      case NotificationType.friendRequest:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isRead ? AppColors.background : AppColors.inputBackground,
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
