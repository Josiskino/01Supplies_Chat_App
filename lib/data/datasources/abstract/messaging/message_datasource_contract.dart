import '../../../../core/utils/api_types.dart';
import '../../../models/messaging/message_model.dart';

/// Accès distant aux messages d'une conversation.
abstract interface class MessageDataSourceContract {
  Future<ApiResult<List<MessageModel>>> fetchMessages({
    required String conversationId,
    int page,
    int limit,
    String? before,
  });

  Future<ApiResult<MessageModel>> sendMessage({
    required String conversationId,
    required String content,
    String? replyTo,
    String type,
    List<String> attachmentMediaIds,
  });

  /// Signale que le fil a été lu jusqu'au bout.
  Future<ApiResult<bool>> markRead(
    String conversationId, {
    List<String>? messageIds,
  });
  Future<ApiResult<bool>> markDelivered(
    String conversationId, {
    required List<String> messageIds,
  });
  Future<ApiResult<bool>> react(String messageId, String emoji);
  Future<ApiResult<bool>> edit(String messageId, String content);
  Future<ApiResult<bool>> delete(String messageId);
}
