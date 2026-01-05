enum MessageType {
  directCall,
  joinRoom,
  call;

  String get value {
    switch (this) {
      case MessageType.directCall:
        return 'DIRECT_CALL';
      case MessageType.joinRoom:
        return 'JOIN_ROOM';
      case MessageType.call:
        return 'CALL';
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