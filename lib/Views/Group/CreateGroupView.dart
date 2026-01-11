import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Utils/Handlers/NavigationHandler.dart';
import '../../Utils/Handlers/DialogHandler.dart';
import '../../Widgets/Avatars/UserAvatar.dart';
import '../../Services/GroupService.dart';
import '../../Services/FriendService.dart';
import '../../Services/AuthStorage.dart';
import '../../Models/User.dart';
import '../Chat/ChatDetailView.dart';

class CreateGroupView extends StatefulWidget {
  @override
  _CreateGroupViewState createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  final GroupService _groupService = GroupService();
  final FriendService _friendService = FriendService();
  TextEditingController txtGroupName = TextEditingController();
  List<String> selectedMemberIds = [];
  bool _isLoading = false;
  bool _isLoadingFriends = true;
  String _currentUserId = '';
  List<User> _friends = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadCurrentUser();
    await _loadFriends();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthStorage.readUser();
    if (mounted && user != null) {
      setState(() {
        _currentUserId = user['id']?.toString() ?? user['_id']?.toString() ?? '';
      });
    }
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await _friendService.getFriends();
      if (mounted) {
        setState(() {
          _friends = friends;
          _isLoadingFriends = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFriends = false);
        DialogHandler.showError("Không thể tải danh sách bạn bè: $e");
      }
    }
  }

  @override
  void dispose() {
    txtGroupName.dispose();
    super.dispose();
  }

  void _toggleMember(String id) {
    setState(() {
      if (selectedMemberIds.contains(id)) {
        selectedMemberIds.remove(id);
      } else {
        selectedMemberIds.add(id);
      }
    });
  }

  Future<void> _createGroup() async {
    if (txtGroupName.text.trim().isEmpty) {
      DialogHandler.showError("Vui lòng nhập tên nhóm");
      return;
    }
    if (selectedMemberIds.isEmpty) {
      DialogHandler.showError("Vui lòng chọn ít nhất 1 thành viên");
      return;
    }
    if (_currentUserId.isEmpty) {
      DialogHandler.showError("Không thể xác định người dùng hiện tại");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final chat = await _groupService.createGroup(
        name: txtGroupName.text.trim(),
        description: '',
        creatorId: _currentUserId,
      );

      for (final memberId in selectedMemberIds) {
        await _groupService.addMember(chat.id, memberId);
      }

      DialogHandler.showSuccess("Tạo nhóm thành công!");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailView(
              chatId: chat.id,
              name: chat.name ?? txtGroupName.text.trim(),
              avatarUrl: '',
              isOnline: false,
              isGroup: true,
            ),
          ),
        );
      }
    } catch (e) {
      DialogHandler.showError("Lỗi tạo nhóm: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: NavigationHandler.goBack,
        ),
        title: Text(
          "Tạo nhóm mới",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          _isLoading
              ? Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _createGroup,
                  child: Text(
                    "Tạo",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section - Avatar nhóm và tên nhóm
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar nhóm giống trang home
                UserAvatar(
                  imagePath: "Assets/Images/anh1.png",
                  name: txtGroupName.text.isEmpty ? "G" : txtGroupName.text,
                  size: 64,
                  isGroup: true,
                  showOnlineIndicator: false,
                ),
                SizedBox(width: 16),
                // Input tên nhóm
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: txtGroupName,
                      decoration: InputDecoration(
                        hintText: "Nhập tên nhóm...",
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Số thành viên đã chọn
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.people_outline,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  "${selectedMemberIds.length} thành viên được chọn",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Section header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.inputBackground,
            width: double.infinity,
            child: Text(
              "Chọn thành viên",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Danh sách bạn bè
          Expanded(
            child: _isLoadingFriends
                ? Center(child: CircularProgressIndicator())
                : _friends.isEmpty
                    ? Center(
                        child: Text(
                          "Bạn chưa có bạn bè nào",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          final isSelected = selectedMemberIds.contains(friend.id);

                          return ListTile(
                            onTap: () => _toggleMember(friend.id),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Checkbox
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                      : null,
                                ),
                                SizedBox(width: 12),
                                // Avatar
                                UserAvatar(
                                  imagePath: friend.avatarUrl,
                                  name: friend.fullName,
                                  size: 48,
                                  isOnline: false,
                                ),
                              ],
                            ),
                            title: Text(
                              friend.fullName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              friend.email,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
