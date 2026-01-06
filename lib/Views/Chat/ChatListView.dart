import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Widgets/Chat/ChatListItem.dart';
import '../../Widgets/Common/BadgeIcon.dart';
import 'ChatDetailView.dart';

class ChatListView extends StatelessWidget {
  final List<Map<String, dynamic>> _conversations = [
    {
      "name": "Minh Anh",
      "avatarUrl": "Assets/Images/anh1.png",
      "content": "Chiều nay đi cafe nhé!",
      "updatedAt": "10:30",
      "unreadCount": 0,
      "type": "private",
    },
    {
      "name": "Team Dev Frontend",
      "avatarUrl": "Assets/Images/anh1.png",
      "content": "Đức Anh: Meeting lúc 2h nhé mọi người",
      "updatedAt": "Hôm qua",
      "unreadCount": 5,
      "type": "group",
    },
    {
      "name": "Hương Giang",
      "avatarUrl": "Assets/Images/anh1.png",
      "content": "Ok, hẹn gặp lại!",
      "updatedAt": "2 ngày trước",
      "unreadCount": 0,
      "type": "private",
    },
    {
      "name": "Nhóm Gia Đình",
      "avatarUrl": "Assets/Images/anh1.png",
      "content": "Chủ nhật đi ăn nhé!",
      "updatedAt": "3 ngày trước",
      "unreadCount": 0,
      "type": "group",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          "Tin nhắn",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {
            },
          ),
          BadgeIcon(
            icon: Icons.notifications_outlined,
            count: 2,
            onTap: () {
            },
          ),
          IconButton(
            icon: Icon(Icons.person_add_outlined, color: AppColors.textPrimary),
            onPressed: () {
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          final bool isGroup = conversation["type"] == "group";
          return ChatListItem(
            name: conversation["name"],
            avatarUrl: conversation["avatarUrl"],
            content: conversation["content"],
            updatedAt: conversation["updatedAt"],
            unreadCount: conversation["unreadCount"],
            isGroup: isGroup,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailView(
                    name: conversation["name"],
                    avatarUrl: conversation["avatarUrl"],
                    isOnline: !isGroup,
                    isGroup: isGroup,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
