// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calls_sign_out.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden by the calls host when support calls are configured.

@ProviderFor(callsSignOut)
final callsSignOutProvider = CallsSignOutProvider._();

/// Overridden by the calls host when support calls are configured.

final class CallsSignOutProvider
    extends $FunctionalProvider<CallsSignOut, CallsSignOut, CallsSignOut>
    with $Provider<CallsSignOut> {
  /// Overridden by the calls host when support calls are configured.
  CallsSignOutProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callsSignOutProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callsSignOutHash();

  @$internal
  @override
  $ProviderElement<CallsSignOut> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CallsSignOut create(Ref ref) {
    return callsSignOut(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CallsSignOut value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CallsSignOut>(value),
    );
  }
}

String _$callsSignOutHash() => r'e8b968c8a90101a77715aa1dfae7987a23b3f597';
