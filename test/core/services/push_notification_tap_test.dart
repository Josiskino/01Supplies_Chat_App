import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supplies_chat_app/core/providers/realtime/push_provider.dart';
import 'package:supplies_chat_app/core/services/push_background_handler.dart';
import 'package:supplies_chat_app/core/services/push_local_notifications.dart';
import 'package:supplies_chat_app/core/services/push_message.dart';
import 'package:supplies_chat_app/core/services/push_notification_service.dart';

import 'push_notification_service_test.dart'
    show FakeApi, FakeDisplay, FakeMessaging, MemoryStore;

const _channel = MethodChannel('dexterous.com/flutter/local_notifications');

/// Delivers a native "notification tapped" call to the Dart plugin.
Future<void> _nativeTap(String payload) async {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  await messenger.handlePlatformMessage(
    _channel.name,
    const StandardMethodCodec().encodeMethodCall(
      MethodCall('didReceiveNotificationResponse', {
        'notificationId': 1,
        'payload': payload,
        'notificationResponseType': 0,
      }),
    ),
    (_) {},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushRoute.fromData', () {
    test('direct conversation message', () {
      final route = PushRoute.fromData({
        'type': 'message.new',
        'conversationType': 'direct',
        'conversationId': 'conv-1',
        'messageId': 'm1',
      })!;
      expect(route.conversationId, 'conv-1');
      expect(route.ticketId, isNull);
    });

    test('support ticket message keeps both ids', () {
      final route = PushRoute.fromData({
        'type': 'message.new',
        'conversationType': 'support',
        'conversationId': 'conv-2',
        'ticketId': 'ticket-2',
      })!;
      expect(route.conversationId, 'conv-2');
      expect(route.ticketId, 'ticket-2');
    });

    test('ticket-only update is kept for inbox resolution', () {
      final route = PushRoute.fromData({
        'type': 'support.ticket.updated',
        'ticketId': 'ticket-3',
        'status': 'resolved',
      })!;
      expect(route.conversationId, isNull);
      expect(route.ticketId, 'ticket-3');
    });

    test('nested JSON data payload (local notification) is read', () {
      final route = PushRoute.fromData({
        'data': '{"conversationId":"conv-4"}',
      })!;
      expect(route.conversationId, 'conv-4');
    });

    test('missing or blank ids give no route', () {
      expect(PushRoute.fromData({'type': 'message.new'}), isNull);
      expect(
        PushRoute.fromData({'conversationId': '', 'ticketId': '  '}),
        isNull,
      );
    });
  });

  group('iOS local notification taps', () {
    final calls = <MethodCall>[];
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      calls.clear();
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      IOSFlutterLocalNotificationsPlugin.registerWith();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
            calls.add(call);
            return call.method == 'initialize' ? true : null;
          });
    });
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
    });

    test(
      'the background handler instance cannot steal the app tap callback',
      () async {
        // App instance, listened to by the push service.
        final app = NativePushLocalNotifications();
        await app.initialize();
        final opened = <PushMessage>[];
        final sub = app.openedMessages.listen(opened.add);

        // On iOS the Firebase background handler runs in this same isolate
        // and initializes a second instance to display the data-only push.
        final background = NativePushLocalNotifications();
        await displayBackgroundPush(
          PushMessage({
            'type': 'message.new',
            'conversationId': 'conv-9',
            'messageId': 'm9',
          }),
          sessionStore: MemoryStore()..account = 'agent',
          notifications: background,
        );
        expect(
          calls.where((call) => call.method == 'initialize'),
          hasLength(2),
        );
        final shown = calls.singleWhere((call) => call.method == 'show');

        await _nativeTap((shown.arguments as Map)['payload'] as String);
        await Future<void>.delayed(Duration.zero);

        expect(opened, hasLength(1));
        expect(opened.single.data['conversationId'], 'conv-9');
        expect(opened.single.recipientId, 'agent');
        await sub.cancel();
        await app.dispose();
        await background.dispose();
      },
    );

    test('a disposed instance stops publishing taps', () async {
      final local = NativePushLocalNotifications();
      await local.initialize();
      final opened = <PushMessage>[];
      final sub = local.openedMessages.listen(opened.add);
      await local.dispose();
      await _nativeTap('{"conversationId":"conv-1"}');
      await Future<void>.delayed(Duration.zero);
      expect(opened, isEmpty);
      await sub.cancel();
    });
  });

  test(
    'foreground-shown local notification tap reaches the opened stream',
    () async {
      SharedPreferences.setMockInitialValues({});
      final display = FakeDisplay();
      final service = PushNotificationService(
        FakeApi(),
        messaging: FakeMessaging(),
        sessionStore: MemoryStore(),
        localNotifications: display,
        supported: true,
        platform: 'ios',
      );
      final received = <PushMessage>[];
      final sub = service.openedMessages.listen(received.add);
      await service.setSession('agent');
      display.opened.add(
        PushMessage({
          'type': 'message.new',
          'conversationId': 'conv-5',
          'messageId': 'm5',
          '_01chatAccountId': 'agent',
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(1));
      expect(
        PushRoute.fromData(received.single.data)?.conversationId,
        'conv-5',
      );
      await sub.cancel();
      await service.dispose();
    },
  );
}
