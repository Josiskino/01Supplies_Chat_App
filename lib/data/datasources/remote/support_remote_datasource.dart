import '../../../core/abstract/api_client_interface.dart';
import '../../../core/constants/api_endpoints_urls.dart';
import '../../../core/utils/api_types.dart';
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
    return _client.request<List<SupportTicketModel>>(
      // La file commune, pas `/me` : un admin qui ne s'est encore saisi de rien
      // verrait sinon une application vide alors que des clients attendent.
      path: ApiEndpoints.supportQueue,
      method: HttpMethod.get,
      queryParameters: {'status': ?status, 'page': page, 'limit': limit},
      dataKey: 'data',
      // `ApiResponseHandler` réenveloppe toute liste dans `{data: …}` avant
      // d'appeler ce parseur, dont le contrat est de recevoir une Map. La
      // liste se relit donc sous cette clé, et non à la racine.
      fromJson: (json) => (json['data'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SupportTicketModel.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  @override
  Future<ApiResult<bool>> joinTicket({
    required String ticketId,
    required String agentId,
  }) {
    return _client.request<bool>(
      path: ApiEndpoints.assignTicket(ticketId),
      method: HttpMethod.post,
      data: {'agentId': agentId},
      fromJson: (_) => true,
    );
  }
}
