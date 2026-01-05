import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../Services/WebRTCService.dart';

class CallView extends StatefulWidget {
  final String? targetUserId;
  final String? userName;
  final bool isIncoming;

  const CallView({
    Key? key,
    this.targetUserId,
    this.userName,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  State<CallView> createState() => _CallViewState();
}

class _CallViewState extends State<CallView> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isMicOff = false;
  bool _isCameraOff = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await [Permission.camera, Permission.microphone].request();

    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    WebRTCService.instance.onLocalStream = (stream) {
      setState(() {
        _localRenderer.srcObject = stream;
      });
    };

    WebRTCService.instance.onRemoteStream = (stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
    };

    WebRTCService.instance.onCallEnd = () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    };

    if (!widget.isIncoming && widget.targetUserId != null) {
      await WebRTCService.instance.startDirectCall(widget.targetUserId!);
    }
  }

  @override
  void dispose() {
    WebRTCService.instance.onLocalStream = null;
    WebRTCService.instance.onRemoteStream = null;
    WebRTCService.instance.onCallEnd = null;
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void _hangUp() async {
    await WebRTCService.instance.endCall(widget.targetUserId);
  }

  void _toggleMic() {
    setState(() {
      _isMicOff = !_isMicOff;
      _localRenderer.srcObject?.getAudioTracks().forEach((track) {
        track.enabled = !_isMicOff;
      });
    });
  }

  void _toggleCamera() {
    setState(() {
      _isCameraOff = !_isCameraOff;
      _localRenderer.srcObject?.getVideoTracks().forEach((track) {
        track.enabled = !_isCameraOff;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),

          Positioned(
            top: 50,
            right: 20,
            width: 120,
            height: 180,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              clipBehavior: Clip.antiAlias,
              child: RTCVideoView(
                _localRenderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),

          // Call Info
          Positioned(
            top: 60,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isIncoming ? "Cuộc gọi đến" : "Đang gọi...",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  widget.userName ?? widget.targetUserId ?? "Người dùng",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isMicOff ? Icons.mic_off : Icons.mic,
                  color: _isMicOff ? Colors.red : Colors.white24,
                  onPressed: _toggleMic,
                ),
                _buildControlButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  iconColor: Colors.white,
                  onPressed: _hangUp,
                  size: 70,
                ),
                _buildControlButton(
                  icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                  color: _isCameraOff ? Colors.red : Colors.white24,
                  onPressed: _toggleCamera,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    Color iconColor = Colors.white,
    double size = 56,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: FloatingActionButton(
        heroTag: null,
        onPressed: onPressed,
        backgroundColor: color,
        child: Icon(icon, color: iconColor, size: size * 0.5),
        elevation: 0,
      ),
    );
  }
}
