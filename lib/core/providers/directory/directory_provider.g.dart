// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(directoryDataSource)
final directoryDataSourceProvider = DirectoryDataSourceProvider._();

final class DirectoryDataSourceProvider
    extends
        $FunctionalProvider<
          DirectoryDataSourceContract,
          DirectoryDataSourceContract,
          DirectoryDataSourceContract
        >
    with $Provider<DirectoryDataSourceContract> {
  DirectoryDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'directoryDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$directoryDataSourceHash();

  @$internal
  @override
  $ProviderElement<DirectoryDataSourceContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DirectoryDataSourceContract create(Ref ref) {
    return directoryDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DirectoryDataSourceContract value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DirectoryDataSourceContract>(value),
    );
  }
}

String _$directoryDataSourceHash() =>
    r'32f55985b03d6748a43440ce1e658634edc3bc2f';

@ProviderFor(directoryRepository)
final directoryRepositoryProvider = DirectoryRepositoryProvider._();

final class DirectoryRepositoryProvider
    extends
        $FunctionalProvider<
          DirectoryRepository,
          DirectoryRepository,
          DirectoryRepository
        >
    with $Provider<DirectoryRepository> {
  DirectoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'directoryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$directoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<DirectoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DirectoryRepository create(Ref ref) {
    return directoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DirectoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DirectoryRepository>(value),
    );
  }
}

String _$directoryRepositoryHash() =>
    r'484d302ad03615e413eb6e581284789557c674bd';

@ProviderFor(fetchContactsUseCase)
final fetchContactsUseCaseProvider = FetchContactsUseCaseProvider._();

final class FetchContactsUseCaseProvider
    extends
        $FunctionalProvider<
          FetchContactsUseCase,
          FetchContactsUseCase,
          FetchContactsUseCase
        >
    with $Provider<FetchContactsUseCase> {
  FetchContactsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fetchContactsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fetchContactsUseCaseHash();

  @$internal
  @override
  $ProviderElement<FetchContactsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FetchContactsUseCase create(Ref ref) {
    return fetchContactsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FetchContactsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FetchContactsUseCase>(value),
    );
  }
}

String _$fetchContactsUseCaseHash() =>
    r'58b3aa17869f55c605f0c83d246ce21ed82fe70e';

/// Le répertoire des clients et partenaires.
///
/// Chargé **en une fois** plutôt que page par page : la plateforme compte moins
/// de deux cents interlocuteurs, et une liste complète en mémoire rend la
/// recherche instantanée, sans aller-retour réseau à chaque lettre tapée. Le
/// jour où ce volume décuplera, c'est `query` côté serveur qu'il faudra brancher
/// — le paramètre est déjà prévu.

@ProviderFor(Contacts)
final contactsProvider = ContactsProvider._();

/// Le répertoire des clients et partenaires.
///
/// Chargé **en une fois** plutôt que page par page : la plateforme compte moins
/// de deux cents interlocuteurs, et une liste complète en mémoire rend la
/// recherche instantanée, sans aller-retour réseau à chaque lettre tapée. Le
/// jour où ce volume décuplera, c'est `query` côté serveur qu'il faudra brancher
/// — le paramètre est déjà prévu.
final class ContactsProvider
    extends $AsyncNotifierProvider<Contacts, List<UserEntity>> {
  /// Le répertoire des clients et partenaires.
  ///
  /// Chargé **en une fois** plutôt que page par page : la plateforme compte moins
  /// de deux cents interlocuteurs, et une liste complète en mémoire rend la
  /// recherche instantanée, sans aller-retour réseau à chaque lettre tapée. Le
  /// jour où ce volume décuplera, c'est `query` côté serveur qu'il faudra brancher
  /// — le paramètre est déjà prévu.
  ContactsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactsHash();

  @$internal
  @override
  Contacts create() => Contacts();
}

String _$contactsHash() => r'3d6ed42a77663f93453670f69c46b1b4e22fa9f1';

/// Le répertoire des clients et partenaires.
///
/// Chargé **en une fois** plutôt que page par page : la plateforme compte moins
/// de deux cents interlocuteurs, et une liste complète en mémoire rend la
/// recherche instantanée, sans aller-retour réseau à chaque lettre tapée. Le
/// jour où ce volume décuplera, c'est `query` côté serveur qu'il faudra brancher
/// — le paramètre est déjà prévu.

abstract class _$Contacts extends $AsyncNotifier<List<UserEntity>> {
  FutureOr<List<UserEntity>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<UserEntity>>, List<UserEntity>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<UserEntity>>, List<UserEntity>>,
              AsyncValue<List<UserEntity>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
