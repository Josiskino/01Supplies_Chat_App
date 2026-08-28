import 'package:fpdart/fpdart.dart';

import '../../../core/abstract/failure.dart';
import '../../../core/abstract/usecase.dart';
import '../../entity/messaging/message_entity.dart';
import '../../repository/messaging/message_repository.dart';

class FetchMessagesUseCase
    implements UseCase<List<MessageEntity>, FetchMessagesParams> {
  const FetchMessagesUseCase(this._repository);
  final MessageRepository _repository;

  @override
  Future<Either<Failure, List<MessageEntity>>> call(
    FetchMessagesParams params,
  ) => _repository.fetchMessages(params);
}

class SendMessageUseCase implements UseCase<MessageEntity, SendMessageParams> {
  const SendMessageUseCase(this._repository);
  final MessageRepository _repository;

  @override
  Future<Either<Failure, MessageEntity>> call(SendMessageParams params) =>
      _repository.sendMessage(params);
}

class MarkReadUseCase implements UseCase<Unit, MarkReadParams> {
  const MarkReadUseCase(this._repository);
  final MessageRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(MarkReadParams params) =>
      _repository.markRead(params);
}
