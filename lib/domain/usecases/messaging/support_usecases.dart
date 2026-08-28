import 'package:fpdart/fpdart.dart';

import '../../../core/abstract/failure.dart';
import '../../../core/abstract/usecase.dart';
import '../../entity/messaging/support_ticket_entity.dart';
import '../../repository/messaging/support_repository.dart';

/// Charge la file d'attente commune.
class FetchQueueUseCase
    implements UseCase<List<SupportTicketEntity>, FetchQueueParams> {
  const FetchQueueUseCase(this._repository);

  final SupportRepository _repository;

  @override
  Future<Either<Failure, List<SupportTicketEntity>>> call(
    FetchQueueParams params,
  ) => _repository.fetchQueue(params);
}

/// Se saisit d'un ticket de la file.
class ClaimTicketUseCase implements UseCase<Unit, ClaimTicketParams> {
  const ClaimTicketUseCase(this._repository);

  final SupportRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ClaimTicketParams params) =>
      _repository.claim(params);
}
