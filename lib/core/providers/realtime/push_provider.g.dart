// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pushNotifications)
final pushNotificationsProvider = PushNotificationsProvider._();

final class PushNotificationsProvider
    extends
        $FunctionalProvider<
          PushNotificationService,
          PushNotificationService,
          PushNotificationService
        >
    with $Provider<PushNotificationService> {
  PushNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushNotificationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushNotificationsHash();

  @$internal
  @override
  $ProviderElement<PushNotificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PushNotificationService create(Ref ref) {
    return pushNotifications(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushNotificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushNotificationService>(value),
    );
  }
}

String _$pushNotificationsHash() => r'7b8d8d9e78b5e8b5ba4acf2aef0fecede52f86df';

@ProviderFor(pushRegistration)
final pushRegistrationProvider = PushRegistrationProvider._();

final class PushRegistrationProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  PushRegistrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushRegistrationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushRegistrationHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return pushRegistration(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$pushRegistrationHash() => r'51bdad499cd03a83c6c077e0308cbc27d1506e9f';

/// Routes only messages accepted by the active account's push session.

@ProviderFor(pushRoute)
final pushRouteProvider = PushRouteProvider._();

/// Routes only messages accepted by the active account's push session.

final class PushRouteProvider
    extends
        $FunctionalProvider<AsyncValue<PushRoute>, PushRoute, Stream<PushRoute>>
    with $FutureModifier<PushRoute>, $StreamProvider<PushRoute> {
  /// Routes only messages accepted by the active account's push session.
  PushRouteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushRouteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushRouteHash();

  @$internal
  @override
  $StreamProviderElement<PushRoute> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<PushRoute> create(Ref ref) {
    return pushRoute(ref);
  }
}

String _$pushRouteHash() => r'f6b9820a0061d77704860b568084e4a56c882797';
