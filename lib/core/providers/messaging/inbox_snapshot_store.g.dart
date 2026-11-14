// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_snapshot_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(inboxSnapshotStore)
final inboxSnapshotStoreProvider = InboxSnapshotStoreProvider._();

final class InboxSnapshotStoreProvider
    extends
        $FunctionalProvider<
          InboxSnapshotStore,
          InboxSnapshotStore,
          InboxSnapshotStore
        >
    with $Provider<InboxSnapshotStore> {
  InboxSnapshotStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxSnapshotStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxSnapshotStoreHash();

  @$internal
  @override
  $ProviderElement<InboxSnapshotStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InboxSnapshotStore create(Ref ref) {
    return inboxSnapshotStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InboxSnapshotStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InboxSnapshotStore>(value),
    );
  }
}

String _$inboxSnapshotStoreHash() =>
    r'b6d335d8942b945521e887fb3ab95b1c25ece209';
