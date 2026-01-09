import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:doanmobile/Utils/Constants/AppColors.dart';
import 'package:doanmobile/Widgets/Avatars/UserAvatar.dart';
import 'package:doanmobile/Services/GroupService.dart';
import 'package:doanmobile/Services/ChatService.dart';
import 'package:doanmobile/Services/FriendService.dart';

class ChatActionSheets {
  /// Shows the media picker bottom sheet (Gallery, Camera, File)
  static void showMediaPicker({
    required BuildContext context,
    required Function(ImageSource) onPickImage,
    required VoidCallback onPickFile,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Chọn ảnh từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  onPickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  onPickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.attach_file, color: AppColors.primary),
                title: const Text('Chọn file'),
                subtitle: Text(
                  'PDF, DOC, ZIP, ...',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onPickFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the group members list and allows management for creators
  static void showGroupMembers({
    required BuildContext context,
    required String chatId,
    required String currentUserId,
    required String? creatorId,
    required Function(String memberId, String memberName) onRemoveMember,
  }) async {
    final chatService = ChatService();
    
    try {
      final chat = await chatService.getChatById(chatId);
      if (!context.mounted) return;

      final isCreator = creatorId == currentUserId;

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Thành viên nhóm (${chat.participantDetails?.length ?? 0})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: chat.participantDetails?.length ?? 0,
                  itemBuilder: (context, index) {
                    final user = chat.participantDetails![index];
                    final isCurrentUser = user.id == currentUserId;
                    final isCreatorMember = user.id == creatorId;
                    
                    return ListTile(
                      leading: UserAvatar(
                        imagePath: user.avatarUrl,
                        name: user.fullName,
                        size: 40,
                      ),
                      title: Row(
                        children: [
                          Text(
                            user.fullName,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (isCreatorMember) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: (isCreator && !isCurrentUser && !isCreatorMember)
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                onRemoveMember(user.id, user.fullName);
                              },
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải thành viên: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Shows a dialog to select a friend to add to the group
  static void showAddMemberDialog({
    required BuildContext context,
    required String chatId,
    required Function(String friendId, String friendName) onAddMember,
  }) async {
    try {
      final friends = await FriendService().getFriends();
      final chat = await ChatService().getChatById(chatId);
      final existingMemberIds = chat.participants.toSet();
      final availableFriends = friends.where((f) => !existingMemberIds.contains(f.id)).toList();

      if (!context.mounted) return;

      if (availableFriends.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tất cả bạn bè đã là thành viên nhóm'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.background,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Thêm thành viên',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableFriends.length,
                  itemBuilder: (context, index) {
                    final friend = availableFriends[index];
                    return ListTile(
                      leading: UserAvatar(
                        imagePath: friend.avatarUrl,
                        name: friend.fullName,
                        size: 40,
                      ),
                      title: Text(
                        friend.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        friend.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.person_add, color: AppColors.primary),
                        onPressed: () {
                          Navigator.pop(context);
                          onAddMember(friend.id, friend.fullName);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Shows a confirmation dialog for dissolving a group
  static Future<bool?> showDissolveConfirm(BuildContext context, String groupName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Giải tán nhóm'),
        content: Text('Bạn có chắc muốn giải tán nhóm "$groupName"?\nTất cả tin nhắn và dữ liệu nhóm sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Giải tán', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}