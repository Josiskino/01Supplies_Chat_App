import 'package:go_router/go_router.dart';

import '../../../core/constants/app_ui_route.dart';
import '../../../core/providers/realtime/push_provider.dart';
import '../../../domain/entity/messaging/conversation_list_entry.dart';

/// Location currently shown by [router], or an empty string before the
/// first route is resolved.
String currentRouterLocation(GoRouter router) {
  final configuration = router.routerDelegate.currentConfiguration;
  return configuration.isEmpty ? '' : configuration.last.matchedLocation;
}

/// Whether a thread opened from a notification can be pushed now.
///
/// On a cold start the router sits on the splash until the session is
/// restored and the splash animation ends, then the redirect *replaces* the
/// stack with the main shell. A thread pushed before that is either dropped
/// or left above the splash, so the push waits for a real screen.
bool canOpenPushedConversation(String location) =>
    location.isNotEmpty &&
    location != AppUiRoute.splash &&
    location != AppUiRoute.login;

/// Thread targeted by [route], or `null` when it cannot be determined.
///
/// Message pushes (direct and support) name the conversation. A payload that
/// only names a support ticket is resolved against the loaded inbox.
String? resolvePushConversationId(
  PushRoute route,
  Iterable<ConversationListEntry> inbox,
) {
  final conversationId = route.conversationId;
  if (conversationId != null) return conversationId;
  final ticketId = route.ticketId;
  if (ticketId == null) return null;
  for (final entry in inbox) {
    if (entry.ticketId == ticketId) return entry.conversationId;
  }
  return null;
}
