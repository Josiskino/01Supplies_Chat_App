import 'dart:async';
import 'dart:io';

/// Pusher protocol transport. No platform plugin: supported by all native apps.
abstract interface class PusherTransport {
  Stream<Object> get frames;
  Future<void> connect(Uri uri);
  void send(String frame);
  Future<void> close();
}

class WebSocketPusherTransport implements PusherTransport {
  WebSocket? _socket;
  @override
  Stream<Object> get frames => _socket!.cast<Object>();
  @override
  Future<void> connect(Uri uri) async {
    _socket = await WebSocket.connect(
      uri.toString(),
    ).timeout(const Duration(seconds: 20));
    _socket!.pingInterval = const Duration(seconds: 30);
  }

  @override
  void send(String frame) => _socket?.add(frame);
  @override
  Future<void> close() async => _socket?.close();
}
