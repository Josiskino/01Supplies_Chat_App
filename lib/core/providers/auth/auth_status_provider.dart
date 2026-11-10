import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/repository/auth/auth_repository.dart';
import '../../../domain/usecases/auth/auth_usecases.dart';
import '../../auth/auth_gate.dart';
import '../../services/api_client.dart';
import '../../utils/app_logger.dart';
import '../directory/directory_provider.dart';
import '../messaging/support_provider.dart';
import '../realtime/push_provider.dart';
import 'auth_provider.dart';

part 'auth_status_provider.g.dart';

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
@Riverpod(keepAlive: true)
class AuthStatusNotifier extends _$AuthStatusNotifier {
  @override
  AuthGateStatus build() {
    // L'interceptor force la déconnexion quand le refresh token est mort. Sans
    // ce branchement, l'app resterait sur un écran authentifié avec une session
    // invalide et échouerait à chaque requête.
    onAuthInterceptorFailure = () {
      if (state != AuthGateStatus.unauthenticated) {
        AppLogger().auth('session', 'Refresh impossible, session fermée');
        state = AuthGateStatus.unauthenticated;
      }
    };
    ref.onDispose(() => onAuthInterceptorFailure = null);

    Future.microtask(_restoreSession);
    return AuthGateStatus.initial;
  }

  /// Message du dernier échec de connexion, à afficher sous le formulaire.
  ///
  /// Porté ici plutôt que renvoyé par [signIn] : l'écran doit pouvoir le
  /// réafficher après une reconstruction, ce qu'une valeur de retour ne permet
  /// pas.
  String? lastError;

  Future<void> _restoreSession() async {
    final result = await ref
        .read(restoreSessionUseCaseProvider)
        .call(const RestoreSessionParams());
    // Le provider peut avoir été invalidé pendant la lecture du stockage :
    // écrire `state` après coup lèverait une exception non capturée.
    if (!ref.mounted) return;

    final session = result.getOrElse((_) => null);
    if (session == null) {
      state = AuthGateStatus.unauthenticated;
      return;
    }
    ref.read(currentUserProvider.notifier).set(session.user);
    state = AuthGateStatus.authenticated;
  }

  /// Ouvre une session contre l'API.
  ///
  /// Renvoie `true` en cas de succès. L'échec laisse le statut à
  /// `unauthenticated` et renseigne [lastError] — y compris pour un compte
  /// valide mais non autorisé, cas que le repository distingue par un
  /// `ForbiddenFailure`.
  Future<bool> signIn({required String email, required String password}) async {
    if (state == AuthGateStatus.loading) return false;
    state = AuthGateStatus.loading;
    lastError = null;

    final result = await ref
        .read(signInUseCaseProvider)
        .call(SignInParams(email: email, password: password));

    if (!ref.mounted) return false;

    // `fold` ne convient pas ici : la branche de succès doit attendre l'écriture
    // du stockage, et une lambda asynchrone y rendrait un `Future` d'un côté et
    // un `bool` de l'autre.
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      AppLogger().auth('signIn', 'Échec : ${failure.runtimeType}');
      lastError = failure.message;
      state = AuthGateStatus.unauthenticated;
      return false;
    }

    final session = result.getRight().toNullable()!;
    // La session n'est écrite qu'une fois le rôle validé : le repository a
    // refusé les comptes non autorisés avant d'arriver ici.
    await ref.read(authRepositoryProvider).persist(session);
    if (!ref.mounted) return false;

    ref.read(currentUserProvider.notifier).set(session.user);
    AppLogger().auth(
      'signIn',
      'Session ouverte (${session.user.role?.wireName})',
    );
    _resetSessionData();
    state = AuthGateStatus.authenticated;
    return true;
  }

  Future<void> signOut() async {
    // Revoke push ownership while the authenticated request can still succeed.
    try {
      await ref.read(pushNotificationsProvider).setSession(null);
    } catch (error) {
      AppLogger().error(
        'Push cleanup failed during sign-out',
        feature: 'Push',
        error: error,
      );
    }
    if (!ref.mounted) return;
    await ref.read(signOutUseCaseProvider).call(const SignOutParams());
    if (!ref.mounted) return;
    ref.read(currentUserProvider.notifier).set(null);
    _resetSessionData();
    state = AuthGateStatus.unauthenticated;
  }

  /// Vide les caches liés à la session précédente.
  ///
  /// Sans cela, les providers de données construits **avant** l'ouverture de
  /// session gardent leur échec 401 : l'écran des conversations est déjà monté
  /// dans l'`IndexedStack` quand le routeur redirige vers la connexion, ses
  /// tentatives échouent faute de jeton, et Riverpod finit par épuiser ses
  /// relances. Rien ne les relancerait après le login, et la liste resterait
  /// bloquée sur « Session expirée ». Le miroir vaut à la déconnexion : les
  /// données du compte sortant ne doivent pas survivre au suivant.
  void _resetSessionData() {
    ref.invalidate(supportQueueProvider);
    ref.invalidate(contactsProvider);
  }
}
