import '../calls/support_call_host.dart' show supportCallBackgroundPush;
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'push_message.dart';
import 'push_session_store.dart';
import 'push_local_notifications.dart';
import 'push_read_receipts.dart';

/// Registered by bootstrap; no Riverpod, routes or widgets in the isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!(Platform.isAndroid || Platform.isIOS)) {
    return;
  }
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    await supportCallBackgroundPush(message.data);
    await displayBackgroundPush(
      PushMessage.fromRemote(message),
      sessionStore: SharedPreferencesPushSessionStore(),
      notifications: NativePushLocalNotifications(),
    );
  } catch (_) {
    /* Delivery may be disabled by the OS; never expose payloads. */
  }
}

/// Unknown recipients never expose private text from a delayed prior session.
Future<bool> displayBackgroundPush(
  PushMessage message, {
  required PushSessionStore sessionStore,
  required PushLocalNotifications notifications,
}) async {
  final account = await sessionStore.readAccount();
  if (account == null || account.isEmpty) {
    return false;
  }
  if (message.recipientId != null && message.recipientId != account) {
    return false;
  }
  final messageId = message.data['messageId']?.toString();
  if (await isReadPushMessage(account, messageId)) return false;
  final type = message.data['type']?.toString();
  if (type != 'message.new' && type != 'support.ticket.updated') {
    return false;
  }
  final verified = message.recipientId == account;
  final safe = verified
      ? message.forSession(account)
      : PushMessage(
          {
            for (final key in [
              'type',
              'conversationId',
              'messageId',
              'ticketId',
            ])
              if (message.data[key] != null) key: message.data[key],
            '_01chatAccountId': account,
          },
          id: message.id,
          notificationTitle: '01 Chat',
          notificationBody: 'Vous avez reçu un nouveau message.',
        );
  // Re-read immediately before display in case logout raced initialization.
  await notifications.initialize();
  if (await sessionStore.readAccount() != account) {
    return false;
  }
  await notifications.show(safe);
  // A read can race native display in the background isolate.
  if (await isReadPushMessage(account, messageId)) {
    await notifications.cancelMessages([messageId!]);
    return false;
  }
  return true;
}
