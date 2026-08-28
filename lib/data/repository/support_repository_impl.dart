import 'package:fpdart/fpdart.dart';

import '../../core/abstract/base_repository.dart';
import '../../core/abstract/failure.dart';
import '../../domain/entity/messaging/conversation_entity.dart';
import '../../domain/entity/messaging/support_ticket_entity.dart';
import '../../domain/repository/messaging/support_repository.dart';
import '../datasources/abstract/messaging/support_datasource_contract.dart';
import '../models/messaging/conversation_model.dart';
import '../models/messaging/support_ticket_model.dart';

class SupportRepositoryImpl extends BaseRepository
    implements SupportRepository {
  SupportRepositoryImpl(this._remote);

  final SupportDataSourceContract _remote;

  @override
  Future<Either<Failure, List<SupportTicketEntity>>> fetchQueue(
    FetchQueueParams params,
  ) async {
    final result = await execute<List<SupportTicketModel>>(
      () => _remote.fetchQueue(
        status: params.status?.wireName,
        page: params.page,
        limit: params.limit,
      ),
    );

    return result.map((models) {
      final tickets = models.map((m) => m.toEntity()).toList();
      // Le plus récemment actif en tête : c'est l'ordre d'une messagerie, et
      // l'API rend la file dans son ordre de création.
      tickets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return tickets;
    });
  }

  @override
  Future<Either<Failure, List<ConversationEntity>>> fetchConversations() async {
    final result = await execute<List<ConversationModel>>(
      () => _remote.fetchConversations(),
    );
    return result.map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Either<Failure, ConversationEntity>> openDirectConversation(
    OpenDirectParams params,
  ) async {
    final result = await execute<ConversationModel>(
      () => _remote.createDirectConversation(params.userId),
    );
    return result.map((m) => m.toEntity());
  }

  @override
  Future<Either<Failure, Unit>> join(JoinTicketParams params) async {
    final result = await execute<bool>(
      () => _remote.joinTicket(
        ticketId: params.ticketId,
        agentId: params.agentId,
      ),
    );
    return result.map((_) => unit);
  }
}
