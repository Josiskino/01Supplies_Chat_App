import '../../../../core/utils/api_types.dart';
import '../../../models/messaging/message_model.dart';

/// Accès distant aux messages d'une conversation.
abstract interface class MessageDataSourceContract {
  Future<ApiResult<List<MessageModel>>> fetchMessages({
    required String conversationId,
    int page,
    int limit,
  });

  Future<ApiResult<MessageModel>> sendMessage({
    required String conversationId,
    required String content,
    String? replyTo,
  });

  /// Signale que le fil a été lu jusqu'au bout.
  Future<ApiResult<bool>> markRead(String conversationId);
}
