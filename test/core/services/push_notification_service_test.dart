import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/abstract/api_client_interface.dart';
import 'package:supplies_chat_app/core/utils/api_types.dart';
import 'package:supplies_chat_app/core/services/push_notification_service.dart';
import 'package:supplies_chat_app/core/services/push_message.dart';
import 'package:supplies_chat_app/core/services/push_session_store.dart';
import 'package:supplies_chat_app/core/services/push_local_notifications.dart';
import 'package:supplies_chat_app/core/services/push_background_handler.dart';

class FakeMessaging implements PushMessaging {
  final tokens = StreamController<String>.broadcast(sync: true);
  final foreground = StreamController<PushMessage>.broadcast(sync: true);
  final opened = StreamController<PushMessage>.broadcast(sync: true);
  Completer<PushMessage?>? initial;
  int deletes = 0;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<String?> getToken() async => 'device-token';
  @override
  Future<void> deleteToken() async {
    deletes++;
  }

  @override
  Stream<String> get tokenRefresh => tokens.stream;
  @override
  Stream<PushMessage> get foregroundMessages => foreground.stream;
  @override
  Stream<PushMessage> get openedMessages => opened.stream;
  @override
  Future<PushMessage?> getInitialMessage() async =>
      initial == null ? null : await initial!.future;
}

class MemoryStore implements PushSessionStore {
  String? account;
  @override
  Future<String?> readAccount() async => account;
  @override
  Future<void> writeAccount(String? value) async {
    account = value;
  }
}

class FakeDisplay implements PushLocalNotifications {
  final opened = StreamController<PushMessage>.broadcast(sync: true);
  final shown = <PushMessage>[];
  int cancellations = 0;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> show(PushMessage message) async {
    shown.add(message);
  }

  @override
  Future<void> cancelAll() async {
    cancellations++;
  }

  @override
  Stream<PushMessage> get openedMessages => opened.stream;
  @override
  Future<PushMessage?> getInitialMessage() async => null;
  @override
  Future<void> dispose() async {}
}

class FakeApi implements ApiClientInterface {
  final calls = <String>[];
  @override
  Future<ApiResult<T>> request<T>({
    String? baseUrl,
    required String path,
    required HttpMethod method,
    required JsonParser<T> fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? dataKey,
    List<MetadataConfig> metadataConfigs = const [],
    JsonParser<dynamic>? itemFromJson,
    List<String>? listPath,
  }) async {
    calls.add('${method.name}:$path:${(data as Map?)?['fcmToken']}');
    return ApiSuccess(data: fromJson({}), statusCode: 200);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeMessaging messaging;
  late MemoryStore store;
  late FakeApi api;
  late FakeDisplay display;
  late PushNotificationService service;
  setUp(() {
    messaging = FakeMessaging();
    store = MemoryStore();
    api = FakeApi();
    display = FakeDisplay();
    service = PushNotificationService(
      api,
      messaging: messaging,
      sessionStore: store,
      localNotifications: display,
      supported: true,
      platform: 'android',
    );
  });
  tearDown(() async {
    await service.dispose();
    await messaging.tokens.close();
    await messaging.foreground.close();
    await messaging.opened.close();
    await display.opened.close();
  });
  test(
    'each account registers the same device and logout detaches listeners',
    () async {
      await service.setSession('a');
      await service.setSession('a');
      expect(api.calls.where((c) => c.startsWith('post:')).length, 1);
      await service.setSession(null);
      expect(store.account, isNull);
      expect(messaging.tokens.hasListener, false);
      expect(api.calls, contains('delete:users/me/devices:device-token'));
      await service.setSession('b');
      expect(api.calls.where((c) => c.startsWith('post:')).length, 2);
    },
  );
  test('late initial notification cannot emit after logout', () async {
    messaging.initial = Completer<PushMessage?>();
    final received = <PushMessage>[];
    final subscription = service.openedMessages.listen(received.add);
    await service.setSession('a');
    await service.setSession(null);
    messaging.initial!.complete(PushMessage({'conversationId': 'private'}));
    await Future<void>.delayed(Duration.zero);
    expect(received, isEmpty);
    await subscription.cancel();
  });
  test(
    'foreground FCM duplicates refresh only once and other recipients drop',
    () async {
      final received = <PushMessage>[];
      final sub = service.foregroundMessages.listen(received.add);
      await service.setSession('a');
      messaging.foreground.add(
        PushMessage({
          'conversationId': 'c',
          'messageId': 'm',
          'recipientId': 'a',
        }),
      );
      messaging.foreground.add(
        PushMessage({
          'conversationId': 'c',
          'messageId': 'm',
          'recipientId': 'a',
        }),
      );
      messaging.foreground.add(
        PushMessage({
          'conversationId': 'c',
          'messageId': 'n',
          'recipientId': 'b',
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(received.length, 1);
      await sub.cancel();
    },
  );
  test('old local notification tap cannot route into a new account', () async {
    final received = <PushMessage>[];
    final sub = service.openedMessages.listen(received.add);
    await service.setSession('b');
    display.opened.add(
      PushMessage({'conversationId': 'c', '_01chatAccountId': 'a'}),
    );
    await Future<void>.delayed(Duration.zero);
    expect(received, isEmpty);
    await sub.cancel();
  });
  test(
    'background unverified recipient uses generic content and session-bound tap',
    () async {
      store.account = 'a';
      expect(
        await displayBackgroundPush(
          PushMessage({
            'type': 'message.new',
            'conversationId': 'c',
            'content': 'Private old text',
            'senderName': 'Private name',
          }),
          sessionStore: store,
          notifications: display,
        ),
        true,
      );
      expect(display.shown.single.body, 'Vous avez reçu un nouveau message.');
      expect(display.shown.single.title, '01 Chat');
      expect(display.shown.single.data['_01chatAccountId'], 'a');
    },
  );
  test(
    'background push drops after logout and for a different explicit recipient',
    () async {
      expect(
        await displayBackgroundPush(
          PushMessage({'type': 'message.new'}),
          sessionStore: store,
          notifications: display,
        ),
        false,
      );
      store.account = 'b';
      expect(
        await displayBackgroundPush(
          PushMessage({'type': 'message.new', 'recipientId': 'a'}),
          sessionStore: store,
          notifications: display,
        ),
        false,
      );
      expect(display.shown, isEmpty);
    },
  );
  test(
    'failed session restoration clears the durable background gate',
    () async {
      store.account = 'old-account';
      await service.setSession(null);
      expect(store.account, isNull);
      expect(api.calls, isEmpty);
      expect(messaging.tokens.hasListener, false);
    },
  );
  test('late initial callback after disposal cannot publish a route', () async {
    messaging.initial = Completer<PushMessage?>();
    final received = <PushMessage>[];
    final subscription = service.openedMessages.listen(received.add);
    await service.setSession('a');
    await service.dispose();
    messaging.initial!.complete(PushMessage({'conversationId': 'private'}));
    await Future<void>.delayed(Duration.zero);
    expect(received, isEmpty);
    await subscription.cancel();
  });
}
