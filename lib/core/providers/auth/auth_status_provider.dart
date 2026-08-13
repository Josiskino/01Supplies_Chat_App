import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/auth_gate.dart';
import '../../services/api_client.dart';
import '../../utils/app_logger.dart';
import '../../utils/preferences.dart';

part 'auth_status_provider.g.dart';

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

  Future<void> _restoreSession() async {
    final token = await SharedPreferencesHelper.getValue(StorageKeys.token);
    // Le provider peut avoir été invalidé pendant la lecture du stockage :
    // écrire `state` après coup lèverait une exception non capturée.
    if (!ref.mounted) return;
    state = token.isEmpty
        ? AuthGateStatus.unauthenticated
        : AuthGateStatus.authenticated;
  }

  /// Ouvre une session locale sans appel réseau.
  ///
  /// Sert uniquement à l'écran de connexion factice du socle, pour rendre la
  /// coquille de navigation atteignable et testable. À supprimer avec l'arrivée
  /// du vrai `LoginUseCase`.
  Future<void> signInPlaceholder() async {
    state = AuthGateStatus.loading;
    await SharedPreferencesHelper.setValue(
      StorageKeys.token,
      'placeholder-token',
    );
    state = AuthGateStatus.authenticated;
  }

  Future<void> signOut() async {
    await SharedPreferencesHelper.deleteValue(StorageKeys.token);
    await SharedPreferencesHelper.deleteValue(StorageKeys.tokenExpires);
    await SharedPreferencesHelper.deleteValue(StorageKeys.refreshToken);
    await SharedPreferencesHelper.deleteValue(StorageKeys.userProfile);
    state = AuthGateStatus.unauthenticated;
  }
}
