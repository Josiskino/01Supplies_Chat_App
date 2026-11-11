/// Hiérarchie d'échecs métier renvoyée par la couche domaine.
///
/// Les couches supérieures ne voient jamais une `DioException` ni un code HTTP :
/// [BaseRepository] les traduit en sous-type de [Failure], et l'UI décide quoi
/// afficher selon le type.
abstract class Failure {
  final String message;
  final StackTrace? stackTrace;

  Failure(this.message, [this.stackTrace]);

  @override
  String toString() => '$runtimeType: $message';
}

/// Pas de réseau, DNS injoignable, timeout.
class NetworkFailure extends Failure {
  NetworkFailure(super.message);
}

class RateLimitFailure extends Failure {
  RateLimitFailure(super.message, {this.retryAfterSeconds = 60});
  final int retryAfterSeconds;
}

/// Règle métier rejetée par le serveur (4xx/5xx non spécifiques).
class BusinessFailure extends Failure {
  final Object? error;

  BusinessFailure(super.message, [this.error, super.stackTrace]);
}

/// 401 — session expirée ou identifiants refusés.
class AuthFailure extends Failure {
  AuthFailure(super.message);
}

/// 403 — authentifié mais pas autorisé.
class ForbiddenFailure extends Failure {
  ForbiddenFailure(super.message);
}

/// 404 — ressource absente.
class NotFoundFailure extends Failure {
  NotFoundFailure(super.message);
}

/// Tout le reste : bug, parsing impossible, exception non prévue.
class UnexpectedFailure extends Failure {
  UnexpectedFailure(super.message, [super.stackTrace]);
}
