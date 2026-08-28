import 'package:fpdart/fpdart.dart';

import '../../../core/abstract/failure.dart';
import '../../../core/abstract/usecase.dart';
import '../../entity/auth/user_entity.dart';
import '../../repository/auth/auth_repository.dart';

/// Ouvre une session.
class SignInUseCase implements UseCase<AuthSessionEntity, SignInParams> {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthSessionEntity>> call(SignInParams params) =>
      _repository.signIn(params);
}

/// Ferme la session.
class SignOutUseCase implements UseCase<Unit, SignOutParams> {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SignOutParams params) =>
      _repository.signOut();
}

/// Relit la session stockée au démarrage.
class RestoreSessionUseCase
    implements UseCase<AuthSessionEntity?, RestoreSessionParams> {
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthSessionEntity?>> call(
    RestoreSessionParams params,
  ) => _repository.restoreSession();
}

/// Un use case sans paramètre déclare quand même sa classe : ajouter un filtre
/// plus tard ne cassera aucun appelant.
class SignOutParams {
  const SignOutParams();
}

class RestoreSessionParams {
  const RestoreSessionParams();
}
