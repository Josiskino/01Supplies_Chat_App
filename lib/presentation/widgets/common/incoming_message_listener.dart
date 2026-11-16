import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/app_router.dart';
import '../../../config/theme/design_tokens.dart';
import '../../../core/constants/app_ui_route.dart';
import '../../../core/providers/messaging/support_provider.dart';
import '../../../core/providers/realtime/push_provider.dart';
import '../../../core/providers/realtime/realtime_provider.dart';
import '../../../core/services/message_events_service.dart';
import '../../../core/utils/app_logger.dart';
import 'push_navigation.dart';

/// Provides message banners for both Material and Cupertino application roots.
class MessagingApplicationLayer extends StatelessWidget {
  const MessagingApplicationLayer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ScaffoldMessenger(child: IncomingMessageListener(child: child));
}

/// Signale les messages arrivés hors du fil affiché.
///
/// ## Portée
///
/// C'est une notification **dans l'application**, pas une notification système :
/// elle ne se voit que si 01 Chat est au premier plan. Alerter un appareil
/// verrouillé demande APNs et FCM, que le socle n'embarque pas — et FCM ne
/// couvre de toute façon pas Windows.
///
/// Monté à la racine et non dans un écran : un message peut arriver pendant
/// qu'on consulte les réglages, et c'est justement là qu'il faut le signaler.
class IncomingMessageListener extends ConsumerStatefulWidget {
  const IncomingMessageListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IncomingMessageListener> createState() =>
      _IncomingMessageListenerState();
}

class _IncomingMessageListenerState
    extends ConsumerState<IncomingMessageListener> {
  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<IncomingMessage>>(incomingMessageProvider, (_, next) {
      final message = next.value;
      if (message == null || !mounted) return;
      _show(message);
    });

    // Tapping a system notification opens its conversation.
    ref.listen<AsyncValue<PushRoute>>(pushRouteProvider, (_, next) {
      final route = next.value;
      if (route == null || !mounted) return;
      _pendingPush = route;
      _openPendingPush();
    });

    return widget.child;
  }

  /// Latest tapped notification not yet opened. Only the last tap matters.
  PushRoute? _pendingPush;
  GoRouter? _waitingRouter;

  @override
  void dispose() {
    _stopWaiting();
    super.dispose();
  }

  void _stopWaiting() {
    _waitingRouter?.routerDelegate.removeListener(_onRouteChanged);
    _waitingRouter = null;
  }

  // Never navigate from inside the delegate's own notification.
  void _onRouteChanged() => scheduleMicrotask(_openPendingPush);

  void _openPendingPush() {
    final route = _pendingPush;
    if (route == null || !mounted) return;
    final router = ref.read(appRouterProvider);
    if (!canOpenPushedConversation(currentRouterLocation(router))) {
      // Cold start: the session or the splash is not done yet. Retry on the
      // next route change (splash -> main).
      if (_waitingRouter != router) {
        _stopWaiting();
        _waitingRouter = router..routerDelegate.addListener(_onRouteChanged);
      }
      return;
    }
    _pendingPush = null;
    _stopWaiting();

    final inbox = ref.exists(supportQueueProvider)
        ? ref.read(supportQueueProvider).value
        : null;
    final conversationId = resolvePushConversationId(route, inbox ?? const []);
    if (conversationId == null) {
      AppLogger().warning(
        'Opened notification names no reachable conversation',
        feature: 'Push',
      );
      return;
    }
    // A thread missing from the loaded inbox (new direct conversation, ticket
    // created since the last fetch) still opens: the screen loads it by id.
    // The refresh fills its header and role once the inbox knows it.
    if (inbox != null &&
        !inbox.any((e) => e.conversationId == conversationId)) {
      ref.read(supportQueueProvider.notifier).requestRefresh();
    }
    final path = AppUiRoute.conversationDetailPath(conversationId);
    if (currentRouterLocation(router) == path) return;
    unawaited(router.push(path, extra: {'contactName': route.title}));
  }

  void _show(IncomingMessage message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(DesignTokens.spaceM),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusM,
          ),
          duration: const Duration(seconds: 4),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.author,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (message.preview.isNotEmpty)
                Text(
                  message.preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          action: SnackBarAction(
            label: 'Ouvrir',
            onPressed: () => ref
                .read(appRouterProvider)
                .push(
                  AppUiRoute.conversationDetailPath(message.conversationId),
                  extra: {'contactName': message.author},
                ),
          ),
        ),
      );
  }
}
