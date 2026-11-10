import '../../../core/abstract/api_client_interface.dart';
import '../../../core/constants/api_endpoints_urls.dart';
import '../../../core/utils/api_types.dart';
import '../../models/messaging/conversation_model.dart';
import '../../models/messaging/support_ticket_model.dart';
import '../abstract/messaging/support_datasource_contract.dart';

class SupportRemoteDataSource implements SupportDataSourceContract {
  const SupportRemoteDataSource(this._client);

  final ApiClientInterface _client;

  @override
  Future<ApiResult<List<SupportTicketModel>>> fetchQueue({
    String? status,
    int page = 1,
    int limit = 50,
  }) {
    return _fetchPages<SupportTicketModel>(
      path: ApiEndpoints.supportQueue,
      page: page,
      limit: limit,
      filters: {'status': ?status},
      parse: SupportTicketModel.fromJson,
      idOf: (ticket) => ticket.id,
    );
  }

  @override
  Future<ApiResult<List<ConversationModel>>> fetchConversations({
    int page = 1,
    int limit = 50,
  }) => _fetchPages<ConversationModel>(
    path: ApiEndpoints.conversations,
    page: page,
    limit: limit,
    parse: ConversationModel.fromJson,
    idOf: (conversation) => conversation.id,
  );

  /// Complete snapshots are needed before merging independently paginated
  /// sources. A failed or non-progressing page must never look complete.
  Future<ApiResult<List<T>>> _fetchPages<T>({
    required String path,
    required int page,
    required int limit,
    required T Function(Map<String, dynamic>) parse,
    required String Function(T) idOf,
    Map<String, dynamic> filters = const {},
  }) async {
    if (page < 1 || limit < 1) {
      return const ApiError(message: 'Pagination invalide.');
    }
    final items = <String, T>{};
    var nextPage = page;
    while (true) {
      final result = await _client.request<List<T>>(
        path: path,
        method: HttpMethod.get,
        queryParameters: {...filters, 'page': nextPage, 'limit': limit},
        dataKey: 'data',
        metadataConfigs: const [MetadataConfig('meta')],
        fromJson: (json) => (json['data'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => parse(item.cast<String, dynamic>()))
            .toList(),
      );
      if (result is ApiError<List<T>>) return result;
      final success = result as ApiSuccess<List<T>>;
      final before = items.length;
      for (final item in success.data) {
        final id = idOf(item);
        if (id.isEmpty) {
          return const ApiError(message: 'Réponse de pagination invalide.');
        }
        items[id] = item;
      }
      final meta = success.metadata['meta'];
      final totalPages = meta is Map
          ? (meta['totalPages'] as num?)?.toInt()
          : null;
      final finished = totalPages != null
          ? nextPage >= totalPages
          : success.data.length < limit;
      if (finished) {
        return ApiSuccess(
          data: items.values.toList(),
          statusCode: success.statusCode,
        );
      }
      if (items.length == before || nextPage - page >= 1000) {
        return const ApiError(message: 'Chargement incomplet. Réessayez.');
      }
      nextPage++;
    }
  }

  @override
  Future<ApiResult<ConversationModel>> createDirectConversation(String userId) {
    return _client.request<ConversationModel>(
      path: ApiEndpoints.conversations,
      method: HttpMethod.post,
      // `name` est interdit sur une conversation directe : l'envoyer produit
      // un 400.
      data: {
        'type': 'direct',
        'participants': [userId],
      },
      dataKey: 'data',
      fromJson: (json) => ConversationModel.fromJson(json),
    );
  }

  @override
  Future<ApiResult<bool>> joinTicket({
    required String ticketId,
    required String agentId,
  }) {
    return _client.request<bool>(
      path: ApiEndpoints.claimTicket(ticketId),
      method: HttpMethod.post,
      fromJson: (_) => true,
    );
  }
}
