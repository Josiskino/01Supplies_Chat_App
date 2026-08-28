import 'package:fpdart/fpdart.dart';

import '../../../core/abstract/failure.dart';
import '../../entity/messaging/support_ticket_entity.dart';

/// La file d'attente du support, vue du domaine.
abstract interface class SupportRepository {
  Future<Either<Failure, List<SupportTicketEntity>>> fetchQueue(
    FetchQueueParams params,
  );

  Future<Either<Failure, Unit>> claim(ClaimTicketParams params);
}

class FetchQueueParams {
  const FetchQueueParams({this.status, this.page = 1, this.limit = 50});

  /// Filtre d'avancement. Nul, la file entière est renvoyée.
  final TicketStatus? status;
  final int page;
  final int limit;
}

class ClaimTicketParams {
  const ClaimTicketParams(this.ticketId);
  final String ticketId;
}
