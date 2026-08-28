// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supportDataSource)
final supportDataSourceProvider = SupportDataSourceProvider._();

final class SupportDataSourceProvider
    extends
        $FunctionalProvider<
          SupportDataSourceContract,
          SupportDataSourceContract,
          SupportDataSourceContract
        >
    with $Provider<SupportDataSourceContract> {
  SupportDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportDataSourceHash();

  @$internal
  @override
  $ProviderElement<SupportDataSourceContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupportDataSourceContract create(Ref ref) {
    return supportDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupportDataSourceContract value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupportDataSourceContract>(value),
    );
  }
}

String _$supportDataSourceHash() => r'8f7502d16737383ba667cc503ed7ad7965081725';

@ProviderFor(supportRepository)
final supportRepositoryProvider = SupportRepositoryProvider._();

final class SupportRepositoryProvider
    extends
        $FunctionalProvider<
          SupportRepository,
          SupportRepository,
          SupportRepository
        >
    with $Provider<SupportRepository> {
  SupportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportRepositoryHash();

  @$internal
  @override
  $ProviderElement<SupportRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupportRepository create(Ref ref) {
    return supportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupportRepository>(value),
    );
  }
}

String _$supportRepositoryHash() => r'f7d26bb904df1eebf427939ad44a3c695afb532a';

@ProviderFor(fetchQueueUseCase)
final fetchQueueUseCaseProvider = FetchQueueUseCaseProvider._();

final class FetchQueueUseCaseProvider
    extends
        $FunctionalProvider<
          FetchQueueUseCase,
          FetchQueueUseCase,
          FetchQueueUseCase
        >
    with $Provider<FetchQueueUseCase> {
  FetchQueueUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fetchQueueUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fetchQueueUseCaseHash();

  @$internal
  @override
  $ProviderElement<FetchQueueUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FetchQueueUseCase create(Ref ref) {
    return fetchQueueUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FetchQueueUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FetchQueueUseCase>(value),
    );
  }
}

String _$fetchQueueUseCaseHash() => r'f6561fd81f105520ce31c283135dacc18d9eafda';

@ProviderFor(claimTicketUseCase)
final claimTicketUseCaseProvider = ClaimTicketUseCaseProvider._();

final class ClaimTicketUseCaseProvider
    extends
        $FunctionalProvider<
          ClaimTicketUseCase,
          ClaimTicketUseCase,
          ClaimTicketUseCase
        >
    with $Provider<ClaimTicketUseCase> {
  ClaimTicketUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'claimTicketUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$claimTicketUseCaseHash();

  @$internal
  @override
  $ProviderElement<ClaimTicketUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ClaimTicketUseCase create(Ref ref) {
    return claimTicketUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClaimTicketUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClaimTicketUseCase>(value),
    );
  }
}

String _$claimTicketUseCaseHash() =>
    r'efc3ece134c0e781d95f1b3e5f8e5c0159633514';

/// La file d'attente commune, telle que l'onglet Conversations l'affiche.
///
/// Tous les admins voient la même liste : un client écrit, son ticket y paraît,
/// et le premier qui répond s'en saisit. C'est pourquoi elle vient de
/// `/messaging/support` et non de `/support/me`, qui ne rendrait que les
/// dossiers déjà pris — donc rien, au premier lancement.

@ProviderFor(SupportQueue)
final supportQueueProvider = SupportQueueProvider._();

/// La file d'attente commune, telle que l'onglet Conversations l'affiche.
///
/// Tous les admins voient la même liste : un client écrit, son ticket y paraît,
/// et le premier qui répond s'en saisit. C'est pourquoi elle vient de
/// `/messaging/support` et non de `/support/me`, qui ne rendrait que les
/// dossiers déjà pris — donc rien, au premier lancement.
final class SupportQueueProvider
    extends $AsyncNotifierProvider<SupportQueue, List<SupportTicketEntity>> {
  /// La file d'attente commune, telle que l'onglet Conversations l'affiche.
  ///
  /// Tous les admins voient la même liste : un client écrit, son ticket y paraît,
  /// et le premier qui répond s'en saisit. C'est pourquoi elle vient de
  /// `/messaging/support` et non de `/support/me`, qui ne rendrait que les
  /// dossiers déjà pris — donc rien, au premier lancement.
  SupportQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportQueueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportQueueHash();

  @$internal
  @override
  SupportQueue create() => SupportQueue();
}

String _$supportQueueHash() => r'126cfa15fe19f382386bf58cd9bcceffdda54ebc';

/// La file d'attente commune, telle que l'onglet Conversations l'affiche.
///
/// Tous les admins voient la même liste : un client écrit, son ticket y paraît,
/// et le premier qui répond s'en saisit. C'est pourquoi elle vient de
/// `/messaging/support` et non de `/support/me`, qui ne rendrait que les
/// dossiers déjà pris — donc rien, au premier lancement.

abstract class _$SupportQueue
    extends $AsyncNotifier<List<SupportTicketEntity>> {
  FutureOr<List<SupportTicketEntity>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<SupportTicketEntity>>,
              List<SupportTicketEntity>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<SupportTicketEntity>>,
                List<SupportTicketEntity>
              >,
              AsyncValue<List<SupportTicketEntity>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
