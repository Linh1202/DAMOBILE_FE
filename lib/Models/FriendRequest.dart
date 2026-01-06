class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String status;
  final DateTime createdAt;
  
  final String? senderName;
  final String? senderAvatarUrl;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.senderName,
    this.senderAvatarUrl,
  });

  factory FriendRequest.fromJson(dynamic json) {
    final Map<String, dynamic> data = json is Map<String, dynamic> 
        ? json 
        : Map<String, dynamic>.from(json as Map);
    
    return FriendRequest(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
      senderId: data['sender_id']?.toString() ?? '',
      receiverId: data['receiver_id']?.toString() ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : DateTime.now(),
      senderName: data['sender_name'] ?? data['sender']?['username'],
      senderAvatarUrl: data['sender_avatar_url'] ?? data['sender']?['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedDate {
    return "${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}";
  }
}