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

  /// Se saisit d'un ticket, qui rejoint alors ses conversations.
  Future<ApiResult<bool>> claim(String ticketId);
}
