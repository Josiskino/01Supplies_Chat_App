// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realtime_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le pont temps réel, vivant tant que l'application tourne.
///
/// `keepAlive` : le service s'abonne au canal de l'utilisateur dès la connexion
/// et doit y rester même quand aucun écran ne l'observe — c'est ce qui fait
/// entrer une nouvelle demande dans la file pendant qu'on regarde un autre
/// onglet.

@ProviderFor(messageEvents)
final messageEventsProvider = MessageEventsProvider._();

/// Le pont temps réel, vivant tant que l'application tourne.
///
/// `keepAlive` : le service s'abonne au canal de l'utilisateur dès la connexion
/// et doit y rester même quand aucun écran ne l'observe — c'est ce qui fait
/// entrer une nouvelle demande dans la file pendant qu'on regarde un autre
/// onglet.

final class MessageEventsProvider
    extends
        $FunctionalProvider<
          MessageEventsService,
          MessageEventsService,
          MessageEventsService
        >
    with $Provider<MessageEventsService> {
  /// Le pont temps réel, vivant tant que l'application tourne.
  ///
  /// `keepAlive` : le service s'abonne au canal de l'utilisateur dès la connexion
  /// et doit y rester même quand aucun écran ne l'observe — c'est ce qui fait
  /// entrer une nouvelle demande dans la file pendant qu'on regarde un autre
  /// onglet.
  MessageEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageEventsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageEventsHash();

  @$internal
  @override
  $ProviderElement<MessageEventsService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessageEventsService create(Ref ref) {
    return messageEvents(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageEventsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageEventsService>(value),
    );
  }
}

String _$messageEventsHash() => r'd81627c54abde513a8f63231fdee60f3a8efa022';
