import 'Reaction.dart';

class HistoryMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String? mediaUrl;
  final List<String> readBy;
  final DateTime createdAt;
  final bool isEdited;
  final List<Reaction> reactions;

  HistoryMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.mediaUrl,
    this.readBy = const [],
    required this.createdAt,
    this.isEdited = false,
    this.reactions = const [],
  });

  factory HistoryMessage.fromJson(Map<String, dynamic> json) {
    final reactionsData = json['reactions'] as List<dynamic>? ?? [];
    final reactions = reactionsData
        .map((r) => Reaction.fromJson(r as Map<String, dynamic>))
        .toList();

    return HistoryMessage(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      chatId: json['chat_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      content: json['content'] ?? '',
      mediaUrl: json['media_url'],
      readBy: (json['read_by'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isEdited: json['is_edited'] ?? false,
      reactions: reactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'media_url': mediaUrl,
      'read_by': readBy,
      'created_at': createdAt.toIso8601String(),
      'is_edited': isEdited,
      'reactions': reactions.map((r) => r.toJson()).toList(),
    };
  }

  String get formattedTime {
    return "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}";
  }

  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  bool isReadBy(String userId) => readBy.contains(userId);

  bool hasReaction(String userId, String emoji) {
    return reactions.any((r) => r.userId == userId && r.emoji == emoji);
  }

  List<String> getReactionUsers(String emoji) {
    return reactions.where((r) => r.emoji == emoji).map((r) => r.userId).toList();
  }
}