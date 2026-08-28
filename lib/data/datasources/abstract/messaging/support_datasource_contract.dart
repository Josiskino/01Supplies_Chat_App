import '../../../../core/utils/api_types.dart';
import '../../../models/messaging/support_ticket_model.dart';

/// Accès distant à la file d'attente du support.
abstract interface class SupportDataSourceContract {
  /// Tous les tickets de la plateforme, la file commune aux admins.
  Future<ApiResult<List<SupportTicketModel>>> fetchQueue({
    String? status,
    int page,
    int limit,
  });

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
