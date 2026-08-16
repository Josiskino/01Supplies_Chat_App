import '../constants/app_ui_route.dart';

/// État d'authentification vu par le routeur.
///
/// Distinct de l'état complet du ViewModel d'auth : le routeur n'a besoin que de
/// ces quatre cas, et cette réduction permet de tester les redirections sans
/// instancier la couche data.
enum AuthGateStatus {
  /// Le profil n'a pas encore été lu depuis le stockage local.
  initial,

  /// Un appel d'authentification est en cours.
  loading,

  /// Aucune session valide.
  unauthenticated,

  /// Session valide.
  authenticated,
}

/// Décide de la redirection à appliquer.
///
/// Fonction **pure** : aucune dépendance à Riverpod, à `BuildContext` ni au
/// réseau. C'est ce qui permet de couvrir la table de vérité complète par des
/// tests unitaires — sur l'app cliente, c'est le test qui a le plus de valeur
/// pour son coût.
///
/// Cette app est un outil interne : contrairement à l'app cliente, il n'y a
/// **aucun mode invité**. Tout écran hors de la pile d'authentification exige une
/// session.
class AuthGate {
  AuthGate._();

  /// Routes accessibles sans session.
  static const Set<String> publicRoutes = {AppUiRoute.splash, AppUiRoute.login};

  /// Renvoie la route vers laquelle rediriger, ou `null` pour laisser passer.
  static String? redirectFor({
    required AuthGateStatus status,
    required String location,
    bool splashCompleted = true,
  }) {
    final isSplash = location == AppUiRoute.splash;
    final isAuthPage = _isAuthPage(location);

    // Tant que l'animation du splash n'est pas terminée, on ne bouge pas :
    // les providers étant préchargés avant `runApp`, la destination est connue
    // dès le premier frame et l'écran serait traversé sans jamais être vu.
    if (isSplash && !splashCompleted) return null;

    // Statut indéterminé : on attend plutôt que de rediriger à tort.
    if (status == AuthGateStatus.initial ||
        (status == AuthGateStatus.loading && isSplash)) {
      return null;
    }

    if (status == AuthGateStatus.unauthenticated) {
      // Déjà sur une page publique : rien à faire, sauf quitter le splash.
      if (isSplash) return AppUiRoute.login;
      if (isAuthPage) return null;
      return AppUiRoute.login;
    }

    if (status == AuthGateStatus.authenticated) {
      // Un utilisateur connecté n'a rien à faire dans la pile d'auth.
      if (isAuthPage || isSplash) return AppUiRoute.main;
      return null;
    }

    return null;
  }

  /// `true` si la route exige une session.
  static bool isProtected(String location) => !_isPublic(location);

  static bool _isPublic(String location) => publicRoutes.contains(location);

  static bool _isAuthPage(String location) => location == AppUiRoute.login;
}
