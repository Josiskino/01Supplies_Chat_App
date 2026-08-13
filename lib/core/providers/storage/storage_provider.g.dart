// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stockage clé/valeur brut. Surchargeable en test via `overrideWith`.

@ProviderFor(localStorage)
final localStorageProvider = LocalStorageProvider._();

/// Stockage clé/valeur brut. Surchargeable en test via `overrideWith`.

final class LocalStorageProvider
    extends
        $FunctionalProvider<
          LocalStorageInterface,
          LocalStorageInterface,
          LocalStorageInterface
        >
    with $Provider<LocalStorageInterface> {
  /// Stockage clé/valeur brut. Surchargeable en test via `overrideWith`.
  LocalStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localStorageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localStorageHash();

  @$internal
  @override
  $ProviderElement<LocalStorageInterface> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalStorageInterface create(Ref ref) {
    return localStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalStorageInterface value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalStorageInterface>(value),
    );
  }
}

String _$localStorageHash() => r'45940df7c64c772801dd767db506909135181aef';

/// Préférences d'affichage (thème, langue).

@ProviderFor(storageService)
final storageServiceProvider = StorageServiceProvider._();

/// Préférences d'affichage (thème, langue).

final class StorageServiceProvider
    extends $FunctionalProvider<StorageService, StorageService, StorageService>
    with $Provider<StorageService> {
  /// Préférences d'affichage (thème, langue).
  StorageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageServiceHash();

  @$internal
  @override
  $ProviderElement<StorageService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StorageService create(Ref ref) {
    return storageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorageService>(value),
    );
  }
}

String _$storageServiceHash() => r'fd1408c968d7121cadbdebf6060a15521588cac2';
