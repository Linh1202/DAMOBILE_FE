import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

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
      return "$base?token=$token";
    }
    return base;
  }

  Future<void> connect() async {
    if (_isConnected) return;
    final url = await _getWsUrl();
    var headers = await AuthStorage.authHeaders();

    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse(url),
        headers: headers,
      );
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (data is Map<String, dynamic>) {
              _messageController.add(data);
            }
          } catch (e) {
          }
        },
        onDone: () {
          _isConnected = false;
        },
        onError: (error) {
          _isConnected = false;
        },
      );
    } catch (e) {
    }
  }

  Stream? get stream => _channel?.stream;

  void sendMessage(dynamic message) {
    if (_channel != null) {
      if (message is Map || message is List) {
        _channel!.sink.add(jsonEncode(message));
      } else {
        _channel!.sink.add(message);
      }
    }
  }

  void sendDirectCall({
    required String targetUserId,
    required SignalingType type,
    dynamic payload,
  }) {
    final message = {
      "type": MessageType.directCall.value,
      "room_id": targetUserId,
      "payload": {
        "type": type.value,
        if (payload != null) "payload": payload,
      },
    };
    sendMessage(message);
  }

  void joinRoom(String roomId) {
    sendMessage({"type": MessageType.joinRoom.value, "room_id": roomId});
  }

  void sendRoomCall({
    required String roomId,
    required SignalingType type,
    dynamic payload,
  }) {
    final message = {
      "type": MessageType.call.value,
      "room_id": roomId,
      "payload": {
        "type": type.value,
        if (payload != null) "payload": payload,
      },
    };
    sendMessage(message);
  }

  void close() {
    _channel?.sink.close();
    _isConnected = false;
  }
}