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
