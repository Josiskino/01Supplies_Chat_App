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
    ref
        .read(messageEventsProvider)
        .handleNotification(message.data, viaPush: true);
    requestSupportQueueRefresh(ref);
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
  const PushRoute({
    this.conversationId,
    this.ticketId,
    this.title = 'Conversation',
  });

  /// Thread to open. Direct and support message pushes both carry it.
  final String? conversationId;

  /// Support ticket, for payloads that only name the ticket
  /// (`support.ticket.updated`); resolved against the loaded inbox.
  final String? ticketId;
  final String title;

  static PushRoute? fromData(Map<String, dynamic> payload) {
    final data = PushMessage.normalize(payload);
    String? id(String key) {
      final value = data[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    final conversationId = id('conversationId');
    final ticketId = id('ticketId');
    if (conversationId == null && ticketId == null) {
      return null;
    }
    // The target endpoint still checks membership. A stale push never supplies
    // a client name as trusted screen metadata.
    return PushRoute(
      conversationId: conversationId,
      ticketId: ticketId,
      title: 'Conversation',
    );
  }
}
