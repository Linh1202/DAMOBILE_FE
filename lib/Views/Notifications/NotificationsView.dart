import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Widgets/Notifications/NotificationItem.dart';

class NotificationsView extends StatefulWidget {
  @override
  _NotificationsViewState createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  // Mock data - Danh sách thông báo
  List<Map<String, dynamic>> _notifications = [
    {
      "id": "1",
      "type": NotificationType.message,
      "title": "Tin nhắn mới từ Minh Anh",
      "content": "Chiều nay đi cafe nhé!",
      "time": "10:30 29-12",
      "isRead": false,
    },
    {
      "id": "2",
      "type": NotificationType.friendRequest,
      "title": "Lời mời kết bạn",
      "content": "Thu Thảo đã gửi lời mời kết bạn",
      "time": "08:00 29-12",
      "isRead": false,
    },
    {
      "id": "3",
      "type": NotificationType.missedCall,
      "title": "Cuộc gọi nhỡ",
      "content": "Tuấn Kiệt đã gọi cho bạn",
      "time": "16:00 28-12",
      "isRead": true,
    },
    {
      "id": "4",
      "type": NotificationType.groupInvite,
      "title": "Lời mời vào nhóm",
      "content": "Bạn được mời vào nhóm Team Dev Frontend",
      "time": "14:00 28-12",
      "isRead": true,
    },
  ];

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n["id"] == id);
      if (index != -1) {
        _notifications[index]["isRead"] = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification["isRead"] = true;
      }
    });
  }

  int get _unreadCount => _notifications.where((n) => !n["isRead"]).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Text(
          "Thông báo",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                "Đọc tất cả",
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return NotificationItem(
                  type: notification["type"],
                  title: notification["title"],
                  content: notification["content"],
                  time: notification["time"],
                  isRead: notification["isRead"],
                  onTap: () {
                    _markAsRead(notification["id"]);
                    _handleNotificationTap(notification);
                  },
                );
              },
            ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    switch (notification["type"]) {
      case NotificationType.message:
        // TODO: Mở chat tương ứng
        break;
      case NotificationType.friendRequest:
        // TODO: Mở tab lời mời kết bạn
        break;
      case NotificationType.missedCall:
        // TODO: Gọi lại
        break;
      case NotificationType.groupInvite:
        // TODO: Mở nhóm
        break;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            "Không có thông báo",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
