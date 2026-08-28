// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authDataSource)
final authDataSourceProvider = AuthDataSourceProvider._();

final class AuthDataSourceProvider
    extends
        $FunctionalProvider<
          AuthDataSourceContract,
          AuthDataSourceContract,
          AuthDataSourceContract
        >
    with $Provider<AuthDataSourceContract> {
  AuthDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authDataSourceHash();

  @$internal
  @override
  $ProviderElement<AuthDataSourceContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthDataSourceContract create(Ref ref) {
    return authDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthDataSourceContract value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthDataSourceContract>(value),
    );
  }
}

String _$authDataSourceHash() => r'74c659dc261353564e22453972a2ccb8d97b568a';

/// Exposé sous son type concret, contrairement à l'usage.
///
/// `persist` et `clearLocalSession` ne relèvent pas du domaine — le domaine ne
/// sait pas qu'un stockage local existe — mais le notifier de session en a
/// besoin. Les remonter dans le contrat y ferait entrer une notion
/// d'infrastructure ; les exposer ici les garde à leur place.

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

/// Exposé sous son type concret, contrairement à l'usage.
///
/// `persist` et `clearLocalSession` ne relèvent pas du domaine — le domaine ne
/// sait pas qu'un stockage local existe — mais le notifier de session en a
/// besoin. Les remonter dans le contrat y ferait entrer une notion
/// d'infrastructure ; les exposer ici les garde à leur place.

final class AuthRepositoryProvider
    extends
        $FunctionalProvider<
          AuthRepositoryImpl,
          AuthRepositoryImpl,
          AuthRepositoryImpl
        >
    with $Provider<AuthRepositoryImpl> {
  /// Exposé sous son type concret, contrairement à l'usage.
  ///
  /// `persist` et `clearLocalSession` ne relèvent pas du domaine — le domaine ne
  /// sait pas qu'un stockage local existe — mais le notifier de session en a
  /// besoin. Les remonter dans le contrat y ferait entrer une notion
  /// d'infrastructure ; les exposer ici les garde à leur place.
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepositoryImpl> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthRepositoryImpl create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepositoryImpl value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepositoryImpl>(value),
    );
  }
}

String _$authRepositoryHash() => r'41b1998eedaedfef1cfec883e30197c56c09a058';

@ProviderFor(signInUseCase)
final signInUseCaseProvider = SignInUseCaseProvider._();

final class SignInUseCaseProvider
    extends $FunctionalProvider<SignInUseCase, SignInUseCase, SignInUseCase>
    with $Provider<SignInUseCase> {
  SignInUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInUseCaseHash();

  @$internal
  @override
  $ProviderElement<SignInUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignInUseCase create(Ref ref) {
    return signInUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInUseCase>(value),
    );
  }
}

String _$signInUseCaseHash() => r'27c9353707dc0ba7c68faf82a9c8f7b6d1212801';

@ProviderFor(signOutUseCase)
final signOutUseCaseProvider = SignOutUseCaseProvider._();

final class SignOutUseCaseProvider
    extends $FunctionalProvider<SignOutUseCase, SignOutUseCase, SignOutUseCase>
    with $Provider<SignOutUseCase> {
  SignOutUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signOutUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signOutUseCaseHash();

  @$internal
  @override
  $ProviderElement<SignOutUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignOutUseCase create(Ref ref) {
    return signOutUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignOutUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignOutUseCase>(value),
    );
  }
}

String _$signOutUseCaseHash() => r'5f544eaa8403bdb843d209fa5e1e36e4320b5e49';

@ProviderFor(restoreSessionUseCase)
final restoreSessionUseCaseProvider = RestoreSessionUseCaseProvider._();

final class RestoreSessionUseCaseProvider
    extends
        $FunctionalProvider<
          RestoreSessionUseCase,
          RestoreSessionUseCase,
          RestoreSessionUseCase
        >
    with $Provider<RestoreSessionUseCase> {
  RestoreSessionUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restoreSessionUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restoreSessionUseCaseHash();

  @$internal
  @override
  $ProviderElement<RestoreSessionUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RestoreSessionUseCase create(Ref ref) {
    return restoreSessionUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestoreSessionUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestoreSessionUseCase>(value),
    );
  }
}

String _$restoreSessionUseCaseHash() =>
    r'6c554241518e2ffc9c5a16d3cceaa0e193eb9b0b';

/// Utilisateur connecté, ou `null`.
///
/// Séparé du statut consommé par le routeur : celui-ci ne s'intéresse qu'à
/// « authentifié ou non », alors que les écrans ont besoin du nom, de l'avatar
/// et surtout de l'identifiant pour s'abonner au bon canal temps réel.

@ProviderFor(CurrentUserNotifier)
final currentUserProvider = CurrentUserNotifierProvider._();

/// Utilisateur connecté, ou `null`.
///
/// Séparé du statut consommé par le routeur : celui-ci ne s'intéresse qu'à
/// « authentifié ou non », alors que les écrans ont besoin du nom, de l'avatar
/// et surtout de l'identifiant pour s'abonner au bon canal temps réel.
final class CurrentUserNotifierProvider
    extends $NotifierProvider<CurrentUserNotifier, UserEntity?> {
  /// Utilisateur connecté, ou `null`.
  ///
  /// Séparé du statut consommé par le routeur : celui-ci ne s'intéresse qu'à
  /// « authentifié ou non », alors que les écrans ont besoin du nom, de l'avatar
  /// et surtout de l'identifiant pour s'abonner au bon canal temps réel.
  CurrentUserNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserNotifierHash();

  @$internal
  @override
  CurrentUserNotifier create() => CurrentUserNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserEntity? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserEntity?>(value),
    );
  }
}

String _$currentUserNotifierHash() =>
    r'ffb4b88135b67eff2c7424507cde737b3ead1875';

/// Utilisateur connecté, ou `null`.
///
/// Séparé du statut consommé par le routeur : celui-ci ne s'intéresse qu'à
/// « authentifié ou non », alors que les écrans ont besoin du nom, de l'avatar
/// et surtout de l'identifiant pour s'abonner au bon canal temps réel.

abstract class _$CurrentUserNotifier extends $Notifier<UserEntity?> {
  UserEntity? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UserEntity?, UserEntity?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserEntity?, UserEntity?>,
              UserEntity?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Repository exposé sous son contrat, pour les consommateurs qui n'ont pas
/// besoin des méthodes de persistance.

@ProviderFor(authRepositoryContract)
final authRepositoryContractProvider = AuthRepositoryContractProvider._();

/// Repository exposé sous son contrat, pour les consommateurs qui n'ont pas
/// besoin des méthodes de persistance.

final class AuthRepositoryContractProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// Repository exposé sous son contrat, pour les consommateurs qui n'ont pas
  /// besoin des méthodes de persistance.
  AuthRepositoryContractProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryContractProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryContractHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepositoryContract(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryContractHash() =>
    r'255fb7099e1e57c3da9ecfb5e02832d2ccf2c3ce';
