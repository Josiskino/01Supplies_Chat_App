// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_calls.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(agentCalls)
final agentCallsProvider = AgentCallsProvider._();

final class AgentCallsProvider
    extends
        $FunctionalProvider<
          AgentCallsSnapshot,
          AgentCallsSnapshot,
          AgentCallsSnapshot
        >
    with $Provider<AgentCallsSnapshot> {
  AgentCallsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agentCallsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agentCallsHash();

  @$internal
  @override
  $ProviderElement<AgentCallsSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AgentCallsSnapshot create(Ref ref) {
    return agentCalls(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AgentCallsSnapshot value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AgentCallsSnapshot>(value),
    );
  }
}

String _$agentCallsHash() => r'cbd23e655cecbbce9b7e44b74f8b18f0c3ed9025';

@ProviderFor(agentCallActions)
final agentCallActionsProvider = AgentCallActionsProvider._();

final class AgentCallActionsProvider
    extends
        $FunctionalProvider<
          AgentCallActions,
          AgentCallActions,
          AgentCallActions
        >
    with $Provider<AgentCallActions> {
  AgentCallActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agentCallActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agentCallActionsHash();

  @$internal
  @override
  $ProviderElement<AgentCallActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AgentCallActions create(Ref ref) {
    return agentCallActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AgentCallActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AgentCallActions>(value),
    );
  }
}

String _$agentCallActionsHash() => r'5f281b599d9a38f0377fec40d7efdf5e25704d79';

@ProviderFor(missedCallsSeenStore)
final missedCallsSeenStoreProvider = MissedCallsSeenStoreProvider._();

final class MissedCallsSeenStoreProvider
    extends
        $FunctionalProvider<
          MissedCallsSeenStore,
          MissedCallsSeenStore,
          MissedCallsSeenStore
        >
    with $Provider<MissedCallsSeenStore> {
  MissedCallsSeenStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'missedCallsSeenStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$missedCallsSeenStoreHash();

  @$internal
  @override
  $ProviderElement<MissedCallsSeenStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MissedCallsSeenStore create(Ref ref) {
    return missedCallsSeenStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MissedCallsSeenStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MissedCallsSeenStore>(value),
    );
  }
}

String _$missedCallsSeenStoreHash() =>
    r'c4624e7c8f5acc007e11c36ce2043c7ed1765044';

/// Last time the history was viewed; missed calls after it are "new".

@ProviderFor(MissedCallsSeen)
final missedCallsSeenProvider = MissedCallsSeenProvider._();

/// Last time the history was viewed; missed calls after it are "new".
final class MissedCallsSeenProvider
    extends $NotifierProvider<MissedCallsSeen, DateTime?> {
  /// Last time the history was viewed; missed calls after it are "new".
  MissedCallsSeenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'missedCallsSeenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$missedCallsSeenHash();

  @$internal
  @override
  MissedCallsSeen create() => MissedCallsSeen();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$missedCallsSeenHash() => r'6f487c57e689270d0143ee7559ab79635352168b';

/// Last time the history was viewed; missed calls after it are "new".

abstract class _$MissedCallsSeen extends $Notifier<DateTime?> {
  DateTime? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Missed calls since the history was last viewed, for the Calls badge.

@ProviderFor(missedCallsCount)
final missedCallsCountProvider = MissedCallsCountProvider._();

/// Missed calls since the history was last viewed, for the Calls badge.

final class MissedCallsCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Missed calls since the history was last viewed, for the Calls badge.
  MissedCallsCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'missedCallsCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$missedCallsCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return missedCallsCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$missedCallsCountHash() => r'946fd3276e937bb2cdc83fcb4bbc5e832d136e1f';
