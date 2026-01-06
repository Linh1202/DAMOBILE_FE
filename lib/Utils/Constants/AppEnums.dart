enum MessageType {
  joinRoom,
  leaveRoom,
  chatMessage,
  reaction,
  typing,
  history,
  friendRequest,
  groupInvite,
  notification,
  directCall,
  call,
  error;

  String get value {
    switch (this) {
      case MessageType.joinRoom:
        return 'JOIN_ROOM';
      case MessageType.leaveRoom:
        return 'LEAVE_ROOM';
      case MessageType.chatMessage:
        return 'CHAT_MESSAGE';
      case MessageType.reaction:
        return 'REACTION';
      case MessageType.typing:
        return 'TYPING';
      case MessageType.history:
        return 'HISTORY';
      case MessageType.friendRequest:
        return 'FRIEND_REQUEST';
      case MessageType.groupInvite:
        return 'GROUP_INVITE';
      case MessageType.notification:
        return 'NOTIFICATION';
      case MessageType.directCall:
        return 'DIRECT_CALL';
      case MessageType.call:
        return 'CALL';
      case MessageType.error:
        return 'ERROR';
    }
  }

  static MessageType? fromString(String value) {
    for (var type in MessageType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

enum SignalingType {
  offer,
  answer,
  iceCandidate,
  end;

  String get value {
    switch (this) {
      case SignalingType.offer:
        return 'offer';
      case SignalingType.answer:
        return 'answer';
      case SignalingType.iceCandidate:
        return 'ice_candidate';
      case SignalingType.end:
        return 'end';
    }
  }

  static SignalingType? fromString(String value) {
    for (var type in SignalingType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

enum ReactionAction {
  added,
  removed,
  updated;

  String get value {
    switch (this) {
      case ReactionAction.added:
        return 'added';
      case ReactionAction.removed:
        return 'removed';
      case ReactionAction.updated:
        return 'updated';
    }
  }

  static ReactionAction? fromString(String value) {
    for (var type in ReactionAction.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}