// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dio)
final dioProvider = DioProvider._();

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'd7062cb923e8b3da5a4e79ac2eae91a88cfde8f0';

/// Racine de l'injection de dépendances de la couche data : toutes les data
/// sources se construisent à partir de ce provider.

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

/// Racine de l'injection de dépendances de la couche data : toutes les data
/// sources se construisent à partir de ce provider.

final class ApiClientProvider
    extends
        $FunctionalProvider<
          ApiClientInterface,
          ApiClientInterface,
          ApiClientInterface
        >
    with $Provider<ApiClientInterface> {
  /// Racine de l'injection de dépendances de la couche data : toutes les data
  /// sources se construisent à partir de ce provider.
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $ProviderElement<ApiClientInterface> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ApiClientInterface create(Ref ref) {
    return apiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiClientInterface value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiClientInterface>(value),
    );
  }
}

String _$apiClientHash() => r'db4ed4cb56022f33b7319f7505578b3a284ecc52';
