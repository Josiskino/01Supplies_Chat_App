// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Draft text survives navigation and is reset whenever the account changes.

@ProviderFor(MessageDraft)
final messageDraftProvider = MessageDraftFamily._();

/// Draft text survives navigation and is reset whenever the account changes.
final class MessageDraftProvider
    extends $NotifierProvider<MessageDraft, String> {
  /// Draft text survives navigation and is reset whenever the account changes.
  MessageDraftProvider._({
    required MessageDraftFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'messageDraftProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageDraftHash();

  @override
  String toString() {
    return r'messageDraftProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MessageDraft create() => MessageDraft();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MessageDraftProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageDraftHash() => r'c528b6567f3cd795f0490e86042e543e87fe6715';

/// Draft text survives navigation and is reset whenever the account changes.

final class MessageDraftFamily extends $Family
    with $ClassFamilyOverride<MessageDraft, String, String, String, String> {
  MessageDraftFamily._()
    : super(
        retry: null,
        name: r'messageDraftProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Draft text survives navigation and is reset whenever the account changes.

  MessageDraftProvider call(String conversationId) =>
      MessageDraftProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'messageDraftProvider';
}

/// Draft text survives navigation and is reset whenever the account changes.

abstract class _$MessageDraft extends $Notifier<String> {
  late final _$args = ref.$arg as String;
  String get conversationId => _$args;

  String build(String conversationId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
