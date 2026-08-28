import 'package:fpdart/fpdart.dart';

import '../../core/abstract/base_repository.dart';
import '../../core/abstract/failure.dart';
import '../../domain/entity/messaging/message_entity.dart';
import '../../domain/repository/messaging/message_repository.dart';
import '../datasources/abstract/messaging/message_datasource_contract.dart';
import '../models/messaging/message_model.dart';

class MessageRepositoryImpl extends BaseRepository
    implements MessageRepository {
  MessageRepositoryImpl(this._remote);

  final MessageDataSourceContract _remote;

  @override
  Future<Either<Failure, List<MessageEntity>>> fetchMessages(
    FetchMessagesParams params,
  ) async {
    final result = await execute<List<MessageModel>>(
      () => _remote.fetchMessages(
        conversationId: params.conversationId,
        page: params.page,
        limit: params.limit,
      ),
    );

    return result.map((models) {
      final messages = models.map((m) => m.toEntity()).toList();
      // Du plus ancien au plus récent : c'est l'ordre de lecture d'un fil, et
      // l'API rend les messages du plus récent au plus ancien pour paginer.
      messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return messages;
    });
  }

  @override
  Future<Either<Failure, MessageEntity>> sendMessage(
    SendMessageParams params,
  ) async {
    final result = await execute<MessageModel>(
      () => _remote.sendMessage(
        conversationId: params.conversationId,
        content: params.content,
        replyTo: params.replyTo,
        type: params.type.wireName,
        attachmentMediaIds: params.attachmentMediaIds,
      ),
    );
    return result.map((m) => m.toEntity());
  }

  @override
  Future<Either<Failure, Unit>> markRead(MarkReadParams params) async {
    final result = await execute<bool>(
      () => _remote.markRead(params.conversationId),
    );
    return result.map((_) => unit);
  }
}
