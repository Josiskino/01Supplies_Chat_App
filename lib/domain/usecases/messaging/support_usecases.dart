import 'package:fpdart/fpdart.dart';

import '../../../core/abstract/failure.dart';
import '../../../core/abstract/usecase.dart';
import '../../entity/messaging/conversation_entity.dart';
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

/// Charge les conversations dont on est participant.
class FetchConversationsUseCase
    implements UseCase<List<ConversationEntity>, FetchConversationsParams> {
  const FetchConversationsUseCase(this._repository);

  final SupportRepository _repository;

  @override
  Future<Either<Failure, List<ConversationEntity>>> call(
    FetchConversationsParams params,
  ) => _repository.fetchConversations();
}

class FetchConversationsParams {
  const FetchConversationsParams();
}

/// Rejoint un ticket de la file, seul ou aux côtés d'autres agents.
class JoinTicketUseCase implements UseCase<Unit, JoinTicketParams> {
  const JoinTicketUseCase(this._repository);

  final SupportRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(JoinTicketParams params) =>
      _repository.join(params);
}
