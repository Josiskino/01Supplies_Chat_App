// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mediaDataSource)
final mediaDataSourceProvider = MediaDataSourceProvider._();

final class MediaDataSourceProvider
    extends
        $FunctionalProvider<
          MediaDataSourceContract,
          MediaDataSourceContract,
          MediaDataSourceContract
        >
    with $Provider<MediaDataSourceContract> {
  MediaDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaDataSourceHash();

  @$internal
  @override
  $ProviderElement<MediaDataSourceContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MediaDataSourceContract create(Ref ref) {
    return mediaDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaDataSourceContract value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaDataSourceContract>(value),
    );
  }
}

String _$mediaDataSourceHash() => r'9eaec1d20457d1865397fd6f6eb954dd17087458';

@ProviderFor(mediaRepository)
final mediaRepositoryProvider = MediaRepositoryProvider._();

final class MediaRepositoryProvider
    extends
        $FunctionalProvider<MediaRepository, MediaRepository, MediaRepository>
    with $Provider<MediaRepository> {
  MediaRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaRepositoryHash();

  @$internal
  @override
  $ProviderElement<MediaRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MediaRepository create(Ref ref) {
    return mediaRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaRepository>(value),
    );
  }
}

String _$mediaRepositoryHash() => r'8ea27e72d6ebfd94ef7df31e3bd5e986eef12093';

@ProviderFor(uploadMediaUseCase)
final uploadMediaUseCaseProvider = UploadMediaUseCaseProvider._();

final class UploadMediaUseCaseProvider
    extends
        $FunctionalProvider<
          UploadMediaUseCase,
          UploadMediaUseCase,
          UploadMediaUseCase
        >
    with $Provider<UploadMediaUseCase> {
  UploadMediaUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadMediaUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadMediaUseCaseHash();

  @$internal
  @override
  $ProviderElement<UploadMediaUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UploadMediaUseCase create(Ref ref) {
    return uploadMediaUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UploadMediaUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UploadMediaUseCase>(value),
    );
  }
}

String _$uploadMediaUseCaseHash() =>
    r'78ea3b22f12648db4d7df3edea32085fd52bddea';
