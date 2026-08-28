import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../core/constants/app_ui_route.dart';
import '../../../core/providers/realtime/realtime_provider.dart';
import '../../../core/services/message_events_service.dart';

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

    return widget.child;
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
            onPressed: () => context.push(
              AppUiRoute.conversationDetailPath(message.conversationId),
              extra: {'contactName': message.author},
            ),
          ),
        ),
      );
  }
}
