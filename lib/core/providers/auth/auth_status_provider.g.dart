// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// État d'authentification consommé par le routeur.
///
/// Il porte le **statut** seul — authentifié ou non — et laisse [AuthGate] seul
/// décideur des redirections. L'identité du connecté vit dans
/// `currentUserProvider` : le routeur n'en a pas besoin, les écrans si.
///
/// Le refus d'un compte non autorisé (client, vendeur) n'est pas traité ici mais
/// dans le repository, qui seul connaît le rôle renvoyé par le serveur.
///
/// `keepAlive` est indispensable : l'état de session est global. En auto-dispose,
/// il serait détruit dès que plus personne ne l'écoute, puis relu au prochain
/// accès — la restauration asynchrone se terminerait alors sur un provider déjà
/// disposé, et le statut repartirait à `initial` à chaque changement d'écran.

@ProviderFor(AuthStatusNotifier)
final authStatusProvider = AuthStatusNotifierProvider._();

/// État d'authentification consommé par le routeur.
///
/// Il porte le **statut** seul — authentifié ou non — et laisse [AuthGate] seul
/// décideur des redirections. L'identité du connecté vit dans
/// `currentUserProvider` : le routeur n'en a pas besoin, les écrans si.
///
/// Le refus d'un compte non autorisé (client, vendeur) n'est pas traité ici mais
/// dans le repository, qui seul connaît le rôle renvoyé par le serveur.
///
/// `keepAlive` est indispensable : l'état de session est global. En auto-dispose,
/// il serait détruit dès que plus personne ne l'écoute, puis relu au prochain
/// accès — la restauration asynchrone se terminerait alors sur un provider déjà
/// disposé, et le statut repartirait à `initial` à chaque changement d'écran.
final class AuthStatusNotifierProvider
    extends $NotifierProvider<AuthStatusNotifier, AuthGateStatus> {
  /// État d'authentification consommé par le routeur.
  ///
  /// Il porte le **statut** seul — authentifié ou non — et laisse [AuthGate] seul
  /// décideur des redirections. L'identité du connecté vit dans
  /// `currentUserProvider` : le routeur n'en a pas besoin, les écrans si.
  ///
  /// Le refus d'un compte non autorisé (client, vendeur) n'est pas traité ici mais
  /// dans le repository, qui seul connaît le rôle renvoyé par le serveur.
  ///
  /// `keepAlive` est indispensable : l'état de session est global. En auto-dispose,
  /// il serait détruit dès que plus personne ne l'écoute, puis relu au prochain
  /// accès — la restauration asynchrone se terminerait alors sur un provider déjà
  /// disposé, et le statut repartirait à `initial` à chaque changement d'écran.
  AuthStatusNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStatusNotifierHash();

  @$internal
  @override
  AuthStatusNotifier create() => AuthStatusNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthGateStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthGateStatus>(value),
    );
  }
}

String _$authStatusNotifierHash() =>
    r'3c356eb6ae155fc64e6180aec51c8b353b1f594b';

/// État d'authentification consommé par le routeur.
///
/// Il porte le **statut** seul — authentifié ou non — et laisse [AuthGate] seul
/// décideur des redirections. L'identité du connecté vit dans
/// `currentUserProvider` : le routeur n'en a pas besoin, les écrans si.
///
/// Le refus d'un compte non autorisé (client, vendeur) n'est pas traité ici mais
/// dans le repository, qui seul connaît le rôle renvoyé par le serveur.
///
/// `keepAlive` est indispensable : l'état de session est global. En auto-dispose,
/// il serait détruit dès que plus personne ne l'écoute, puis relu au prochain
/// accès — la restauration asynchrone se terminerait alors sur un provider déjà
/// disposé, et le statut repartirait à `initial` à chaque changement d'écran.

abstract class _$AuthStatusNotifier extends $Notifier<AuthGateStatus> {
  AuthGateStatus build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AuthGateStatus, AuthGateStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthGateStatus, AuthGateStatus>,
              AuthGateStatus,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
