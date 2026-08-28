import 'package:fpdart/fpdart.dart';

import '../../core/abstract/base_repository.dart';
import '../../core/abstract/failure.dart';
import '../../domain/entity/messaging/support_ticket_entity.dart';
import '../../domain/repository/messaging/support_repository.dart';
import '../datasources/abstract/messaging/support_datasource_contract.dart';
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
