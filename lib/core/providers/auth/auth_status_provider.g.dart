// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// État d'authentification consommé par le routeur.
///
/// **Portée volontairement réduite** : ce provider ne fait aucun appel réseau. Il
/// se contente de constater la présence d'un jeton en stockage local et de
/// réagir à l'échec de renouvellement signalé par l'interceptor.
///
/// La feature d'authentification complète (écran de connexion branché sur l'API,
/// profil utilisateur, rôles agent/admin) le remplacera par un vrai ViewModel
/// avec un état scellé. La forme de l'état exposé au routeur, en revanche, ne
/// changera pas : c'est [AuthGateStatus], et [AuthGate] reste l'unique décideur
/// des redirections.
///
/// `keepAlive` est indispensable : l'état de session est global. En auto-dispose,
/// il serait détruit dès que plus personne ne l'écoute, puis relu au prochain
/// accès — la restauration asynchrone se terminerait alors sur un provider déjà
/// disposé, et le statut repartirait à `initial` à chaque changement d'écran.

@ProviderFor(AuthStatusNotifier)
final authStatusProvider = AuthStatusNotifierProvider._();

/// État d'authentification consommé par le routeur.
///
/// **Portée volontairement réduite** : ce provider ne fait aucun appel réseau. Il
/// se contente de constater la présence d'un jeton en stockage local et de
/// réagir à l'échec de renouvellement signalé par l'interceptor.
///
/// La feature d'authentification complète (écran de connexion branché sur l'API,
/// profil utilisateur, rôles agent/admin) le remplacera par un vrai ViewModel
/// avec un état scellé. La forme de l'état exposé au routeur, en revanche, ne
/// changera pas : c'est [AuthGateStatus], et [AuthGate] reste l'unique décideur
/// des redirections.
///
/// `keepAlive` est indispensable : l'état de session est global. En auto-dispose,
/// il serait détruit dès que plus personne ne l'écoute, puis relu au prochain
/// accès — la restauration asynchrone se terminerait alors sur un provider déjà
/// disposé, et le statut repartirait à `initial` à chaque changement d'écran.
final class AuthStatusNotifierProvider
    extends $NotifierProvider<AuthStatusNotifier, AuthGateStatus> {
  /// État d'authentification consommé par le routeur.
  ///
  /// **Portée volontairement réduite** : ce provider ne fait aucun appel réseau. Il
  /// se contente de constater la présence d'un jeton en stockage local et de
  /// réagir à l'échec de renouvellement signalé par l'interceptor.
  ///
  /// La feature d'authentification complète (écran de connexion branché sur l'API,
  /// profil utilisateur, rôles agent/admin) le remplacera par un vrai ViewModel
  /// avec un état scellé. La forme de l'état exposé au routeur, en revanche, ne
  /// changera pas : c'est [AuthGateStatus], et [AuthGate] reste l'unique décideur
  /// des redirections.
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
    r'19c3b1450ee120321a7659008030fa9b65699536';

/// État d'authentification consommé par le routeur.
///
/// **Portée volontairement réduite** : ce provider ne fait aucun appel réseau. Il
/// se contente de constater la présence d'un jeton en stockage local et de
/// réagir à l'échec de renouvellement signalé par l'interceptor.
///
/// La feature d'authentification complète (écran de connexion branché sur l'API,
/// profil utilisateur, rôles agent/admin) le remplacera par un vrai ViewModel
/// avec un état scellé. La forme de l'état exposé au routeur, en revanche, ne
/// changera pas : c'est [AuthGateStatus], et [AuthGate] reste l'unique décideur
/// des redirections.
///
/// `keepAlive` est indispensable : l'état de session est global. En auto-dispose,
/// il serait détruit dès que plus personne ne l'écoute, puis relu au prochain
/// accès — la restauration asynchrone se terminerait alors sur un provider déjà
/// disposé, et le statut repartirait à `initial` à chaque changement d'écran.

abstract class _$AuthStatusNotifier extends $Notifier<AuthGateStatus> {
  AuthGateStatus build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AuthGateStatus, AuthGateStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthGateStatus, AuthGateStatus>,
              AuthGateStatus,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
