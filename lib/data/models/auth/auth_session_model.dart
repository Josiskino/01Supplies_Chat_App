import '../../../domain/entity/auth/user_entity.dart';
import 'user_model.dart';

/// Un jeton et son expiration, tels que l'API les renvoie.
class AuthTokenModel {
  const AuthTokenModel({required this.token, this.expires});

  final String token;
  final String? expires;

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) => AuthTokenModel(
    token: (json['token'] ?? '').toString(),
    expires: json['expires']?.toString(),
  );

  AuthTokenEntity toEntity() => AuthTokenEntity(
    token: token,
    // Une date illisible ne doit pas faire échouer la connexion : elle ne sert
    // qu'à anticiper le rafraîchissement, que le 401 déclenche de toute façon.
    expiresAt: expires == null ? null : DateTime.tryParse(expires!),
  );
}

/// Réponse de `POST /auth/login` : l'utilisateur et ses deux jetons.
class AuthSessionModel {
  const AuthSessionModel({
    required this.user,
    required this.access,
    required this.refresh,
  });

  final UserModel user;
  final AuthTokenModel access;
  final AuthTokenModel refresh;

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final tokens = (json['tokens'] as Map?)?.cast<String, dynamic>() ?? {};
    return AuthSessionModel(
      user: UserModel.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      access: AuthTokenModel.fromJson(
        (tokens['access'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      refresh: AuthTokenModel.fromJson(
        (tokens['refresh'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  AuthSessionEntity toEntity() => AuthSessionEntity(
    user: user.toEntity(),
    accessToken: access.toEntity(),
    refreshToken: refresh.toEntity(),
  );
}
