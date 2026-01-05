import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'SocketService.dart';
import '../Utils/Constants/AppEnums.dart';

class WebRTCService {
  static final WebRTCService instance = WebRTCService._internal();
  factory WebRTCService() => instance;
  WebRTCService._internal();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  Function(MediaStream stream)? onLocalStream;
  Function(MediaStream stream)? onRemoteStream;
  Function(RTCSignalingState state)? onSignalingStateChange;
  Function(RTCPeerConnectionState state)? onConnectionStateChange;

  Future<void> _initPeerConnection(String targetUserId) async {
    if (_peerConnection != null) return;

    try {
      _peerConnection = await createPeerConnection(_configuration);

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        SocketService.instance.sendDirectCall(
          targetUserId: targetUserId,
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
      await _initPeerConnection(targetUserId);
      await _setupLocalMedia();

      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      SocketService.instance.sendDirectCall(
        targetUserId: targetUserId,
        type: SignalingType.offer,
        payload: {'sdp': offer.sdp, 'type': offer.type},
      );
    } catch (e) {
      print("Error starting direct call: $e");
      await endCall(targetUserId);
    }
  }

  Future<void> handleOffer(
    String senderId,
    Map<String, dynamic> sdpData,
  ) async {
    try {
      await _initPeerConnection(senderId);
      await _setupLocalMedia();

      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdpData['sdp'], sdpData['type']),
      );

      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      SocketService.instance.sendDirectCall(
        targetUserId: senderId,
        type: SignalingType.answer,
        payload: {'sdp': answer.sdp, 'type': answer.type},
      );
    } catch (e) {
      print("Error handling offer: $e");
      await endCall(senderId);
    }
  }

  Future<void> handleAnswer(Map<String, dynamic> sdpData) async {
    if (_peerConnection == null) return;
    try {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdpData['sdp'], sdpData['type']),
      );
    } catch (e) {
      print("Error handling answer: $e");
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
      print("Error adding ICE candidate: $e");
    }
  }

  Future<void> endCall(String? targetUserId) async {
    try {
      if (targetUserId != null) {
        SocketService.instance.sendDirectCall(
          targetUserId: targetUserId,
          type: SignalingType.end,
        );
      }

      _localStream?.getTracks().forEach((track) => track.stop());
      await _localStream?.dispose();
      _localStream = null;

      await _peerConnection?.close();
      await _peerConnection?.dispose();
      _peerConnection = null;
    } catch (e) {
      print("Error ending call: $e");
      rethrow;
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
