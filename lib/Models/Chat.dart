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
    // Parse participants - can be list of strings or list of objects with _id
    List<String> parseParticipants(dynamic participants) {
      if (participants == null) return [];
      if (participants is! List) return [];
      return participants.map((e) {
        if (e is String) return e;
        if (e is Map) return e['_id']?.toString() ?? e['id']?.toString() ?? '';
        return e.toString();
      }).where((id) => id.isNotEmpty).toList();
    }

    // Parse participant details - handle different formats
    List<User>? parseParticipantDetails(dynamic details) {
      if (details == null) return null;
      if (details is! List) return null;
      try {
        return details.map((e) {
          if (e is Map<String, dynamic>) {
            return User.fromJson(e);
          }
          return User.fromJson(Map<String, dynamic>.from(e));
        }).toList();
      } catch (_) {
        return null;
      }
    }

    return Chat(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type'] == 'group' ? ChatType.group : ChatType.direct,
      name: json['name'],
      participants: parseParticipants(json['participants']),
      participantDetails: parseParticipantDetails(json['participant_details']),
      lastMessage: (json['last_message'] != null && json['last_message'] is Map)
          ? Message.fromJson(json['last_message'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : (json['updatedAt'] != null 
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now()),
      creatorId: json['creatorId']?.toString() ?? json['creator_id']?.toString(),
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