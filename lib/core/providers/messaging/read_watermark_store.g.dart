// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_watermark_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(readWatermarkStore)
final readWatermarkStoreProvider = ReadWatermarkStoreProvider._();

final class ReadWatermarkStoreProvider
    extends
        $FunctionalProvider<
          ReadWatermarkStore,
          ReadWatermarkStore,
          ReadWatermarkStore
        >
    with $Provider<ReadWatermarkStore> {
  ReadWatermarkStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readWatermarkStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readWatermarkStoreHash();

  @$internal
  @override
  $ProviderElement<ReadWatermarkStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReadWatermarkStore create(Ref ref) {
    return readWatermarkStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReadWatermarkStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReadWatermarkStore>(value),
    );
  }
}

String _$readWatermarkStoreHash() =>
    r'15e4031b8cba76e8a5e43742931c42d9760ae422';
