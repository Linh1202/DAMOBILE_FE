import '../../Utils/Constants/AppEnums.dart';

class SocketMessage {
  final MessageType type;
  final String? roomId;
  final String? senderId;
  final String? senderName;
  final String? content;
  final dynamic payload;
  final DateTime? timestamp;

  SocketMessage({
    required this.type,
    this.roomId,
    this.senderId,
    this.senderName,
    this.content,
    this.payload,
    this.timestamp,
  });

  factory SocketMessage.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString() ?? '';
    final type = MessageType.fromString(typeStr) ?? MessageType.error;

    return SocketMessage(
      type: type,
      roomId: json['room_id']?.toString(),
      senderId: json['sender_id']?.toString(),
      senderName: json['sender_name']?.toString(),
      content: json['content']?.toString(),
      payload: json['payload'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'type': type.value};

    if (roomId != null) data['room_id'] = roomId;
    if (senderId != null) data['sender_id'] = senderId;
    if (senderName != null) data['sender_name'] = senderName;
    if (content != null) data['content'] = content;
    if (payload != null) data['payload'] = payload;
    if (timestamp != null) data['timestamp'] = timestamp!.toIso8601String();

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
      payload: {'message_id': messageId, 'emoji': emoji},
    );
  }

  static SocketMessage createTyping(String roomId) {
    return SocketMessage(type: MessageType.typing, roomId: roomId);
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
