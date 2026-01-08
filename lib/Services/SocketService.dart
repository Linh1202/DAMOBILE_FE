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
  StreamSubscription? _subscription;
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

  Future<void> ensureConnected() async {
    if (_isConnected) return;
    if (!_isConnecting) {
      await connect();
    }
    
    int attempts = 0;
    while (!_isConnected && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }
  }

  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      print('🔌 WS: Already connected or connecting, skip');
      return;
    }
    _isConnecting = true;

    final url = await _getWsUrl();
    print("WebSocket: Connecting to $url...");

    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse(url),
        pingInterval: const Duration(seconds: 5),
      );

      _channel!.ready.then((_) {
        if (!_isConnected) {
          print("WebSocket: Connection established");
          _isConnected = true;
          _isConnecting = false;
          _retryCount = 0;
          _cancelReconnectTimer();
        }
      }).catchError((e) {
        _handleConnectionClosed("Lỗi khi thiết lập kết nối: $e");
      });

      await _subscription?.cancel();

      _subscription = _channel!.stream.listen(
        (message) {
          print("WebSocket: Message received: $message");
          try {
            final decoded = jsonDecode(message);
            print('📥 WS decoded: $decoded');
            if (decoded is Map<String, dynamic>) {
              final socketMsg = SocketMessage.fromJson(decoded);
              print('📥 WS parsed: type=${socketMsg.type.value}, roomId=${socketMsg.roomId}');
              _messageController.add(socketMsg);
            } else if (decoded is List) {
              print('📥 WS received HISTORY with ${decoded.length} messages');
              _messageController.add(SocketMessage(
                type: MessageType.history,
                payload: decoded,
              ));
            }
          } catch (e) {
            print('❌ WS decode error: $e');
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
    print("WebSocket: Connection closed ($reason)");
    _isConnected = false;
    _isConnecting = false;
    _channel = null;
    _subscription?.cancel();
    _subscription = null;

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
    
    final List<int> backoffDelays = [2, 5, 10, 30, 60];
    final delay = Duration(seconds: backoffDelays[_retryCount]);
    _retryCount++;

    print("WebSocket: Scheduling reconnect in ${delay.inSeconds}s (attempt $_retryCount/$_maxRetries)");
    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> sendMessage(SocketMessage message) async {
    if (!_isConnected) {
      print("WebSocket: Not connected. Attempting to connect before sending message...");
      await ensureConnected();
    }

    if (_channel != null && _isConnected) {
      try {
        final json = jsonEncode(message.toJson());
        print('📤 WS sending: $json');
        _channel!.sink.add(json);
      } catch (e) {
        _handleError("Không thể gửi tin nhắn: $e");
      }
    } else {
      print("WebSocket: Failed to send message - still not connected after retry.");
      _handleError("Không có kết nối WebSocket.");
    }
  }

  void joinRoom(String roomId) {
    print('📍 WS joinRoom: $roomId');
    sendMessage(SocketMessage.createJoinRoom(roomId));
  }

  void leaveRoom(String roomId) {
    print('📍 WS leaveRoom: $roomId');
    sendMessage(SocketMessage.createLeaveRoom(roomId));
  }

  void sendChatMessage(String roomId, String content, {String? mediaUrl}) {
    print('💬 WS sendChatMessage: roomId=$roomId, content=$content, mediaUrl=$mediaUrl');
    sendMessage(SocketMessage.createChatMessage(
      roomId: roomId,
      content: content,
      mediaUrl: mediaUrl,
    ));
  }

  void sendReaction(String roomId, String messageId, String emoji) {
    print('👍 WS sendReaction: roomId=$roomId, messageId=$messageId, emoji=$emoji');
    sendMessage(SocketMessage.createReaction(
      roomId: roomId,
      messageId: messageId,
      emoji: emoji,
    ));
  }

  void sendTyping(String roomId) {
    print('✏️ WS sendTyping: roomId=$roomId');
    sendMessage(SocketMessage.createTyping(roomId));
  }

  void sendFriendRequest(String targetUserId) {
    print('👥 WS sendFriendRequest: targetUserId=$targetUserId');
    sendMessage(SocketMessage.createFriendRequest(targetUserId));
  }

  void sendGroupInvite(String targetUserId, String inviteMessage) {
    print('👫 WS sendGroupInvite: targetUserId=$targetUserId, message=$inviteMessage');
    sendMessage(SocketMessage.createGroupInvite(
      targetUserId: targetUserId,
      content: inviteMessage,
    ));
  }

  void sendNotification({String? targetUserId, required String content}) {
    print('🔔 WS sendNotification: targetUserId=$targetUserId, content=$content');
    sendMessage(SocketMessage.createNotification(
      targetUserId: targetUserId,
      content: content,
    ));
  }

  void sendDirectCall({
    required String targetUserId,
    required SignalingType signalingType,
    dynamic signalingPayload,
  }) {
    print('📞 WS sendDirectCall: targetUserId=$targetUserId, type=$signalingType');
    sendMessage(SocketMessage.createDirectCall(
      targetId: targetUserId,
      signalingType: signalingType,
      signalingPayload: signalingPayload,
    ));
  }

  void sendRoomCall({
    required String roomId,
    required SignalingType signalingType,
    dynamic signalingPayload,
  }) {
    print('📞 WS sendRoomCall: roomId=$roomId, type=$signalingType');
    sendMessage(SocketMessage.createRoomCall(
      roomId: roomId,
      signalingType: signalingType,
      signalingPayload: signalingPayload,
    ));
  }

  void close() {
    print('🔌 WS closing connection...');
    _cancelReconnectTimer();
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _isConnected = false;
    _isConnecting = false;
    _retryCount = 0;
  }
}