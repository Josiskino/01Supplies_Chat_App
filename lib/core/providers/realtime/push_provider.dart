import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../auth/auth_gate.dart';
import '../../services/push_notification_service.dart';
import '../../services/push_message.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_status_provider.dart';
import '../messaging/support_provider.dart';
import '../request/api_provider.dart';
import 'realtime_provider.dart';

part 'push_provider.g.dart';

@Riverpod(keepAlive: true)
PushNotificationService pushNotifications(Ref ref) {
  final service = PushNotificationService(ref.watch(apiClientProvider));
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
}

@Riverpod(keepAlive: true)
void pushRegistration(Ref ref) {
  final service = ref.watch(pushNotificationsProvider);
  void syncSession() {
    final status = ref.read(authStatusProvider);
    if (status == AuthGateStatus.initial || status == AuthGateStatus.loading) {
      return;
    }
    final account = status == AuthGateStatus.authenticated
        ? ref.read(currentUserProvider)?.id
        : null;
    unawaited(service.setSession(account));
  }

  ref.listen(
    authStatusProvider,
    (_, _) => syncSession(),
    fireImmediately: true,
  );
  ref.listen(currentUserProvider, (_, _) => syncSession());
  final subscription = service.foregroundMessages.listen((message) {
    if (!ref.mounted ||
        ref.read(authStatusProvider) != AuthGateStatus.authenticated ||
        message.recipientId != ref.read(currentUserProvider)?.id) {
      return;
    }
    // The shared dispatcher deduplicates FCM and Pusher, including observers
    // who do not yet have access to the private conversation channel.
    ref.read(messageEventsProvider).handleNotification(message.data);
    ref.invalidate(supportQueueProvider);
  });
  ref.onDispose(() => unawaited(subscription.cancel()));
}

/// Routes only messages accepted by the active account's push session.
@Riverpod(keepAlive: true)
Stream<PushRoute> pushRoute(Ref ref) {
  final service = ref.watch(pushNotificationsProvider);
  return service.openedMessages
      .where(
        (message) =>
            ref.mounted &&
            ref.read(authStatusProvider) == AuthGateStatus.authenticated &&
            message.recipientId == ref.read(currentUserProvider)?.id,
      )
      .map((message) => PushRoute.fromData(message.data))
      .where((route) => route != null)
      .cast<PushRoute>();
}

class PushRoute {
  const PushRoute({required this.conversationId, required this.title});
  final String conversationId;
  final String title;
  static PushRoute? fromData(Map<String, dynamic> payload) {
    final data = PushMessage.normalize(payload);
    final id = data['conversationId']?.toString();
    if (id == null || id.isEmpty) {
      return null;
    }
    // The target endpoint still checks membership. A stale push never supplies
    // a client name as trusted screen metadata.
    return PushRoute(conversationId: id, title: 'Conversation');
  }
}
