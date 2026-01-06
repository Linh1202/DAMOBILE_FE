import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Utils/Handlers/NavigationHandler.dart';
import '../../Utils/Handlers/DialogHandler.dart';
import '../../Widgets/Avatars/UserAvatar.dart';

class CreateGroupView extends StatefulWidget {
  @override
  _CreateGroupViewState createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  TextEditingController txtGroupName = TextEditingController();
  List<String> selectedMemberIds = [];

  // Mock data - Danh sách bạn bè
  final List<Map<String, dynamic>> _friends = [
    {
      "id": "1",
      "name": "Minh Anh",
      "avatarUrl": "Assets/Images/anh1.png",
      "isOnline": true,
      "lastSeen": "Đang hoạt động",
    },
    {
      "id": "2",
      "name": "Tuấn Kiệt",
      "avatarUrl": "Assets/Images/anh1.png",
      "isOnline": false,
      "lastSeen": "5 phút trước",
    },
    {
      "id": "3",
      "name": "Hương Giang",
      "avatarUrl": "Assets/Images/anh1.png",
      "isOnline": true,
      "lastSeen": "Đang hoạt động",
    },
    {
      "id": "4",
      "name": "Đức Anh",
      "avatarUrl": "Assets/Images/anh1.png",
      "isOnline": false,
      "lastSeen": "2 giờ trước",
    },
    {
      "id": "5",
      "name": "Thu Thảo",
      "avatarUrl": "Assets/Images/anh1.png",
      "isOnline": true,
      "lastSeen": "Đang hoạt động",
    },
    {
      "id": "6",
      "name": "Hoàng Long",
      "avatarUrl": "Assets/Images/anh1.png",
      "isOnline": false,
      "lastSeen": "1 ngày trước",
    },
  ];

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

  void _createGroup() {
    if (txtGroupName.text.trim().isEmpty) {
      DialogHandler.showError("Vui lòng nhập tên nhóm");
      return;
    }
    if (selectedMemberIds.isEmpty) {
      DialogHandler.showError("Vui lòng chọn ít nhất 1 thành viên");
      return;
    }

    // TODO: Gọi API tạo nhóm
    DialogHandler.showSuccess("Tạo nhóm thành công!");
    Navigator.pop(context);
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
          TextButton(
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
                // Avatar nhóm với nút camera
                Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.group,
                        color: AppColors.iconGrey,
                        size: 32,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: AppColors.iconGrey,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
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
            child: ListView.builder(
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final friend = _friends[index];
                final isSelected = selectedMemberIds.contains(friend["id"]);

                return ListTile(
                  onTap: () => _toggleMember(friend["id"]),
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
                        imagePath: friend["avatarUrl"],
                        name: friend["name"],
                        size: 48,
                        isOnline: friend["isOnline"],
                      ),
                    ],
                  ),
                  title: Text(
                    friend["name"],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    friend["lastSeen"],
                    style: TextStyle(
                      fontSize: 13,
                      color: friend["isOnline"] 
                          ? AppColors.success 
                          : AppColors.textSecondary,
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
