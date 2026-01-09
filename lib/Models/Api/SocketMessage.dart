import '../../Utils/Constants/AppEnums.dart';

class SocketMessage {
  final MessageType type;
  final String? roomId;
  final String? senderId;
  final String? senderName;
  final String? chatName;
  final String? lastMessage;
  final String? content;
  final dynamic payload;
  final DateTime? timestamp;
  final bool? isOnline;

  SocketMessage({
    required this.type,
    this.roomId,
    this.senderId,
    this.senderName,
    this.chatName,
    this.lastMessage,
    this.content,
    this.payload,
    this.timestamp,
    this.isOnline,
  });

  factory SocketMessage.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString() ?? '';
    final type = MessageType.fromString(typeStr) ?? MessageType.error;

    return SocketMessage(
      type: type,
      roomId: json['room_id']?.toString(),
      senderId: json['sender_id']?.toString(),
      senderName: json['sender_name']?.toString(),
      chatName: json['chat_name']?.toString(),
      lastMessage: json['last_message']?.toString(),
      content: json['content']?.toString(),
      payload: json['payload'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      isOnline: json['is_online'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'type': type.value};

    if (roomId != null) data['room_id'] = roomId;
    if (senderId != null) data['sender_id'] = senderId;
    if (senderName != null) data['sender_name'] = senderName;
    if (chatName != null) data['chat_name'] = chatName;
    if (lastMessage != null) data['last_message'] = lastMessage;
    if (content != null) data['content'] = content;
    if (payload != null) data['payload'] = payload;
    if (timestamp != null) data['timestamp'] = timestamp!.toIso8601String();
    if (isOnline != null) data['is_online'] = isOnline;

    return data;
  }

  static SocketMessage createChatMessage({
    required String roomId,
    required String content,
    String? mediaUrl,
  }) {
    return SocketMessage(
      type: MessageType.chatMessage,
      roomId: roomId,
      content: content,
      payload: mediaUrl != null ? {'media_url': mediaUrl} : null,
    );
  }

  static SocketMessage createJoinRoom(String roomId) {
    return SocketMessage(type: MessageType.joinRoom, roomId: roomId);
  }

  static SocketMessage createLeaveRoom(String roomId) {
    return SocketMessage(type: MessageType.leaveRoom, roomId: roomId);
  }

  static SocketMessage createReaction({
    required String roomId,
    required String messageId,
    required String emoji,
  }) {
    return SocketMessage(
      type: MessageType.reaction,
      roomId: roomId,
      payload: {
        'message_id': messageId,
        'emoji': emoji,
      },
    );
  }

  static SocketMessage createTyping(String roomId) {
    return SocketMessage(type: MessageType.typing, roomId: roomId);
  }

  static SocketMessage createFriendRequest(String targetUserId) {
    return SocketMessage(
      type: MessageType.friendRequest,
      roomId: targetUserId,
    );
  }

  static SocketMessage createGroupInvite({
    required String targetUserId,
    required String content,
  }) {
    return SocketMessage(
      type: MessageType.groupInvite,
      roomId: targetUserId,
      content: content,
    );
  }

  static SocketMessage createNotification({
    String? targetUserId,
    required String content,
  }) {
    return SocketMessage(
      type: MessageType.notification,
      roomId: targetUserId,
      content: content,
    );
  }

  static SocketMessage createDirectCall({
    required String targetId,
    required SignalingType signalingType,
    dynamic signalingPayload,
  }) {
    return SocketMessage(
      type: MessageType.directCall,
      roomId: targetId,
      payload: {
        'type': signalingType.value,
        if (signalingPayload != null) 'payload': signalingPayload,
      },
    );
  }

  static SocketMessage createRoomCall({
    required String roomId,
    required SignalingType signalingType,
    dynamic signalingPayload,
  }) {
    return SocketMessage(
      type: MessageType.call,
      roomId: roomId,
      payload: {
        'type': signalingType.value,
        if (signalingPayload != null) 'payload': signalingPayload,
      },
    );
  }

  @override
  String toString() {
    return 'SocketMessage(type: ${type.value}, roomId: $roomId, sender: $senderName, content: $content)';
  }
}