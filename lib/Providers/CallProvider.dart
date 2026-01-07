import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Services/WebRTCService.dart';
import '../Models/Api/SocketMessage.dart';
import '../Utils/Constants/AppEnums.dart';
import 'SocketProvider.dart';

enum CallStatus { idle, ringing, connected }

class CallState {
  final CallStatus status;
  final String? callerId;
  final String? callerName;
  final Map<String, dynamic>? offerSdp;
  final bool isRoom;
  final String? roomId;

  CallState({
    this.status = CallStatus.idle,
    this.callerId,
    this.callerName,
    this.offerSdp,
    this.isRoom = false,
    this.roomId,
  });

  CallState copyWith({
    CallStatus? status,
    String? callerId,
    String? callerName,
    Map<String, dynamic>? offerSdp,
    bool? isRoom,
    String? roomId,
  }) {
    return CallState(
      status: status ?? this.status,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      offerSdp: offerSdp ?? this.offerSdp,
      isRoom: isRoom ?? this.isRoom,
      roomId: roomId ?? this.roomId,
    );
  }
}

final callProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  final notifier = CallNotifier(ref);
  
  ref.listen(socketMessageStreamProvider, (previous, next) {
    next.whenData((message) {
      notifier.handleIncomingMessage(message);
    });
  });

  return notifier;
});

class CallNotifier extends StateNotifier<CallState> {
  final Ref _ref;

  CallNotifier(this._ref) : super(CallState());

  void handleIncomingMessage(SocketMessage message) {
    if (message.type != MessageType.directCall && message.type != MessageType.call) return;

    final payload = message.payload;
    if (payload == null) return;

    final sigType = SignalingType.fromString(payload['type'] ?? "");
    final innerPayload = payload['payload'];
    final isRoom = message.type == MessageType.call;

    switch (sigType) {
      case SignalingType.offer:
        if (state.status != CallStatus.idle) {
          return;
        }

        print("CallProvider: Received incoming call offer from ${message.senderName ?? message.senderId}");
        state = CallState(
          status: CallStatus.ringing,
          callerId: message.senderId,
          callerName: message.senderName,
          offerSdp: innerPayload,
          isRoom: isRoom,
          roomId: message.roomId,
        );
        break;

      case SignalingType.answer:
        print("CallProvider: Received Answer from peer");
        WebRTCService.instance.handleAnswer(innerPayload);
        break;

      case SignalingType.iceCandidate:
        print("CallProvider: Received ICE Candidate from peer");
        WebRTCService.instance.handleIceCandidate(innerPayload);
        break;

      case SignalingType.end:
        print("CallProvider: Call ended by remote peer");
        _resetState();
        break;

      default:
        break;
    }
  }

  /// Transitions state to connected (UI should then navigate to CallView)
  void acceptCall() {
    if (state.status == CallStatus.ringing) {
      state = state.copyWith(status: CallStatus.connected);
    }
  }

  /// Rejects the incoming call and notifies the sender
  void rejectCall() {
    if (state.status == CallStatus.ringing) {
      WebRTCService.instance.endCall(state.callerId);
      _resetState();
    }
  }

  /// Ends the current active call locally and notifies the peer
  void endCall() {
    WebRTCService.instance.endCall(state.callerId);
    _resetState();
  }

  void _resetState() {
    state = CallState(status: CallStatus.idle);
  }
}