import '../../../core/abstract/api_client_interface.dart';
import '../../../core/constants/api_endpoints_urls.dart';
import '../../../core/utils/api_types.dart';
import '../../../domain/entity/auth/user_role.dart';
import '../../models/directory/user_page_model.dart';
import '../abstract/directory/directory_datasource_contract.dart';

/// Implémentation HTTP du répertoire.
class DirectoryRemoteDataSource implements DirectoryDataSourceContract {
  const DirectoryRemoteDataSource(this._client);

  final ApiClientInterface _client;

  @override
  Future<ApiResult<UserPageModel>> fetchUsers({
    required List<UserRole> roles,
    String? query,
    int page = 1,
    int limit = 200,
  }) {
    return _client.request<UserPageModel>(
      path: ApiEndpoints.users,
      method: HttpMethod.get,
      queryParameters: {
        // `role` est répété une fois par valeur : l'API accepte le paramètre
        // sous forme de tableau, ce qui évite un appel par rôle puis une fusion
        // côté application — et une pagination qui n'aurait plus de sens.
        if (roles.isNotEmpty) 'role': roles.map((r) => r.wireName).toList(),
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
        'page': page,
        'limit': limit,
      },
      dataKey: 'data',
      fromJson: (json) => UserPageModel.fromJson(json),
    );
  }
}
