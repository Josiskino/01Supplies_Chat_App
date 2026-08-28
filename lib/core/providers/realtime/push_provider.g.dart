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

String _$pushNotificationsHash() => r'7044b2f64b7a5730b888049d2b683885e5b2a0cd';

/// Enregistre l'appareil dès qu'une session s'ouvre.
///
/// Lié à l'authentification et non au démarrage : l'endpoint est authentifié, et
/// un jeton déposé sans session ne serait rattaché à aucun compte — l'appareil
/// resterait injoignable.

@ProviderFor(pushRegistration)
final pushRegistrationProvider = PushRegistrationProvider._();

/// Enregistre l'appareil dès qu'une session s'ouvre.
///
/// Lié à l'authentification et non au démarrage : l'endpoint est authentifié, et
/// un jeton déposé sans session ne serait rattaché à aucun compte — l'appareil
/// resterait injoignable.

final class PushRegistrationProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Enregistre l'appareil dès qu'une session s'ouvre.
  ///
  /// Lié à l'authentification et non au démarrage : l'endpoint est authentifié, et
  /// un jeton déposé sans session ne serait rattaché à aucun compte — l'appareil
  /// resterait injoignable.
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

String _$pushRegistrationHash() => r'a535c3ca04b2e436024a921b00c1bcc41da2c393';

/// Conversation à ouvrir suite au tap sur une notification.
///
/// Le message porte `conversationId` — même charge utile que celle routée par
/// l'app cliente. Sans cet aiguillage, toucher une notification ouvrirait
/// l'accueil, obligeant à retrouver la discussion à la main.

@ProviderFor(pushRoute)
final pushRouteProvider = PushRouteProvider._();

/// Conversation à ouvrir suite au tap sur une notification.
///
/// Le message porte `conversationId` — même charge utile que celle routée par
/// l'app cliente. Sans cet aiguillage, toucher une notification ouvrirait
/// l'accueil, obligeant à retrouver la discussion à la main.

final class PushRouteProvider
    extends
        $FunctionalProvider<AsyncValue<PushRoute>, PushRoute, Stream<PushRoute>>
    with $FutureModifier<PushRoute>, $StreamProvider<PushRoute> {
  /// Conversation à ouvrir suite au tap sur une notification.
  ///
  /// Le message porte `conversationId` — même charge utile que celle routée par
  /// l'app cliente. Sans cet aiguillage, toucher une notification ouvrirait
  /// l'accueil, obligeant à retrouver la discussion à la main.
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

String _$pushRouteHash() => r'f995d01f4cf41d357f8ddd182d2886fc5b97346c';
