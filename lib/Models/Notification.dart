import 'package:intl/intl.dart';

enum NotificationType {
  message,
  friendRequest,
}

class AppNotification {
  final String id;
  final String recipientId;
  final String senderId;
  final String type;
  final String? resourceId;
  final String content;
  final String? actionUrl;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.type,
    this.resourceId,
    required this.content,
    this.actionUrl,
    this.isRead = false,
    required this.createdAt,
  });

  NotificationType? get notificationType {
    switch (type) {
      case 'CHAT_MESSAGE':
      case 'NEW_MESSAGE':
        return NotificationType.message;
      case 'FRIEND_REQUEST':
        return NotificationType.friendRequest;
      default:
        return null;
    }
  }

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(createdAt);
    } else if (difference.inDays < 7) {
      return DateFormat('HH:mm dd-MM').format(createdAt);
    } else {
      return DateFormat('dd-MM-yyyy').format(createdAt);
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      recipientId: json['recipient_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      resourceId: json['resource_id']?.toString(),
      content: json['content']?.toString() ?? '',
      actionUrl: json['action_url']?.toString(),
      isRead: json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'recipient_id': recipientId,
      'sender_id': senderId,
      'type': type,
      'resource_id': resourceId,
      'content': content,
      'action_url': actionUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: this.id,
      recipientId: this.recipientId,
      senderId: this.senderId,
      type: this.type,
      resourceId: this.resourceId,
      content: this.content,
      actionUrl: this.actionUrl,
      isRead: isRead ?? this.isRead,
      createdAt: this.createdAt,
    );
  }
}
