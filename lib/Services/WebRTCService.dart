import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'SocketService.dart';
import '../Utils/Constants/AppEnums.dart';
import '../Utils/Constants/AppStrings.dart';

class WebRTCService {
  static final WebRTCService instance = WebRTCService._internal();
  factory WebRTCService() => instance;
  WebRTCService._internal();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  String? _currentTargetId;
  String? _currentRoomId;
  bool _isRoomCall = false;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      if (AppStrings.turnUrl.isNotEmpty)
        {
          'urls': AppStrings.turnUrl,
          'username': AppStrings.turnUsername,
          'credential': AppStrings.turnPassword,
        },
    ],
    'sdpSemantics': 'unified-plan',
  };

  Function(MediaStream stream)? onLocalStream;
  Function(MediaStream stream)? onRemoteStream;
  Function(RTCSignalingState state)? onSignalingStateChange;
  Function(RTCPeerConnectionState state)? onConnectionStateChange;
  Function()? onCallEnd;

  Future<void> _initPeerConnection() async {
    if (_peerConnection != null) return;

    try {
      _peerConnection = await createPeerConnection(_configuration);

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        _sendSignalingMessage(
          type: SignalingType.iceCandidate,
          payload: {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
      };

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          onRemoteStream?.call(event.streams[0]);
        }
      };

      _peerConnection!.onSignalingState = (state) {
        onSignalingStateChange?.call(state);
      };

      _peerConnection!.onConnectionState = (state) {
        onConnectionStateChange?.call(state);
      };
    } catch (e) {
      rethrow;
    }
  }

  void _sendSignalingMessage({
    required SignalingType type,
    dynamic payload,
    String? overrideTargetId,
    String? overrideRoomId,
    bool? overrideIsRoom,
  }) {
    final isRoom = overrideIsRoom ?? _isRoomCall;
    final roomId = overrideRoomId ?? _currentRoomId;
    final targetId = overrideTargetId ?? _currentTargetId;

    if (isRoom && roomId != null) {
      SocketService.instance.sendRoomCall(
        roomId: roomId,
        type: type,
        payload: payload,
      );
    } else if (targetId != null) {
      SocketService.instance.sendDirectCall(
        targetUserId: targetId,
        type: type,
        payload: payload,
      );
    }
  }

  Future<void> _setupLocalMedia() async {
    if (_localStream != null) return;

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'},
      });

      onLocalStream?.call(_localStream!);

      if (_peerConnection != null) {
        _localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> startDirectCall(String targetUserId) async {
    try {
      _isRoomCall = false;
      _currentTargetId = targetUserId;
      _currentRoomId = null;

      await _initPeerConnection();
      await _setupLocalMedia();

      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      _sendSignalingMessage(
        type: SignalingType.offer,
        payload: {'sdp': offer.sdp, 'type': offer.type},
      );
    } catch (e) {
      print("Lỗi bắt đầu cuộc gọi trực tiếp: $e");
      await endCall();
    }
  }

  Future<void> startRoomCall(String roomId) async {
    try {
      _isRoomCall = true;
      _currentRoomId = roomId;
      _currentTargetId = null;

      SocketService.instance.joinRoom(roomId);

      await _initPeerConnection();
      await _setupLocalMedia();

      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      _sendSignalingMessage(
        type: SignalingType.offer,
        payload: {'sdp': offer.sdp, 'type': offer.type},
      );
    } catch (e) {
      print("Lỗi bắt đầu cuộc gọi nhóm: $e");
      await endCall();
    }
  }

  Future<void> handleOffer(
    String senderId,
    Map<String, dynamic> sdpData, {
    bool isRoom = false,
    String? roomId,
  }) async {
    try {
      _isRoomCall = isRoom;
      _currentTargetId = senderId;
      _currentRoomId = roomId;

      if (isRoom && roomId != null) {
        SocketService.instance.joinRoom(roomId);
      }

      await _initPeerConnection();
      await _setupLocalMedia();

      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdpData['sdp'], sdpData['type']),
      );

      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      _sendSignalingMessage(
        type: SignalingType.answer,
        payload: {'sdp': answer.sdp, 'type': answer.type},
      );
    } catch (e) {
      print("Lỗi xử lý offer: $e");
      await endCall();
    }
  }

  Future<void> handleAnswer(Map<String, dynamic> sdpData) async {
    if (_peerConnection == null) return;
    try {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdpData['sdp'], sdpData['type']),
      );
    } catch (e) {
      print("Lỗi xử lý answer: $e");
    }
  }

  Future<void> handleIceCandidate(Map<String, dynamic> data) async {
    if (_peerConnection == null) return;
    try {
      await _peerConnection!.addCandidate(
        RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMLineIndex'],
        ),
      );
    } catch (e) {
      print("Lỗi thêm ICE candidate: $e");
    }
  }

  /// Ends the current call or rejects an incoming one if targetUserId is provided
  Future<void> endCall([String? targetUserId]) async {
    try {
      if (targetUserId != null) {
        _sendSignalingMessage(
          type: SignalingType.end,
          overrideTargetId: targetUserId,
          overrideIsRoom: false,
        );
      } else {
        _sendSignalingMessage(type: SignalingType.end);
      }

      _localStream?.getTracks().forEach((track) => track.stop());
      await _localStream?.dispose();
      _localStream = null;

      await _peerConnection?.close();
      await _peerConnection?.dispose();
      _peerConnection = null;

      _currentTargetId = null;
      _currentRoomId = null;
      _isRoomCall = false;

      onCallEnd?.call();
    } catch (e) {
      print("Lỗi kết thúc cuộc gọi: $e");
    }
  }

  void toggleMute(bool isMuted) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !isMuted;
    });
  }

  void toggleCamera(bool isOff) {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !isOff;
    });
  }

  Future<void> switchCamera() async {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      final videoTrack = _localStream!.getVideoTracks().first;
      await Helper.switchCamera(videoTrack);
    }
  }
}