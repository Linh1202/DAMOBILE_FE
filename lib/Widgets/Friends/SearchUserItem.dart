import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';
import '../Avatars/UserAvatar.dart';

/// Widget hiển thị kết quả tìm kiếm người dùng
/// Có nút Kết bạn hoặc hiển thị trạng thái đã gửi lời mời
class SearchUserItem extends StatelessWidget {
  final String id;
  final String name;
  final String avatarUrl;
  final String? email;
  final FriendStatus status;
  final VoidCallback? onAddFriend;
  final VoidCallback? onCancelRequest;
  final VoidCallback? onTap;
  final bool isLoading;

  const SearchUserItem({
    Key? key,
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.email,
    this.status = FriendStatus.none,
    this.onAddFriend,
    this.onCancelRequest,
    this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: UserAvatar(
        imagePath: avatarUrl,
        name: name,
        size: 50,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: email != null
          ? Text(
              email!,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: _buildTrailingButton(),
    );
  }

  Widget? _buildTrailingButton() {
    switch (status) {
      case FriendStatus.none:
        return _ActionButton(
          label: "Kết bạn",
          icon: Icons.person_add_outlined,
          isPrimary: true,
          isLoading: isLoading,
          onPressed: onAddFriend,
        );
      case FriendStatus.pending:
        return _ActionButton(
          label: "Đã gửi",
          icon: Icons.schedule,
          isPrimary: false,
          isLoading: isLoading,
          onPressed: onCancelRequest,
        );
      case FriendStatus.friend:
        return Icon(
          Icons.check_circle,
          color: AppColors.success,
        );
      case FriendStatus.blocked:
        return null;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isPrimary
              ? null
              : Border.all(color: AppColors.border, width: 1),
        ),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPrimary ? Colors.white : AppColors.primary,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isPrimary ? Colors.white : AppColors.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isPrimary ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Trạng thái quan hệ bạn bè
enum FriendStatus {
  none,     // Chưa kết bạn
  pending,  // Đã gửi lời mời
  friend,   // Đã là bạn bè
  blocked,  // Đã chặn
}
