import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/services/pusher_service.dart';
import 'package:supplies_chat_app/core/services/pusher_transport.dart';

class FakeTransport implements PusherTransport {
  final controller = StreamController<Object>.broadcast(sync: true);
  final sent = <Map<String, dynamic>>[];
  Uri? connectedUri;
  @override
  Stream<Object> get frames => controller.stream;
  @override
  Future<void> connect(Uri uri) async {
    connectedUri = uri;
  }

  @override
  void send(String frame) =>
      sent.add(jsonDecode(frame) as Map<String, dynamic>);
  @override
  Future<void> close() async {}
  void receive(String event, Object data, [String? channel]) => controller.add(
    jsonEncode({'event': event, 'data': data, 'channel': ?channel}),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('connects to the secure Pusher websocket endpoint', () async {
    final transport = FakeTransport();
    final service = PusherService(transportFactory: () => transport);
    await service.connect(
      apiKey: 'public-key',
      cluster: 'eu',
      authorizer: (_, _) async => {'auth': 'signed'},
    );
    expect(transport.connectedUri?.scheme, 'wss');
    expect(transport.connectedUri?.host, 'ws-eu.pusher.com');
    expect(transport.connectedUri?.path, '/app/public-key');
    expect(transport.connectedUri?.queryParameters['protocol'], '7');
    await service.disconnect();
  });
  test('shared handlers survive removal of a single owner', () async {
    final transport = FakeTransport();
    final service = PusherService(transportFactory: () => transport);
    var a = 0;
    var b = 0;
    void first(Map<String, dynamic> _) {
      a++;
    }

    void second(Map<String, dynamic> _) {
      b++;
    }

    await service.bindEvent(
      channelName: 'private-test',
      eventName: 'message.new',
      handler: first,
    );
    await service.bindEvent(
      channelName: 'private-test',
      eventName: 'message.new',
      handler: second,
    );
    await service.connect(
      apiKey: 'key',
      cluster: 'eu',
      authorizer: (_, _) async => {'auth': 'signed'},
    );
    transport.receive(
      'pusher:connection_established',
      jsonEncode({'socket_id': '1.1', 'activity_timeout': 120}),
    );
    await Future<void>.delayed(Duration.zero);
    transport.receive(
      'pusher_internal:subscription_succeeded',
      '{}',
      'private-test',
    );
    await service.unbindEvent(
      channelName: 'private-test',
      eventName: 'message.new',
      handler: first,
    );
    transport.receive('message.new', '{}', 'private-test');
    expect(a, 0);
    expect(b, 1);
    await service.disconnect();
  });
  test('late authorization cannot subscribe a disconnected session', () async {
    final transport = FakeTransport();
    final authorization = Completer<Map<String, dynamic>?>();
    final service = PusherService(transportFactory: () => transport);
    await service.bindEvent(
      channelName: 'private-test',
      eventName: 'message.new',
      handler: (_) {},
    );
    await service.connect(
      apiKey: 'key',
      cluster: 'eu',
      authorizer: (_, _) => authorization.future,
    );
    transport.receive(
      'pusher:connection_established',
      jsonEncode({'socket_id': '1.1'}),
    );
    await service.disconnect();
    authorization.complete({'auth': 'old'});
    await Future<void>.delayed(Duration.zero);
    expect(
      transport.sent.where((f) => f['event'] == 'pusher:subscribe'),
      isEmpty,
    );
  });
  test('client typing is sent only after authorized subscription', () async {
    final transport = FakeTransport();
    final service = PusherService(transportFactory: () => transport);
    await service.connect(
      apiKey: 'key',
      cluster: 'eu',
      authorizer: (_, _) async => {'auth': 'signed'},
    );
    await service.bindEvent(
      channelName: 'private-test',
      eventName: 'client-typing',
      handler: (_) {},
    );
    expect(
      await service.trigger(
        channelName: 'private-test',
        eventName: 'client-typing',
        data: {'isTyping': true},
      ),
      false,
    );
    transport.receive(
      'pusher:connection_established',
      jsonEncode({'socket_id': '1.1'}),
    );
    await Future<void>.delayed(Duration.zero);
    transport.receive(
      'pusher_internal:subscription_succeeded',
      '{}',
      'private-test',
    );
    expect(
      await service.trigger(
        channelName: 'private-test',
        eventName: 'client-typing',
        data: {'isTyping': true},
      ),
      true,
    );
    await service.disconnect();
  });
  testWidgets('a socket without a Pusher handshake is retried', (tester) async {
    var attempts = 0;
    final service = PusherService(
      transportFactory: () {
        attempts++;
        return FakeTransport();
      },
    );
    await service.connect(
      apiKey: 'key',
      cluster: 'eu',
      authorizer: (_, _) async => {'auth': 'signed'},
    );
    await tester.pump(const Duration(seconds: 25));
    expect(service.connectionState, RealtimeConnectionState.reconnecting);
    await tester.pump(const Duration(seconds: 2));
    expect(attempts, 2);
    await tester.pump();
    unawaited(service.disconnect());
    await tester.pump();
  });
}
