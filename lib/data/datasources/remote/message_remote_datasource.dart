import '../../../core/abstract/api_client_interface.dart';
import '../../../core/constants/api_endpoints_urls.dart';
import '../../../core/utils/api_types.dart';
import '../../models/messaging/message_model.dart';
import '../abstract/messaging/message_datasource_contract.dart';

class MessageRemoteDataSource implements MessageDataSourceContract {
  const MessageRemoteDataSource(this._client);

  final ApiClientInterface _client;

  @override
  Future<ApiResult<List<MessageModel>>> fetchMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
  }) {
    return _client.request<List<MessageModel>>(
      path: ApiEndpoints.messagesOfConversation(conversationId),
      method: HttpMethod.get,
      queryParameters: {'page': page, 'limit': limit},
      dataKey: 'data',
      // `ApiResponseHandler` réenveloppe les listes sous `data` : cf. le même
      // motif dans la source du support.
      fromJson: (json) => (json['data'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => MessageModel.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  @override
  Future<ApiResult<MessageModel>> sendMessage({
    required String conversationId,
    required String content,
    String? replyTo,
    String type = 'text',
    List<String> attachmentMediaIds = const [],
  }) {
    return _client.request<MessageModel>(
      path: ApiEndpoints.messages,
      method: HttpMethod.post,
      data: {
        'conversationId': conversationId,
        'content': content,
        'type': type,
        'replyTo': ?replyTo,
        // Les identifiants de média, pas les URL : c'est ce lien qui empêche le
        // serveur de considérer le fichier comme orphelin et de l'effacer.
        if (attachmentMediaIds.isNotEmpty)
          'attachmentMediaIds': attachmentMediaIds,
      },
      dataKey: 'data',
      fromJson: (json) => MessageModel.fromJson(json),
    );
  }

  @override
  Future<ApiResult<bool>> markRead(String conversationId) {
    return _client.request<bool>(
      path: ApiEndpoints.markRead(conversationId),
      method: HttpMethod.post,
      fromJson: (_) => true,
    );
  }
}
