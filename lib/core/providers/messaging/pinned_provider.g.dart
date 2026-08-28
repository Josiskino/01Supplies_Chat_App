// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pinned_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Conversations épinglées, gardées en tête de liste.
///
/// ## Stockage local
///
/// L'API n'expose aucun champ d'épinglage : `PATCH /conversations/{id}`
/// n'accepte que `name` et `description`, et la conversation n'en porte pas.
/// L'épinglage vit donc sur l'appareil.
///
/// Conséquence à connaître : ce qu'on épingle sur ce téléphone ne se retrouve
/// ni sur le web ni sur un autre appareil. Le jour où le backend l'exposera,
/// seul ce provider changera — les écrans lisent déjà un simple ensemble
/// d'identifiants.

@ProviderFor(PinnedConversations)
final pinnedConversationsProvider = PinnedConversationsProvider._();

/// Conversations épinglées, gardées en tête de liste.
///
/// ## Stockage local
///
/// L'API n'expose aucun champ d'épinglage : `PATCH /conversations/{id}`
/// n'accepte que `name` et `description`, et la conversation n'en porte pas.
/// L'épinglage vit donc sur l'appareil.
///
/// Conséquence à connaître : ce qu'on épingle sur ce téléphone ne se retrouve
/// ni sur le web ni sur un autre appareil. Le jour où le backend l'exposera,
/// seul ce provider changera — les écrans lisent déjà un simple ensemble
/// d'identifiants.
final class PinnedConversationsProvider
    extends $NotifierProvider<PinnedConversations, Set<String>> {
  /// Conversations épinglées, gardées en tête de liste.
  ///
  /// ## Stockage local
  ///
  /// L'API n'expose aucun champ d'épinglage : `PATCH /conversations/{id}`
  /// n'accepte que `name` et `description`, et la conversation n'en porte pas.
  /// L'épinglage vit donc sur l'appareil.
  ///
  /// Conséquence à connaître : ce qu'on épingle sur ce téléphone ne se retrouve
  /// ni sur le web ni sur un autre appareil. Le jour où le backend l'exposera,
  /// seul ce provider changera — les écrans lisent déjà un simple ensemble
  /// d'identifiants.
  PinnedConversationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinnedConversationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinnedConversationsHash();

  @$internal
  @override
  PinnedConversations create() => PinnedConversations();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$pinnedConversationsHash() =>
    r'72f2d80c966c3378cf33e4763a0ccb5d10562953';

/// Conversations épinglées, gardées en tête de liste.
///
/// ## Stockage local
///
/// L'API n'expose aucun champ d'épinglage : `PATCH /conversations/{id}`
/// n'accepte que `name` et `description`, et la conversation n'en porte pas.
/// L'épinglage vit donc sur l'appareil.
///
/// Conséquence à connaître : ce qu'on épingle sur ce téléphone ne se retrouve
/// ni sur le web ni sur un autre appareil. Le jour où le backend l'exposera,
/// seul ce provider changera — les écrans lisent déjà un simple ensemble
/// d'identifiants.

abstract class _$PinnedConversations extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
