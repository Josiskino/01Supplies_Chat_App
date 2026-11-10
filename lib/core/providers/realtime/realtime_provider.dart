import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/message_events_service.dart';

part 'realtime_provider.g.dart';

/// Le pont temps réel, vivant tant que l'application tourne.
///
/// `keepAlive` : le service s'abonne au canal de l'utilisateur dès la connexion
/// et doit y rester même quand aucun écran ne l'observe — c'est ce qui fait
/// entrer une nouvelle demande dans la file pendant qu'on regarde un autre
/// onglet.
@Riverpod(keepAlive: true)
MessageEventsService messageEvents(Ref ref) {
  final service = MessageEventsService(ref);
  ref.onDispose(service.dispose);
  return service;
}

/// Conversation actuellement à l'écran, s'il y en a une.
///
/// Provider distinct du service temps réel : l'écran de fil n'a qu'à déclarer
/// ce qu'il affiche, sans instancier la mécanique Pusher — ce qui la ferait
/// démarrer jusque dans les tests d'interface.
@Riverpod(keepAlive: true)
class VisibleConversation extends _$VisibleConversation {
  @override
  String? build() => null;

  void set(String? conversationId) => state = conversationId;
}

/// Flux des messages reçus hors du fil affiché.
///
/// Exposé en provider pour que l'écouteur d'interface s'y abonne sans connaître
/// le service, et que le lien se défasse avec l'arbre de widgets.
@riverpod
Stream<IncomingMessage> incomingMessage(Ref ref) =>
    ref.watch(messageEventsProvider).incomingMessages;

/// Participants currently typing in this conversation, expired by the service.
@riverpod
Stream<Map<String, String>> typingUsers(Ref ref, String conversationId) {
  final service = ref.watch(messageEventsProvider);
  return Stream.multi((controller) {
    controller.add(service.typingSnapshot(conversationId));
    final subscription = service.typingChanges.listen((event) {
      if (event.conversationId == conversationId) controller.add(event.users);
    }, onError: controller.addError);
    controller.onCancel = subscription.cancel;
  });
}

/// Members with this conversation open; this is not global online presence.
@riverpod
Stream<Map<String, Map<String, dynamic>>> conversationPresence(
  Ref ref,
  String conversationId,
) {
  final service = ref.watch(messageEventsProvider);
  return Stream.multi((controller) {
    controller.add(service.presenceSnapshot(conversationId));
    final subscription = service.presenceChanges.listen((event) {
      if (event.conversationId == conversationId) controller.add(event.members);
    }, onError: controller.addError);
    controller.onCancel = subscription.cancel;
  });
}
