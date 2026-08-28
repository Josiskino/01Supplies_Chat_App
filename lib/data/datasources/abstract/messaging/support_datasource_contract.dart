import '../../../../core/utils/api_types.dart';
import '../../../models/messaging/conversation_model.dart';
import '../../../models/messaging/support_ticket_model.dart';

/// Accès distant à la file d'attente du support.
abstract interface class SupportDataSourceContract {
  /// Tous les tickets de la plateforme, la file commune aux admins.
  Future<ApiResult<List<SupportTicketModel>>> fetchQueue({
    String? status,
    int page,
    int limit,
  });

  /// Les conversations dont l'utilisateur est participant.
  ///
  /// Seule source du **dernier message** et du compteur de non-lus : le ticket
  /// ne connaît que la demande d'origine, et son `description` reste figée à
  /// l'ouverture du dossier.
  Future<ApiResult<List<ConversationModel>>> fetchConversations({
    int page,
    int limit,
  });

  /// Ouvre une conversation directe avec un interlocuteur.
  ///
  /// L'API déduplique les conversations `direct` : rappeler cette méthode pour
  /// le même contact renvoie la conversation existante au lieu d'en créer une
  /// seconde, ce qui éviterait sinon deux fils parallèles pour une même
  /// personne.
  Future<ApiResult<ConversationModel>> createDirectConversation(String userId);

  /// Rejoint un ticket en s'y déclarant agent.
  ///
  /// Passe par `assign` et non `claim` : `claim` répond 409 sur un dossier déjà
  /// pris, alors que l'équipe travaille à plusieurs sur une même demande —
  /// `assign` ajoute l'agent aux participants sans évincer les précédents.
  Future<ApiResult<bool>> joinTicket({
    required String ticketId,
    required String agentId,
  });
}
