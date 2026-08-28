import 'package:fpdart/fpdart.dart';

import '../../../core/abstract/failure.dart';
import '../../entity/messaging/message_entity.dart';

/// Le fil d'une conversation.
abstract interface class MessageRepository {
  Future<Either<Failure, List<MessageEntity>>> fetchMessages(
    FetchMessagesParams params,
  );

  Future<Either<Failure, MessageEntity>> sendMessage(SendMessageParams params);

  Future<Either<Failure, Unit>> markRead(MarkReadParams params);
}

class FetchMessagesParams {
  const FetchMessagesParams({
    required this.conversationId,
    this.page = 1,
    this.limit = 50,
  });

  final String conversationId;
  final int page;
  final int limit;
}

class SendMessageParams {
  const SendMessageParams({
    required this.conversationId,
    required this.content,
    this.replyTo,
  });

  final String conversationId;
  final String content;

  /// Identifiant du message cité, le cas échéant.
  final String? replyTo;
}

class MarkReadParams {
  const MarkReadParams(this.conversationId);
  final String conversationId;
}
