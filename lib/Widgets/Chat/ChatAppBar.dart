import 'package:flutter/material.dart';
import 'package:doanmobile/Utils/Constants/AppColors.dart';
import 'package:doanmobile/Utils/Handlers/NavigationHandler.dart';
import 'package:doanmobile/Widgets/Avatars/UserAvatar.dart';
import 'package:doanmobile/Providers/ChatController.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final bool isGroup;
  final ChatState state;
  final VoidCallback onVideoCall;
  final VoidCallback? onViewMembers;
  final VoidCallback? onAddMember;
  final VoidCallback? onDissolveGroup;
  final VoidCallback? onLeaveGroup;
  final VoidCallback? onInfo;

  const ChatAppBar({
    Key? key,
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
    required this.isGroup,
    required this.state,
    required this.onVideoCall,
    this.onViewMembers,
    this.onAddMember,
    this.onDissolveGroup,
    this.onLeaveGroup,
    this.onInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCreator = state.creatorId != null && state.creatorId == state.currentUserId;

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
            imagePath: avatarUrl,
            name: name,
            size: 40,
            isOnline: state.targetUserIsOnline || isOnline,
            isGroup: isGroup,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (state.isTyping)
                  Text(
                    "Đang gõ...",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (state.targetUserIsOnline || isOnline)
                  Text(
                    state.targetUserIsOnline ? "Đang hoạt động" : "Không hoạt động",
                    style: TextStyle(
                      fontSize: 12,
                      color: state.targetUserIsOnline ? AppColors.success : AppColors.textSecondary,
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
          onPressed: onVideoCall,
        ),
        if (isGroup)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (value) {
              if (value == 'view_members') onViewMembers?.call();
              else if (value == 'add_member') onAddMember?.call();
              else if (value == 'leave_group') onLeaveGroup?.call();
              else if (value == 'dissolve_group') onDissolveGroup?.call();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'view_members',
                child: Row(
                  children: [
                    Icon(Icons.people_outline, color: AppColors.textPrimary),
                    const SizedBox(width: 12),
                    const Text('Xem thành viên'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'add_member',
                child: Row(
                  children: [
                    Icon(Icons.person_add_outlined, color: AppColors.textPrimary),
                    const SizedBox(width: 12),
                    const Text('Thêm thành viên'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'leave_group',
                child: Row(
                  children: [
                    const Icon(Icons.exit_to_app, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Text('Rời nhóm', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
              if (isCreator)
                PopupMenuItem(
                  value: 'dissolve_group',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_forever, color: Colors.red),
                      const SizedBox(width: 12),
                      const Text('Giải tán nhóm', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          )
        else
          IconButton(
            icon: Icon(Icons.info_outline, color: AppColors.textPrimary),
            onPressed: onInfo,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}