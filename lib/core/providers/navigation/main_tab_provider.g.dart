// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main_tab_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Onglet actif de la coquille principale.
///
/// Extrait dans son propre fichier — sur l'app cliente, l'équivalent est défini
/// au milieu du provider de panier, ce qui le rend introuvable. Il vit ici parce
/// que plusieurs écrans doivent pouvoir changer d'onglet à distance (une
/// notification de message ouvre l'onglet Conversations, par exemple).
///
/// `keepAlive` : l'onglet actif doit survivre à la navigation vers un écran hors
/// coquille. En auto-dispose, revenir des réglages ramènerait sur le premier
/// onglet au lieu de celui qu'on avait quitté.

@ProviderFor(MainTabNotifier)
final mainTabProvider = MainTabNotifierProvider._();

/// Onglet actif de la coquille principale.
///
/// Extrait dans son propre fichier — sur l'app cliente, l'équivalent est défini
/// au milieu du provider de panier, ce qui le rend introuvable. Il vit ici parce
/// que plusieurs écrans doivent pouvoir changer d'onglet à distance (une
/// notification de message ouvre l'onglet Conversations, par exemple).
///
/// `keepAlive` : l'onglet actif doit survivre à la navigation vers un écran hors
/// coquille. En auto-dispose, revenir des réglages ramènerait sur le premier
/// onglet au lieu de celui qu'on avait quitté.
final class MainTabNotifierProvider
    extends $NotifierProvider<MainTabNotifier, int> {
  /// Onglet actif de la coquille principale.
  ///
  /// Extrait dans son propre fichier — sur l'app cliente, l'équivalent est défini
  /// au milieu du provider de panier, ce qui le rend introuvable. Il vit ici parce
  /// que plusieurs écrans doivent pouvoir changer d'onglet à distance (une
  /// notification de message ouvre l'onglet Conversations, par exemple).
  ///
  /// `keepAlive` : l'onglet actif doit survivre à la navigation vers un écran hors
  /// coquille. En auto-dispose, revenir des réglages ramènerait sur le premier
  /// onglet au lieu de celui qu'on avait quitté.
  MainTabNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mainTabProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mainTabNotifierHash();

  @$internal
  @override
  MainTabNotifier create() => MainTabNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$mainTabNotifierHash() => r'4a455512bbf916dd994672934eaa5e6350c2e63b';

/// Onglet actif de la coquille principale.
///
/// Extrait dans son propre fichier — sur l'app cliente, l'équivalent est défini
/// au milieu du provider de panier, ce qui le rend introuvable. Il vit ici parce
/// que plusieurs écrans doivent pouvoir changer d'onglet à distance (une
/// notification de message ouvre l'onglet Conversations, par exemple).
///
/// `keepAlive` : l'onglet actif doit survivre à la navigation vers un écran hors
/// coquille. En auto-dispose, revenir des réglages ramènerait sur le premier
/// onglet au lieu de celui qu'on avait quitté.

abstract class _$MainTabNotifier extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
