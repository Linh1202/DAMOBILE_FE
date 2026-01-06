import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';
import '../Avatars/UserAvatar.dart';

/// Widget hiển thị một lời mời kết bạn
/// Có nút Chấp nhận và Từ chối
class FriendRequestItem extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final String requestDate;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isLoading;

  const FriendRequestItem({
    Key? key,
    required this.name,
    required this.avatarUrl,
    required this.requestDate,
    this.onAccept,
    this.onReject,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          UserAvatar(
            imagePath: avatarUrl,
            name: name,
            size: 50,
          ),
          SizedBox(width: 12),
          // Info và buttons
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                // Ngày gửi lời mời
                Text(
                  requestDate,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút Chấp nhận
              _buildActionButton(
                label: "Chấp nhận",
                icon: Icons.person_add_outlined,
                isPrimary: true,
                onPressed: isLoading ? null : onAccept,
              ),
              SizedBox(width: 8),
              // Nút Từ chối
              _buildActionButton(
                label: "Từ chối",
                icon: Icons.person_remove_outlined,
                isPrimary: false,
                onPressed: isLoading ? null : onReject,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
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
        child: Row(
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
