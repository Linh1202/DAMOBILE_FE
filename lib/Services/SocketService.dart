import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:doanmobile/Models/Api/SocketMessage.dart';
import 'package:doanmobile/Services/AuthStorage.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../Utils/Constants/AppStrings.dart';
import '../Utils/Constants/AppEnums.dart';
import '../Utils/Constants/ApiEndpoints.dart';

class SocketService {
  static final SocketService instance = SocketService._internal();
  factory SocketService() => instance;
  SocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  int _retryCount = 0;
  final int _maxRetries = 5;

  final StreamController<SocketMessage> _messageController =
      StreamController<SocketMessage>.broadcast();
  Stream<SocketMessage> get messageStream => _messageController.stream;

  bool get isConnected => _isConnected;

  Future<String> _getWsUrl() async {
    String base = AppStrings.baseUrl.replaceFirst('http', 'ws');

    if (base.contains('/api')) {
      base = base.replaceFirst('/api', ApiEndpoints.ws);
    } else if (!base.endsWith(ApiEndpoints.ws)) {
      base = "$base${ApiEndpoints.ws}";
    }

    if (Platform.isAndroid) {
      if (base.contains('localhost')) {
        base = base.replaceFirst('localhost', '10.0.2.2');
      }
      if (base.contains('127.0.0.1')) {
        base = base.replaceFirst('127.0.0.1', '10.0.2.2');
      }
    }

    final token = await AuthStorage.readToken();
    if (token != null && token.isNotEmpty) {
      if (base.contains('?')) {
        return "$base&token=$token";
      } else {
        return "$base?token=$token";
      }
    }
    return base;
  }

  Future<void> connect() async {
    if (_isConnected || _isConnecting) return;
    _isConnecting = true;

    final url = await _getWsUrl();

    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse(url),
        pingInterval: const Duration(seconds: 10),
      );

      _channel!.stream.listen(
        (message) {
          _retryCount = 0;
          _isConnected = true;
          _isConnecting = false;
          _cancelReconnectTimer();

          try {
            final decoded = jsonDecode(message);
            if (decoded is Map<String, dynamic>) {
              _messageController.add(SocketMessage.fromJson(decoded));
            } else if (decoded is List) {
              // Handle HISTORY which returns a List of HistoryMessage objects
              _messageController.add(SocketMessage(
                type: MessageType.history,
                payload: decoded,
              ));
            }
          } catch (e) {
            _handleError("Lỗi giải mã tin nhắn: $e");
          }
        },
        onDone: () {
          _handleConnectionClosed("Kết nối bị đóng");
        },
        onError: (error) {
          _handleConnectionClosed("Lỗi kết nối: $error");
        },
        cancelOnError: true,
      );
    } catch (e) {
      _handleConnectionClosed("Không thể khởi tạo kết nối: $e");
    }
  }

  void _handleConnectionClosed(String reason) {
    _isConnected = false;
    _isConnecting = false;
    _channel = null;

    _messageController.add(SocketMessage(
      type: MessageType.error,
      content: reason,
    ));

    _scheduleReconnect();
  }

  void _handleError(String error) {
    _messageController.add(SocketMessage(
      type: MessageType.error,
      content: error,
    ));
  }

  void _scheduleReconnect() {
    if (_retryCount >= _maxRetries) {
      _handleError("Đã đạt số lần thử kết nối tối đa.");
      return;
    }

    _cancelReconnectTimer();
    
    // Exponential backoff
    final List<int> backoffDelays = [2, 5, 10, 30, 60];
    final delay = Duration(seconds: backoffDelays[_retryCount]);
    _retryCount++;

    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void sendMessage(SocketMessage message) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(jsonEncode(message.toJson()));
      } catch (e) {
        _handleError("Không thể gửi tin nhắn: $e");
      }
    } else {
      _handleError("Không có kết nối WebSocket.");
    }
  }

  // --- Chat & Room Management ---

  void joinRoom(String roomId) {
    sendMessage(SocketMessage.createJoinRoom(roomId));
  }

  void leaveRoom(String roomId) {
    sendMessage(SocketMessage.createLeaveRoom(roomId));
  }

  void sendChatMessage(String roomId, String content, {String? mediaUrl}) {
    sendMessage(SocketMessage.createChatMessage(
      roomId: roomId,
      content: content,
      mediaUrl: mediaUrl,
    ));
  }

  void sendReaction(String roomId, String messageId, String emoji) {
    sendMessage(SocketMessage.createReaction(
      roomId: roomId,
      messageId: messageId,
      emoji: emoji,
    ));
  }

  void sendTyping(String roomId) {
    sendMessage(SocketMessage.createTyping(roomId));
  }

  // --- Social & Notifications ---

  void sendFriendRequest(String targetIdOrUsername) {
    sendMessage(SocketMessage(
      type: MessageType.friendRequest,
      roomId: targetIdOrUsername,
    ));
  }

  void sendGroupInvite(String targetIdOrUsername, String content) {
    sendMessage(SocketMessage(
      type: MessageType.groupInvite,
      roomId: targetIdOrUsername,
      content: content,
    ));
  }

  void sendNotification(String? targetIdOrUsername, String content) {
    sendMessage(SocketMessage(
      type: MessageType.notification,
      roomId: targetIdOrUsername ?? "",
      content: content,
    ));
  }

  // --- WebRTC Signaling ---

  void sendDirectCall({
    required String targetUserId,
    required SignalingType type,
    dynamic payload,
  }) {
    sendMessage(SocketMessage.createDirectCall(
      targetId: targetUserId,
      signalingType: type,
      signalingPayload: payload,
    ));
  }

  void sendRoomCall({
    required String roomId,
    required SignalingType type,
    dynamic payload,
  }) {
    sendMessage(SocketMessage.createRoomCall(
      roomId: roomId,
      signalingType: type,
      signalingPayload: payload,
    ));
  }

  void close() {
    _cancelReconnectTimer();
    _channel?.sink.close();
    _isConnected = false;
    _isConnecting = false;
    _retryCount = 0;
  }
}