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
  MediaStream? _remoteStream;
  final List<RTCIceCandidate> _remoteIceCandidatesBuffer = [];
  bool _isRemoteDescriptionSet = false;

  String? _currentTargetId;
  String? _currentRoomId;
  bool _isRoomCall = false;

  Map<String, dynamic> get _configuration => {
    'iceServers': [
      {
        'urls': [
          'stun:stun.cloudflare.com:3478',
          'turn:turn.cloudflare.com:3478?transport=udp',
          'turn:turn.cloudflare.com:3478?transport=tcp',
          'turns:turn.cloudflare.com:5349?transport=tcp',
        ],
        'username': AppStrings.turnUsername,
        'credential': AppStrings.turnPassword,
      },
    ],
  };

  Function(MediaStream stream)? _onLocalStreamCallback;

  set onLocalStream(Function(MediaStream stream)? callback) {
    _onLocalStreamCallback = callback;
    if (callback != null && _localStream != null) {
      callback(_localStream!);
    }
  }

  Function(MediaStream stream)? get onLocalStream => _onLocalStreamCallback;

  Function(MediaStream stream)? _onRemoteStreamCallback;

  set onRemoteStream(Function(MediaStream stream)? callback) {
    _onRemoteStreamCallback = callback;
    if (callback != null && _remoteStream != null) {
      callback(_remoteStream!);
    }
  }

  Function(MediaStream stream)? get onRemoteStream => _onRemoteStreamCallback;

  Function(RTCSignalingState state)? onSignalingStateChange;
  Function(RTCPeerConnectionState state)? onConnectionStateChange;
  Function()? onCallEnd;

  Future<void> _initPeerConnection() async {
    if (_peerConnection != null) return;

    try {
      final config = _configuration;

      _peerConnection = await createPeerConnection(config);

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
        if (candidate.candidate != null) {
          await _sendSignalingMessage(
            type: SignalingType.iceCandidate,
            payload: {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
          );
        }
      };

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          _onRemoteStreamCallback?.call(_remoteStream!);
        }
      };

      _peerConnection!.onAddStream = (MediaStream stream) {
        _remoteStream = stream;
        _onRemoteStreamCallback?.call(_remoteStream!);
      };

      _peerConnection!.onSignalingState = (state) {
        onSignalingStateChange?.call(state);
      };

      _peerConnection!.onConnectionState = (state) {
        onConnectionStateChange?.call(state);
      };

      _peerConnection!.onIceConnectionState = (state) {};
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _setupLocalMedia() async {
    if (_localStream != null) return;

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
      });

      _onLocalStreamCallback?.call(_localStream!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _addTracksToConnection() async {
    if (_localStream == null || _peerConnection == null) return;

    for (var track in _localStream!.getTracks()) {
      _peerConnection!.addTrack(track, _localStream!);
    }
  }

  Future<void> startDirectCall(String targetUserId) async {
    try {
      _isRoomCall = false;
      _currentTargetId = targetUserId;
      _currentRoomId = null;

      await _setupLocalMedia();
      await _initPeerConnection();
      await _addTracksToConnection();

      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      await _sendSignalingMessage(
        type: SignalingType.offer,
        payload: {'sdp': offer.sdp, 'type': offer.type},
      );
    } catch (e) {
      await endCall();
    }
  }

  Future<void> startRoomCall(String roomId) async {
    try {
      _isRoomCall = true;
      _currentRoomId = roomId;
      _currentTargetId = null;

      SocketService.instance.joinRoom(roomId);

      await _setupLocalMedia();
      await _initPeerConnection();
      await _addTracksToConnection();

      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      await _sendSignalingMessage(
        type: SignalingType.offer,
        payload: {'sdp': offer.sdp, 'type': offer.type},
      );
    } catch (e) {
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

      await _setupLocalMedia();
      await _initPeerConnection();
      await _addTracksToConnection();

      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdpData['sdp'], sdpData['type']),
      );
      _isRemoteDescriptionSet = true;
      await _processRemoteIceCandidates();

      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      await _sendSignalingMessage(
        type: SignalingType.answer,
        payload: {'sdp': answer.sdp, 'type': answer.type},
      );
    } catch (e) {
      await endCall();
    }
  }

  Future<void> handleAnswer(Map<String, dynamic> sdpData) async {
    if (_peerConnection == null) return;

    final state = _peerConnection!.signalingState;
    if (state != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      return;
    }

    try {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdpData['sdp'], sdpData['type']),
      );
      _isRemoteDescriptionSet = true;
      await _processRemoteIceCandidates();
    } catch (e) {
      //
    }
  }

  Future<void> handleIceCandidate(Map<String, dynamic> data) async {
    final candidate = RTCIceCandidate(
      data['candidate'],
      data['sdpMid'],
      data['sdpMLineIndex'],
    );

    if (_peerConnection == null ||
        !_isRemoteDescriptionSet ||
        _peerConnection!.signalingState == RTCSignalingState.RTCSignalingStateClosed) {
      _remoteIceCandidatesBuffer.add(candidate);
      return;
    }

    try {
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      //
    }
  }

  Future<void> _processRemoteIceCandidates() async {
    if (_peerConnection == null || _remoteIceCandidatesBuffer.isEmpty) return;
    for (var candidate in List.from(_remoteIceCandidatesBuffer)) {
      try {
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        //
      }
    }
    _remoteIceCandidatesBuffer.clear();
  }

  Future<void> endCall([String? targetUserId]) async {
    try {
      if (targetUserId != null) {
        await _sendSignalingMessage(
          type: SignalingType.end,
          overrideTargetId: targetUserId,
          overrideIsRoom: false,
        );
      } else {
        await _sendSignalingMessage(type: SignalingType.end);
      }
    

      // Dispose local media
      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          track.stop();
        }
        await _localStream!.dispose();
        _localStream = null;
      }

      // Dispose remote media
      if (_remoteStream != null) {
        for (var track in _remoteStream!.getTracks()) {
          track.stop();
        }
        await _remoteStream!.dispose();
        _remoteStream = null;
      }

      // Dispose peer connection
      if (_peerConnection != null) {
        await _peerConnection!.close();
        await _peerConnection!.dispose();
        _peerConnection = null;
      }

      _currentTargetId = null;
      _currentRoomId = null;
      _isRoomCall = false;
      _isRemoteDescriptionSet = false;
      _remoteIceCandidatesBuffer.clear();

      onCallEnd?.call();
    } catch (e) {
      //
    }
  }

  Future<void> _sendSignalingMessage({
    required SignalingType type,
    dynamic payload,
    String? overrideTargetId,
    String? overrideRoomId,
    bool? overrideIsRoom,
  }) async {
    final isRoom = overrideIsRoom ?? _isRoomCall;
    final roomId = overrideRoomId ?? _currentRoomId;
    final targetId = overrideTargetId ?? _currentTargetId;

    if (isRoom && roomId != null) {
      SocketService.instance.sendRoomCall(
        roomId: roomId,
        signalingType: type,
        signalingPayload: payload,
      );
    } else if (targetId != null) {
      SocketService.instance.sendDirectCall(
        targetUserId: targetId,
        signalingType: type,
        signalingPayload: payload,
      );
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
