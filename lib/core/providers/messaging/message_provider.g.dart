// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(messageDataSource)
final messageDataSourceProvider = MessageDataSourceProvider._();

final class MessageDataSourceProvider
    extends
        $FunctionalProvider<
          MessageDataSourceContract,
          MessageDataSourceContract,
          MessageDataSourceContract
        >
    with $Provider<MessageDataSourceContract> {
  MessageDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageDataSourceHash();

  @$internal
  @override
  $ProviderElement<MessageDataSourceContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessageDataSourceContract create(Ref ref) {
    return messageDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageDataSourceContract value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageDataSourceContract>(value),
    );
  }
}

String _$messageDataSourceHash() => r'f2cc340c34d393a8ea06d1497b5fcb3a44f22685';

@ProviderFor(messageRepository)
final messageRepositoryProvider = MessageRepositoryProvider._();

final class MessageRepositoryProvider
    extends
        $FunctionalProvider<
          MessageRepository,
          MessageRepository,
          MessageRepository
        >
    with $Provider<MessageRepository> {
  MessageRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageRepositoryHash();

  @$internal
  @override
  $ProviderElement<MessageRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessageRepository create(Ref ref) {
    return messageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageRepository>(value),
    );
  }
}

String _$messageRepositoryHash() => r'7ed54d0dbb395fd5226c8e1069ef7ec78e69fd70';

@ProviderFor(fetchMessagesUseCase)
final fetchMessagesUseCaseProvider = FetchMessagesUseCaseProvider._();

final class FetchMessagesUseCaseProvider
    extends
        $FunctionalProvider<
          FetchMessagesUseCase,
          FetchMessagesUseCase,
          FetchMessagesUseCase
        >
    with $Provider<FetchMessagesUseCase> {
  FetchMessagesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fetchMessagesUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fetchMessagesUseCaseHash();

  @$internal
  @override
  $ProviderElement<FetchMessagesUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FetchMessagesUseCase create(Ref ref) {
    return fetchMessagesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FetchMessagesUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FetchMessagesUseCase>(value),
    );
  }
}

String _$fetchMessagesUseCaseHash() =>
    r'a09ff566846432f10e63861ad9d9cc4d9f4205b9';

@ProviderFor(sendMessageUseCase)
final sendMessageUseCaseProvider = SendMessageUseCaseProvider._();

final class SendMessageUseCaseProvider
    extends
        $FunctionalProvider<
          SendMessageUseCase,
          SendMessageUseCase,
          SendMessageUseCase
        >
    with $Provider<SendMessageUseCase> {
  SendMessageUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendMessageUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendMessageUseCaseHash();

  @$internal
  @override
  $ProviderElement<SendMessageUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SendMessageUseCase create(Ref ref) {
    return sendMessageUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendMessageUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendMessageUseCase>(value),
    );
  }
}

String _$sendMessageUseCaseHash() =>
    r'e56155e39bbeba53404b58e71310a3dde0c18ce1';

@ProviderFor(markReadUseCase)
final markReadUseCaseProvider = MarkReadUseCaseProvider._();

final class MarkReadUseCaseProvider
    extends
        $FunctionalProvider<MarkReadUseCase, MarkReadUseCase, MarkReadUseCase>
    with $Provider<MarkReadUseCase> {
  MarkReadUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'markReadUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$markReadUseCaseHash();

  @$internal
  @override
  $ProviderElement<MarkReadUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MarkReadUseCase create(Ref ref) {
    return markReadUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarkReadUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarkReadUseCase>(value),
    );
  }
}

String _$markReadUseCaseHash() => r'a8fcf7320583b062a9f3e534392564e29d9495a5';

/// Le fil d'une conversation.
///
/// ## L'accès n'est pas acquis
///
/// Un admin qui n'a pas pris le dossier n'est **pas participant** : l'API
/// répond « Not a participant in this conversation ». C'est l'état normal d'un
/// ticket qui attend dans la file, et l'écran doit proposer de s'en saisir.

@ProviderFor(Thread)
final threadProvider = ThreadFamily._();

/// Le fil d'une conversation.
///
/// ## L'accès n'est pas acquis
///
/// Un admin qui n'a pas pris le dossier n'est **pas participant** : l'API
/// répond « Not a participant in this conversation ». C'est l'état normal d'un
/// ticket qui attend dans la file, et l'écran doit proposer de s'en saisir.
final class ThreadProvider extends $AsyncNotifierProvider<Thread, ThreadState> {
  /// Le fil d'une conversation.
  ///
  /// ## L'accès n'est pas acquis
  ///
  /// Un admin qui n'a pas pris le dossier n'est **pas participant** : l'API
  /// répond « Not a participant in this conversation ». C'est l'état normal d'un
  /// ticket qui attend dans la file, et l'écran doit proposer de s'en saisir.
  ThreadProvider._({
    required ThreadFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'threadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$threadHash();

  @override
  String toString() {
    return r'threadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Thread create() => Thread();

  @override
  bool operator ==(Object other) {
    return other is ThreadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$threadHash() => r'25bfcf036f813968d988021663638fafc232f86d';

/// Le fil d'une conversation.
///
/// ## L'accès n'est pas acquis
///
/// Un admin qui n'a pas pris le dossier n'est **pas participant** : l'API
/// répond « Not a participant in this conversation ». C'est l'état normal d'un
/// ticket qui attend dans la file, et l'écran doit proposer de s'en saisir.

final class ThreadFamily extends $Family
    with
        $ClassFamilyOverride<
          Thread,
          AsyncValue<ThreadState>,
          ThreadState,
          FutureOr<ThreadState>,
          String
        > {
  ThreadFamily._()
    : super(
        retry: null,
        name: r'threadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Le fil d'une conversation.
  ///
  /// ## L'accès n'est pas acquis
  ///
  /// Un admin qui n'a pas pris le dossier n'est **pas participant** : l'API
  /// répond « Not a participant in this conversation ». C'est l'état normal d'un
  /// ticket qui attend dans la file, et l'écran doit proposer de s'en saisir.

  ThreadProvider call(String conversationId) =>
      ThreadProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'threadProvider';
}

/// Le fil d'une conversation.
///
/// ## L'accès n'est pas acquis
///
/// Un admin qui n'a pas pris le dossier n'est **pas participant** : l'API
/// répond « Not a participant in this conversation ». C'est l'état normal d'un
/// ticket qui attend dans la file, et l'écran doit proposer de s'en saisir.

abstract class _$Thread extends $AsyncNotifier<ThreadState> {
  late final _$args = ref.$arg as String;
  String get conversationId => _$args;

  FutureOr<ThreadState> build(String conversationId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ThreadState>, ThreadState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ThreadState>, ThreadState>,
              AsyncValue<ThreadState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Identifiant du compte connecté, pour distinguer ses propres bulles.

@ProviderFor(currentUserId)
final currentUserIdProvider = CurrentUserIdProvider._();

/// Identifiant du compte connecté, pour distinguer ses propres bulles.

final class CurrentUserIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// Identifiant du compte connecté, pour distinguer ses propres bulles.
  CurrentUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return currentUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$currentUserIdHash() => r'9cf054843ce14026624a6e2145b887ab5165fec7';
