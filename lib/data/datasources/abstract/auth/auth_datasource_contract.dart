import '../../../../core/utils/api_types.dart';
import '../../../models/auth/auth_session_model.dart';

/// Accès distant aux opérations d'authentification.
///
/// Renvoie des `ApiResult<Model>` : la traduction en `Either<Failure, Entity>`
/// appartient au repository, pas à la source.
abstract interface class AuthDataSourceContract {
  Future<ApiResult<AuthSessionModel>> signIn({
    required String email,
    required String password,
  });

  /// Invalide la session côté serveur.
  ///
  /// Le jeton de rafraîchissement est exigé par l'API : une déconnexion qui ne
  /// le révoquerait pas laisserait une session utilisable ailleurs.
  Future<ApiResult<bool>> signOut({required String refreshToken});
}
