import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Widgets/Notifications/NotificationItem.dart';
import '../../Models/Notification.dart';
import '../../Models/Chat.dart';
import '../../Services/NotificationService.dart';
import '../../Services/ChatService.dart';
import '../../Providers/SocketProvider.dart';
import '../../Views/Chat/ChatDetailView.dart';
import '../../Utils/AppGlobals.dart';

class NotificationsView extends ConsumerStatefulWidget {
  @override
  ConsumerState<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends ConsumerState<NotificationsView> {
  final NotificationService _notificationService = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông báo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      final success = await _notificationService.markAsRead(id);
      if (success && mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == id);
          if (index != -1) {
            _notifications[index] = _notifications[index].copyWith(isRead: true);
          }
        });
      }
    } catch (e) {
      //
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final success = await _notificationService.markAllAsRead();
      if (success && mounted) {
        setState(() {
          _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã đánh dấu tất cả đã đọc'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  String _getTitleForType(AppNotification notification) {
    switch (notification.notificationType) {
      case NotificationType.message:
        return 'Tin nhắn mới';
      case NotificationType.friendRequest:
        return 'Lời mời kết bạn';
      default:
        return 'Thông báo';
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(socketMessageStreamProvider, (previous, next) {
      next.whenData((message) {
        final typeValue = message.type.value;
        if (typeValue == 'FRIEND_REQUEST' || typeValue == 'NOTIFICATION' || typeValue == 'CHAT_MESSAGE') {
          _loadNotifications();
        }
      });
    });

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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final notifType = notification.notificationType;
                      if (notifType == null) return SizedBox.shrink();
                      
                      return NotificationItem(
                        type: notifType,
                        title: _getTitleForType(notification),
                        content: notification.content,
                        time: notification.formattedTime,
                        isRead: notification.isRead,
                        onTap: () {
                          _markAsRead(notification.id);
                          _handleNotificationTap(notification);
                        },
                      );
                    },
                  ),
                ),
    );
  }

  void _handleNotificationTap(AppNotification notification) async {
    final actionUrl = notification.actionUrl;
    if (actionUrl == null || actionUrl.isEmpty) return;

    if (actionUrl.startsWith('/chat/')) {
      final chatId = actionUrl.replaceFirst('/chat/', '');
      if (chatId.isNotEmpty) {
        try {
          final chatService = ChatService();
          final chat = await chatService.getChatById(chatId);
          if (chat != null && mounted) {
            String chatName = chat.name ?? 'Chat';
            String chatAvatar = '';
            bool isGroup = chat.type == ChatType.group;
            
            if (!isGroup && chat.participantDetails != null && chat.participantDetails!.isNotEmpty) {
              final otherUser = chat.participantDetails!.firstWhere(
                (u) => u.id != notification.recipientId,
                orElse: () => chat.participantDetails!.first,
              );
              chatName = otherUser.fullName;
              chatAvatar = otherUser.avatarUrl ?? '';
            }
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailView(
                  chatId: chat.id,
                  name: chatName,
                  avatarUrl: chatAvatar,
                  isGroup: isGroup,
                ),
              ),
            );
          }
        } catch (e) {
          //
        }
      }
    }
    else if (actionUrl == '/friend/requests') {
      Navigator.pop(context);
      AppGlobals.itemBarIndex = 1;
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
