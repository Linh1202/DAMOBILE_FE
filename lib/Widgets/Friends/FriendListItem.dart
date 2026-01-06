import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';
import '../Avatars/UserAvatar.dart';

/// Widget hiển thị một item bạn bè trong danh sách
/// Có thể tái sử dụng ở nhiều nơi: danh sách bạn bè, chọn thành viên nhóm, etc.
class FriendListItem extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final String lastSeen;
  final VoidCallback? onTap;
  final VoidCallback? onChatTap;
  final Widget? trailing;

  const FriendListItem({
    Key? key,
    required this.name,
    required this.avatarUrl,
    this.isOnline = false,
    this.lastSeen = "",
    this.onTap,
    this.onChatTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: UserAvatar(
        imagePath: avatarUrl,
        name: name,
        size: 50,
        isOnline: isOnline,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        isOnline ? "Đang hoạt động" : lastSeen,
        style: TextStyle(
          fontSize: 13,
          color: isOnline ? AppColors.success : AppColors.textSecondary,
        ),
      ),
      trailing: trailing ?? (onChatTap != null
          ? IconButton(
              icon: Icon(
                Icons.chat_bubble_outline,
                color: AppColors.textSecondary,
              ),
              onPressed: onChatTap,
            )
          : null),
    );
  }
}
