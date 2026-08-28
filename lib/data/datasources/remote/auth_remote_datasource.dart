import '../../../core/abstract/api_client_interface.dart';
import '../../../core/constants/api_endpoints_urls.dart';
import '../../../core/utils/api_types.dart';
import '../../models/auth/auth_session_model.dart';
import '../abstract/auth/auth_datasource_contract.dart';

/// Implémentation HTTP du contrat d'authentification.
class AuthRemoteDataSource implements AuthDataSourceContract {
  const AuthRemoteDataSource(this._client);

  final ApiClientInterface _client;

  @override
  Future<ApiResult<AuthSessionModel>> signIn({
    required String email,
    required String password,
  }) {
    return _client.request<AuthSessionModel>(
      path: ApiEndpoints.login,
      method: HttpMethod.post,
      // Le champ `role` que l'API accepte n'est pas transmis : il sert à choisir
      // un espace de connexion (client, vendeur…), alors qu'ici on veut le rôle
      // *réel* du compte pour décider de l'accès. L'imposer reviendrait à se
      // répondre à soi-même.
      data: {'email': email.trim(), 'password': password},
      dataKey: 'data',
      fromJson: (json) => AuthSessionModel.fromJson(json),
    );
  }

  @override
  Future<ApiResult<bool>> signOut({required String refreshToken}) {
    return _client.request<bool>(
      path: ApiEndpoints.logout,
      method: HttpMethod.post,
      data: {'refreshToken': refreshToken},
      fromJson: (_) => true,
    );
  }
}
