import 'package:fpdart/fpdart.dart';

import '../../../core/abstract/failure.dart';
import '../../entity/auth/user_entity.dart';

/// Contrat d'authentification, vu du domaine.
abstract interface class AuthRepository {
  /// Ouvre une session pour un membre des équipes logistique.
  ///
  /// Échoue en [ForbiddenFailure] si les identifiants sont valides mais que le
  /// compte n'a pas accès à la messagerie interne — un client, typiquement.
  Future<Either<Failure, AuthSessionEntity>> signIn(SignInParams params);

  /// Ferme la session, localement dans tous les cas.
  Future<Either<Failure, Unit>> signOut();

  /// Session déjà stockée sur l'appareil, ou `null` si aucune.
  Future<Either<Failure, AuthSessionEntity?>> restoreSession();
}

/// Paramètres de connexion.
class SignInParams {
  const SignInParams({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}
