import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/datasources/abstract/auth/auth_datasource_contract.dart';
import '../../../data/datasources/remote/auth_remote_datasource.dart';
import '../../../data/repository/auth_repository_impl.dart';
import '../../../domain/entity/auth/user_entity.dart';
import '../../../domain/repository/auth/auth_repository.dart';
import '../../../domain/usecases/auth/auth_usecases.dart';
import '../request/api_provider.dart';

part 'auth_provider.g.dart';

// ── Infrastructure ──────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
AuthDataSourceContract authDataSource(Ref ref) =>
    AuthRemoteDataSource(ref.watch(apiClientProvider));

/// Exposé sous son type concret, contrairement à l'usage.
///
/// `persist` et `clearLocalSession` ne relèvent pas du domaine — le domaine ne
/// sait pas qu'un stockage local existe — mais le notifier de session en a
/// besoin. Les remonter dans le contrat y ferait entrer une notion
/// d'infrastructure ; les exposer ici les garde à leur place.
@Riverpod(keepAlive: true)
AuthRepositoryImpl authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(authDataSourceProvider));

// ── Use cases ───────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
SignInUseCase signInUseCase(Ref ref) =>
    SignInUseCase(ref.watch(authRepositoryProvider));

@Riverpod(keepAlive: true)
SignOutUseCase signOutUseCase(Ref ref) =>
    SignOutUseCase(ref.watch(authRepositoryProvider));

@Riverpod(keepAlive: true)
RestoreSessionUseCase restoreSessionUseCase(Ref ref) =>
    RestoreSessionUseCase(ref.watch(authRepositoryProvider));

// ── Notifier ────────────────────────────────────────────────────────────────

/// Utilisateur connecté, ou `null`.
///
/// Séparé du statut consommé par le routeur : celui-ci ne s'intéresse qu'à
/// « authentifié ou non », alors que les écrans ont besoin du nom, de l'avatar
/// et surtout de l'identifiant pour s'abonner au bon canal temps réel.
@Riverpod(keepAlive: true)
class CurrentUserNotifier extends _$CurrentUserNotifier {
  @override
  UserEntity? build() => null;

  void set(UserEntity? user) => state = user;
}

/// Repository exposé sous son contrat, pour les consommateurs qui n'ont pas
/// besoin des méthodes de persistance.
@Riverpod(keepAlive: true)
AuthRepository authRepositoryContract(Ref ref) =>
    ref.watch(authRepositoryProvider);
