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
  /// Complète les conversations embarquées dans les tickets et apporte les
  /// conversations directes. Les listes sont paginées jusqu'à leur dernière
  /// page pour produire une vue complète avant fusion.
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

  /// Prend le dossier au nom de la session authentifiée via `/claim`.
  /// Une prise remplace l'ancien agent. [agentId] reste uniquement pour la
  /// compatibilité des appelants : il n'est jamais envoyé au serveur.
  Future<ApiResult<bool>> joinTicket({
    required String ticketId,
    required String agentId,
  });
}
