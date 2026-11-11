import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supplies_chat_app/core/abstract/api_client_interface.dart';
import 'package:supplies_chat_app/core/utils/api_types.dart';
import 'package:supplies_chat_app/core/services/push_notification_service.dart';
import 'package:supplies_chat_app/core/services/push_device_identity.dart';
import 'package:supplies_chat_app/core/services/push_read_receipts.dart';
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
  final cancelledMessages = <String>[];
  Future<void> Function()? onShow;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> show(PushMessage message) async {
    shown.add(message);
    await onShow?.call();
  }

  @override
  Future<void> cancelAll() async {
    cancellations++;
  }

  @override
  Future<void> cancelMessages(Iterable<String> ids) async {
    cancelledMessages.addAll(ids);
    shown.removeWhere((message) => ids.contains(message.data['messageId']));
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
  int registrationFailures = 0;
  final registered = Completer<void>();
  Map<String, dynamic>? lastRegistration;
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
    if (method == HttpMethod.post && registrationFailures > 0) {
      registrationFailures--;
      return ApiError<T>(message: 'Temporarily unavailable', statusCode: 503);
    }
    if (method == HttpMethod.post && !registered.isCompleted) {
      registered.complete();
    }
    if (method == HttpMethod.post) {
      lastRegistration = Map<String, dynamic>.from(data as Map);
    }
    return ApiSuccess(
      data: fromJson(
        method == HttpMethod.get
            ? {
                'data': {
                  'devices': [
                    {
                      'deviceId': lastRegistration?['deviceId'],
                      'platform': lastRegistration?['platform'],
                    },
                  ],
                },
              }
            : {},
      ),
      statusCode: 200,
    );
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
    SharedPreferences.setMockInitialValues({});
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
  test(
    'registration includes stable installation ID and verifies the active device',
    () async {
      await service.setSession('a');
      final firstId = api.lastRegistration?['deviceId'];
      expect(firstId, isA<String>());
      expect(firstId, startsWith('01chat-'));
      expect(
        api.calls.any((call) => call.startsWith('get:users/me/devices:')),
        isTrue,
      );
      messaging.tokens.add('rotated-token');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(api.lastRegistration?['deviceId'], firstId);
      expect(api.lastRegistration?['fcmToken'], 'rotated-token');
    },
  );
  test('installation identity survives a new service instance', () async {
    final first = await PushDeviceIdentity().getDeviceId();
    final second = await PushDeviceIdentity().getDeviceId();
    expect(second, first);
    expect(first.length, lessThanOrEqualTo(128));
  });
  test(
    'reading removes only matching notifications and suppresses delayed push',
    () async {
      await service.setSession('a');
      display.shown.addAll([
        PushMessage({
          'type': 'message.new',
          'messageId': 'read',
          'conversationId': 'c',
        }),
        PushMessage({
          'type': 'message.new',
          'messageId': 'new',
          'conversationId': 'c',
        }),
        PushMessage({
          'type': 'message.new',
          'messageId': 'other',
          'conversationId': 'other',
        }),
      ]);
      await service.markMessagesRead(['read']);
      expect(display.cancelledMessages, ['read']);
      expect(display.shown.map((message) => message.data['messageId']), [
        'new',
        'other',
      ]);
      expect(display.cancellations, 0);
      expect(await isReadPushMessage('a', 'read'), isTrue);
      expect(await isReadPushMessage('b', 'read'), isFalse);
      expect(
        await displayBackgroundPush(
          PushMessage({'type': 'message.new', 'messageId': 'read'}),
          sessionStore: store,
          notifications: display,
        ),
        isFalse,
      );
      expect(display.shown, hasLength(2));
    },
  );
  test(
    'read racing background display cancels the just-created notification',
    () async {
      store.account = 'a';
      display.onShow = () => rememberReadPushMessages('a', ['late']);
      final displayed = await displayBackgroundPush(
        PushMessage({
          'type': 'message.new',
          'messageId': 'late',
          'conversationId': 'c',
        }),
        sessionStore: store,
        notifications: display,
      );
      expect(displayed, isFalse);
      expect(display.shown, isEmpty);
      expect(display.cancelledMessages, ['late']);
    },
  );
  test(
    'temporary registration failure retries without another login',
    () async {
      await service.dispose();
      api.registrationFailures = 1;
      service = PushNotificationService(
        api,
        messaging: messaging,
        sessionStore: store,
        localNotifications: display,
        supported: true,
        registrationRetryDelay: const Duration(milliseconds: 1),
      );
      await service.setSession('support-agent');
      await api.registered.future.timeout(const Duration(seconds: 2));
      expect(api.calls.where((call) => call.startsWith('post:')), hasLength(2));
    },
  );

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
