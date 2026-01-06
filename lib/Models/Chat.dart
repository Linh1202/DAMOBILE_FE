import 'User.dart';
import 'Message.dart';

enum ChatType { direct, group }

class Chat {
  final String id;
  final ChatType type;
  final String? name;
  final List<String> participants;
  final List<User>? participantDetails;
  final Message? lastMessage;
  final DateTime updatedAt;
  final String? creatorId;
  final String? description;

  Chat({
    required this.id,
    required this.type,
    this.name,
    required this.participants,
    this.participantDetails,
    this.lastMessage,
    required this.updatedAt,
    this.creatorId,
    this.description,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] == 'group' ? ChatType.group : ChatType.direct,
      name: json['name'],
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      participantDetails: (json['participant_details'] as List<dynamic>?)
          ?.map((e) => User.fromJson(e))
          .toList(),
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : (json['updatedAt'] != null 
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now()),
      creatorId: json['creatorId'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == ChatType.group ? 'group' : 'direct',
      'name': name,
      'participants': participants,
      'updatedAt': updatedAt.toIso8601String(),
      'creatorId': creatorId,
      'description': description,
    };
  }

  String getChatName(String currentUserId) {
    if (type == ChatType.group) {
      return name ?? "Group Chat";
    }

    if (participantDetails != null && participantDetails!.isNotEmpty) {
      final otherUser = participantDetails!.firstWhere(
        (u) => u.id != currentUserId,
        orElse: () => participantDetails!.first,
      );
      return otherUser.fullName;
    }

    return "Chat";
  }

  String? getChatAvatar(String currentUserId) {
    if (type == ChatType.group) return null;

    if (participantDetails != null && participantDetails!.isNotEmpty) {
      final otherUser = participantDetails!.firstWhere(
        (u) => u.id != currentUserId,
        orElse: () => participantDetails!.first,
      );
      return otherUser.avatarUrl;
    }
    return null;
  }
}