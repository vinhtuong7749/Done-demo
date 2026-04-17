import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import 'auth/simple_auth_helper.dart';

class ChatSocketService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Timer? _pingTimer;
  Timer? _reconnectTimer;

  String? _conversationId;
  bool _manualClosed = false;
  int _reconnectAttempt = 0;

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  bool get isConnected => _channel != null;

  Future<void> connect(String conversationId) async {
    _conversationId = conversationId;
    _manualClosed = false;

    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Không thể kết nối realtime khi chưa đăng nhập');
    }

    await _closeInternal();

    final uri = Uri.parse(
      '${AppConfig.chatWebSocketBaseUrl}/conversations/$conversationId?token=$token',
    );

    debugPrint('🔌 [CHAT SOCKET] Connecting to $uri');

    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );

    _reconnectAttempt = 0;
    _startPing();
  }

  Future<void> sendTyping(bool isTyping) async {
    _sendJson({
      'type': 'typing',
      'is_typing': isTyping,
    });
  }

  Future<void> sendReadEvent() async {
    _sendJson({'type': 'message.read'});
  }

  Future<void> disconnect() async {
    _manualClosed = true;
    await _closeInternal();
  }

  Future<void> dispose() async {
    await disconnect();
    await _eventController.close();
  }

  void _onData(dynamic data) {
    try {
      if (data is String) {
        final parsed = jsonDecode(data);
        if (parsed is Map<String, dynamic>) {
          _eventController.add(parsed);
          return;
        }
      }

      if (data is Map<String, dynamic>) {
        _eventController.add(data);
        return;
      }

      _eventController.add({'type': 'socket.raw', 'data': data.toString()});
    } catch (e) {
      _eventController.add({'type': 'socket.error', 'message': e.toString()});
    }
  }

  void _onError(Object error) {
    _eventController.add({'type': 'socket.error', 'message': error.toString()});
  }

  void _onDone() {
    _eventController.add({'type': 'socket.disconnected'});

    if (_manualClosed) {
      return;
    }

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_conversationId == null || _conversationId!.isEmpty) {
      return;
    }

    _reconnectTimer?.cancel();

    final cappedAttempt = _reconnectAttempt.clamp(0, 5);
    final delaySeconds = 1 << cappedAttempt;
    _reconnectAttempt = cappedAttempt + 1;

    _eventController.add({
      'type': 'socket.reconnecting',
      'attempt': _reconnectAttempt,
      'delay_seconds': delaySeconds,
    });

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      try {
        await connect(_conversationId!);
      } catch (e) {
        _eventController.add({'type': 'socket.error', 'message': e.toString()});
        _scheduleReconnect();
      }
    });
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _sendJson({'type': 'ping'});
    });
  }

  void _sendJson(Map<String, dynamic> payload) {
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (e) {
      _eventController.add({'type': 'socket.error', 'message': e.toString()});
    }
  }

  Future<void> _closeInternal() async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();

    try {
      await _channel?.sink.close();
    } catch (_) {
      // Ignore close errors
    }

    _channel = null;
  }
}
