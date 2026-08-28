import 'package:fpdart/fpdart.dart';

import '../../../core/abstract/failure.dart';
import '../../entity/messaging/conversation_entity.dart';
import '../../entity/messaging/support_ticket_entity.dart';

/// La file d'attente du support, vue du domaine.
abstract interface class SupportRepository {
  Future<Either<Failure, List<SupportTicketEntity>>> fetchQueue(
    FetchQueueParams params,
  );

  Future<Either<Failure, List<ConversationEntity>>> fetchConversations();

  Future<Either<Failure, Unit>> join(JoinTicketParams params);
}

class FetchQueueParams {
  const FetchQueueParams({this.status, this.page = 1, this.limit = 50});

  /// Filtre d'avancement. Nul, la file entière est renvoyée.
  final TicketStatus? status;
  final int page;
  final int limit;
}

class JoinTicketParams {
  const JoinTicketParams({required this.ticketId, required this.agentId});

  final String ticketId;

  /// L'agent qui rejoint — soi-même dans tous les cas d'usage actuels.
  final String agentId;
}
