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

/// Participants currently typing in this conversation, expired by the service.

@ProviderFor(typingUsers)
final typingUsersProvider = TypingUsersFamily._();

/// Participants currently typing in this conversation, expired by the service.

final class TypingUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          Stream<Map<String, String>>
        >
    with
        $FutureModifier<Map<String, String>>,
        $StreamProvider<Map<String, String>> {
  /// Participants currently typing in this conversation, expired by the service.
  TypingUsersProvider._({
    required TypingUsersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'typingUsersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$typingUsersHash();

  @override
  String toString() {
    return r'typingUsersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, String>> create(Ref ref) {
    final argument = this.argument as String;
    return typingUsers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TypingUsersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$typingUsersHash() => r'c3e0fc1e0d8cd43d767131c264156d210365ae29';

/// Participants currently typing in this conversation, expired by the service.

final class TypingUsersFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<String, String>>, String> {
  TypingUsersFamily._()
    : super(
        retry: null,
        name: r'typingUsersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Participants currently typing in this conversation, expired by the service.

  TypingUsersProvider call(String conversationId) =>
      TypingUsersProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'typingUsersProvider';
}

/// Members with this conversation open; this is not global online presence.

@ProviderFor(conversationPresence)
final conversationPresenceProvider = ConversationPresenceFamily._();

/// Members with this conversation open; this is not global online presence.

final class ConversationPresenceProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Map<String, dynamic>>>,
          Map<String, Map<String, dynamic>>,
          Stream<Map<String, Map<String, dynamic>>>
        >
    with
        $FutureModifier<Map<String, Map<String, dynamic>>>,
        $StreamProvider<Map<String, Map<String, dynamic>>> {
  /// Members with this conversation open; this is not global online presence.
  ConversationPresenceProvider._({
    required ConversationPresenceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'conversationPresenceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationPresenceHash();

  @override
  String toString() {
    return r'conversationPresenceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as String;
    return conversationPresence(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationPresenceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationPresenceHash() =>
    r'541646ad6ccc0a1cee0eb98b60cd3c8d4381274f';

/// Members with this conversation open; this is not global online presence.

final class ConversationPresenceFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<Map<String, Map<String, dynamic>>>,
          String
        > {
  ConversationPresenceFamily._()
    : super(
        retry: null,
        name: r'conversationPresenceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Members with this conversation open; this is not global online presence.

  ConversationPresenceProvider call(String conversationId) =>
      ConversationPresenceProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'conversationPresenceProvider';
}
