import 'Reaction.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String? mediaUrl;
  final List<String> readBy;
  final DateTime createdAt;
  final bool isEdited;

  final String? senderName;
  final String? senderAvatarUrl;
  final List<Reaction> reactions;
  final Map<String, int> reactionCounts;
  final String? chatName;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.mediaUrl,
    this.readBy = const [],
    required this.createdAt,
    this.isEdited = false,
    this.senderName,
    this.senderAvatarUrl,
    this.reactions = const [],
    this.reactionCounts = const {},
    this.chatName,
  });

  factory Message.fromJson(dynamic json) {
    final Map<String, dynamic> data = json is Map<String, dynamic> 
        ? json 
        : Map<String, dynamic>.from(json as Map);
    
    final reactionsData = data['reactions'] as List<dynamic>? ?? [];
    final reactions = reactionsData
        .map((r) => Reaction.fromJson(r as Map<String, dynamic>))
        .toList();

    final Map<String, int> reactionCounts = {};
    if (data['reaction_counts'] != null) {
      (data['reaction_counts'] as Map).forEach((key, value) {
        reactionCounts[key.toString()] = value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }
    
    return Message(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
      chatId: data['chat_id']?.toString() ?? '',
      senderId: data['sender_id']?.toString() ?? '',
      content: data['content'] ?? '',
      mediaUrl: data['media_url'],
      readBy: (data['read_by'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : DateTime.now(),
      isEdited: data['is_edited'] ?? false,
      senderName: data['sender_name'] ?? data['sender']?['username'],
      senderAvatarUrl: data['sender_avatar_url'] ?? data['sender']?['avatar_url'],
      reactions: reactions,
      reactionCounts: reactionCounts,
      chatName: data['chat_name'],
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
      'reaction_counts': reactionCounts,
      'chat_name': chatName,
    };
  }

  String get formattedTime {
    final localTime = createdAt.toLocal();
    return "${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}";
  }

  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  bool isReadBy(String userId) => readBy.contains(userId);

  bool hasReaction(String userId, String emoji) {
    return reactions.any((r) => r.userId == userId && r.emoji == emoji);
  }

  List<String> getReactionUsers(String emoji) {
    return reactions.where((r) => r.emoji == emoji).map((r) => r.userId).toList();
  }

  List<String> getUniqueReactionEmojis() {
    return reactions.map((r) => r.emoji).toSet().toList();
  }
}