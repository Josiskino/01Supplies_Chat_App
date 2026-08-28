import 'dart:convert';

import 'package:fpdart/fpdart.dart';

import '../../core/abstract/base_repository.dart';
import '../../core/abstract/failure.dart';
import '../../core/utils/preferences.dart';
import '../../domain/entity/auth/user_entity.dart';
import '../../domain/repository/auth/auth_repository.dart';
import '../datasources/abstract/auth/auth_datasource_contract.dart';
import '../models/auth/auth_session_model.dart';
import '../models/auth/user_model.dart';

/// Implémentation de [AuthRepository].
///
/// Porte deux responsabilités que le domaine ne peut pas assumer seul : la
/// **règle d'accès** — qui a le droit d'ouvrir la messagerie interne — et la
/// persistance des jetons là où l'intercepteur HTTP va les chercher.
class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthDataSourceContract _remote;

  @override
  Future<Either<Failure, AuthSessionEntity>> signIn(SignInParams params) async {
    final result = await execute<AuthSessionModel>(
      () => _remote.signIn(email: params.email, password: params.password),
    );

    return result.flatMap((model) {
      final session = model.toEntity();

      // Le filtre se pose **après** l'authentification, jamais avant : c'est le
      // serveur qui dit quel rôle porte le compte, et lui seul. Refuser sur la
      // foi de l'adresse saisie laisserait passer un client dont le rôle a
      // changé, et bloquerait un agent dont l'adresse ne ressemble à rien.
      if (!session.user.canAccessWorkspace) {
        return Left(
          ForbiddenFailure(
            'Ce compte n’a pas accès à la messagerie interne. '
            'Elle est réservée aux équipes 01Supplies.',
          ),
        );
      }

      if (session.accessToken.token.isEmpty) {
        return Left(
          AuthFailure(
            'Connexion impossible : le serveur n’a pas fourni de jeton.',
          ),
        );
      }

      return Right(session);
    });
  }

  /// Dépose la session là où l'intercepteur HTTP la relira.
  ///
  /// Séparé de [signIn] pour que le refus d'un rôle non autorisé n'écrive
  /// **rien** sur l'appareil : un client éconduit ne doit pas repartir avec un
  /// jeton valide en mémoire locale.
  Future<void> persist(AuthSessionEntity session) async {
    await SharedPreferencesHelper.setValue(
      StorageKeys.token,
      session.accessToken.token,
    );
    await SharedPreferencesHelper.setValue(
      StorageKeys.refreshToken,
      session.refreshToken.token,
    );
    final expires = session.accessToken.expiresAt;
    if (expires != null) {
      await SharedPreferencesHelper.setValue(
        StorageKeys.tokenExpires,
        expires.toIso8601String(),
      );
    }
    await SharedPreferencesHelper.setValue(
      StorageKeys.userProfile,
      jsonEncode(_userToJson(session.user)),
    );
  }

  @override
  Future<Either<Failure, AuthSessionEntity?>> restoreSession() async {
    try {
      final token = await SharedPreferencesHelper.getValue(StorageKeys.token);
      final refresh = await SharedPreferencesHelper.getValue(
        StorageKeys.refreshToken,
      );
      final profile = await SharedPreferencesHelper.getValue(
        StorageKeys.userProfile,
      );
      if (token.isEmpty || profile.isEmpty) return const Right(null);

      final user = UserModel.fromJson(
        jsonDecode(profile) as Map<String, dynamic>,
      ).toEntity();

      // Une session stockée dont le rôle n'est plus autorisé est effacée : le
      // compte a pu changer de rôle depuis la dernière ouverture.
      if (!user.canAccessWorkspace) {
        await clearLocalSession();
        return const Right(null);
      }

      final expiresRaw = await SharedPreferencesHelper.getValue(
        StorageKeys.tokenExpires,
      );
      return Right(
        AuthSessionEntity(
          user: user,
          accessToken: AuthTokenEntity(
            token: token,
            expiresAt: DateTime.tryParse(expiresRaw),
          ),
          refreshToken: AuthTokenEntity(token: refresh, expiresAt: null),
        ),
      );
    } catch (e) {
      // Un profil illisible n'est pas une panne : on repart d'une session vide
      // plutôt que de bloquer l'ouverture de l'application.
      await clearLocalSession();
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    final refresh = await SharedPreferencesHelper.getValue(
      StorageKeys.refreshToken,
    );

    // L'appel serveur est tenté, mais son échec ne retient pas l'utilisateur :
    // une déconnexion qui échoue parce que le réseau est coupé laisserait la
    // session ouverte sur l'appareil, ce qui est le contraire du but.
    if (refresh.isNotEmpty) {
      await execute<bool>(() => _remote.signOut(refreshToken: refresh));
    }
    await clearLocalSession();
    return const Right(unit);
  }

  Future<void> clearLocalSession() async {
    await SharedPreferencesHelper.deleteValue(StorageKeys.token);
    await SharedPreferencesHelper.deleteValue(StorageKeys.refreshToken);
    await SharedPreferencesHelper.deleteValue(StorageKeys.tokenExpires);
    await SharedPreferencesHelper.deleteValue(StorageKeys.userProfile);
  }

  Map<String, dynamic> _userToJson(UserEntity user) => {
    'id': user.id,
    'email': user.email,
    'firstName': user.firstName,
    'lastName': user.lastName,
    'role': user.role?.wireName,
    'phone': user.phones,
    'avatar': user.avatarUrl,
    'isVerified': user.isVerified,
  };
}
