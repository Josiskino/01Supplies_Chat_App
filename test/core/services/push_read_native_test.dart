import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/services/push_local_notifications.dart';
import 'package:supplies_chat_app/core/services/push_message.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'native cancellation uses the exact displayed IDs and never cancelAll',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return call.method == 'initialize' ? true : null;
          });
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
      final notifications = NativePushLocalNotifications();
      await notifications.show(
        PushMessage({'messageId': 'read', 'type': 'message.new'}),
      );
      await notifications.cancelMessages(['read', 'read']);
      final shown = calls.singleWhere((call) => call.method == 'show');
      final cancelled = calls.singleWhere((call) => call.method == 'cancel');
      expect(
        (cancelled.arguments as Map)['id'],
        (shown.arguments as Map)['id'],
      );
      expect(calls.any((call) => call.method == 'cancelAll'), isFalse);
      await notifications.dispose();
    },
  );
}
