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

/// Conversation actuellement à l'écran, s'il y en a une.
///
/// Provider distinct du service temps réel : l'écran de fil n'a qu'à déclarer
/// ce qu'il affiche, sans instancier la mécanique Pusher — ce qui la ferait
/// démarrer jusque dans les tests d'interface.

@ProviderFor(VisibleConversation)
final visibleConversationProvider = VisibleConversationProvider._();

/// Conversation actuellement à l'écran, s'il y en a une.
///
/// Provider distinct du service temps réel : l'écran de fil n'a qu'à déclarer
/// ce qu'il affiche, sans instancier la mécanique Pusher — ce qui la ferait
/// démarrer jusque dans les tests d'interface.
final class VisibleConversationProvider
    extends $NotifierProvider<VisibleConversation, String?> {
  /// Conversation actuellement à l'écran, s'il y en a une.
  ///
  /// Provider distinct du service temps réel : l'écran de fil n'a qu'à déclarer
  /// ce qu'il affiche, sans instancier la mécanique Pusher — ce qui la ferait
  /// démarrer jusque dans les tests d'interface.
  VisibleConversationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visibleConversationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visibleConversationHash();

  @$internal
  @override
  VisibleConversation create() => VisibleConversation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$visibleConversationHash() =>
    r'5c24a5e0bc19f4900ad14db1558bfab6749dcac6';

/// Conversation actuellement à l'écran, s'il y en a une.
///
/// Provider distinct du service temps réel : l'écran de fil n'a qu'à déclarer
/// ce qu'il affiche, sans instancier la mécanique Pusher — ce qui la ferait
/// démarrer jusque dans les tests d'interface.

abstract class _$VisibleConversation extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Flux des messages reçus hors du fil affiché.
///
/// Exposé en provider pour que l'écouteur d'interface s'y abonne sans connaître
/// le service, et que le lien se défasse avec l'arbre de widgets.

@ProviderFor(incomingMessage)
final incomingMessageProvider = IncomingMessageProvider._();

/// Flux des messages reçus hors du fil affiché.
///
/// Exposé en provider pour que l'écouteur d'interface s'y abonne sans connaître
/// le service, et que le lien se défasse avec l'arbre de widgets.

final class IncomingMessageProvider
    extends
        $FunctionalProvider<
          AsyncValue<IncomingMessage>,
          IncomingMessage,
          Stream<IncomingMessage>
        >
    with $FutureModifier<IncomingMessage>, $StreamProvider<IncomingMessage> {
  /// Flux des messages reçus hors du fil affiché.
  ///
  /// Exposé en provider pour que l'écouteur d'interface s'y abonne sans connaître
  /// le service, et que le lien se défasse avec l'arbre de widgets.
  IncomingMessageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'incomingMessageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$incomingMessageHash();

  @$internal
  @override
  $StreamProviderElement<IncomingMessage> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<IncomingMessage> create(Ref ref) {
    return incomingMessage(ref);
  }
}

String _$incomingMessageHash() => r'2ba5dae10a17b3ad20c7921cce6f04bd9dee11f8';
