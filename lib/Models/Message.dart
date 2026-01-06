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
  });

  factory Message.fromJson(dynamic json) {
    final Map<String, dynamic> data = json is Map<String, dynamic> 
        ? json 
        : Map<String, dynamic>.from(json as Map);
    
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
    };
  }

  String get formattedTime {
    return "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}";
  }

  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  bool isReadBy(String userId) => readBy.contains(userId);
}