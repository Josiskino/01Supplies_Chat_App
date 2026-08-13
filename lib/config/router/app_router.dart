import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_gate.dart';
import '../../core/constants/app_ui_route.dart';
import '../../core/providers/auth/auth_status_provider.dart';
import '../../core/providers/navigation/main_tab_provider.dart';
import '../../core/providers/splash_completed_provider.dart';
import '../../presentation/main/main_page.dart';
import '../../presentation/main/nav_destinations.dart';
import '../../presentation/pages/auth/login_screen.dart';
import '../../presentation/pages/auth/splash_screen.dart';
import '../../presentation/pages/settings/settings_screen.dart';
import '../../presentation/widgets/photo/image_viewer_widget.dart';

/// `Listenable` qui réveille GoRouter quand l'état dont dépend le `redirect`
/// change.
///
/// GoRouter ne réévalue pas ses redirections sur un rebuild Riverpod : sans ce
/// pont, une déconnexion laisserait l'utilisateur sur un écran protégé.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authStatusProvider, (_, _) => notifyListeners());
    // Sans cette écoute, la fin de l'animation du splash ne relancerait aucun
    // redirect et l'app resterait bloquée sur l'écran de démarrage.
    _ref.listen(splashCompletedProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppUiRoute.splash,
    refreshListenable: notifier,
    debugLogDiagnostics: kDebugMode,

    // Toute la décision est déléguée à une fonction pure, testable sans widget
    // tree ni conteneur Riverpod.
    redirect: (context, state) {
      return AuthGate.redirectFor(
        status: ref.read(authStatusProvider),
        location: state.uri.path,
        splashCompleted: ref.read(splashCompletedProvider),
      );
    },

    routes: [
      GoRoute(
        path: AppUiRoute.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppUiRoute.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Coquille de navigation. Route **plate**, pas un ShellRoute : les onglets
      // vivent dans un IndexedStack piloté par `mainTabProvider`, ce qui préserve
      // leur état et suit la convention des autres apps du dépôt.
      GoRoute(
        path: AppUiRoute.main,
        builder: (context, state) => const MainPage(),
        routes: [
          // Sous-routes d'onglet : elles n'ont pas d'écran propre, elles ne
          // servent qu'à cibler un onglet depuis un lien profond ou une
          // notification. Le `redirect` sélectionne l'onglet puis renvoie sur la
          // coquille.
          for (final destination in NavDestinations.all)
            GoRoute(
              path: destination.subPath,
              redirect: (context, state) {
                ref
                    .read(mainTabProvider.notifier)
                    .select(destination.index);
                return AppUiRoute.main;
              },
            ),
        ],
      ),

      GoRoute(
        path: AppUiRoute.settings,
        builder: (context, state) => const SettingsScreen(),
      ),

      // ── Overlay non opaque ──────────────────────────────────────────────
      // Une visionneuse d'image doit laisser voir la page en dessous pendant la
      // transition. `opaque: false` est le seul moyen de l'obtenir avec
      // GoRouter ; c'est aussi le pattern à reprendre pour les futurs overlays
      // de la messagerie (galerie de pièces jointes, aperçu de document).
      GoRoute(
        path: AppUiRoute.imageViewer,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? const {};
          return CustomTransitionPage<void>(
            key: state.pageKey,
            opaque: false,
            barrierColor: Colors.black,
            transitionDuration: const Duration(milliseconds: 280),
            reverseTransitionDuration: const Duration(milliseconds: 220),
            child: ImageViewerWidget(
              // Accepte indifféremment des URL distantes et des chemins de
              // fichiers locaux — utile dès qu'on affichera une pièce jointe
              // avant son envoi.
              imagePaths:
                  (extra['images'] as List?)?.cast<String>() ?? const [],
              initialIndex: extra['initialIndex'] as int? ?? 0,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ],
  );
});

/// Transitions réutilisables.
///
/// Reprises de l'app cliente, où elles corrigent des ruptures visuelles réelles.
/// Placées ici pour être appliquées d'emblée aux futurs écrans plutôt que
/// redécouvertes une fois le glissement latéral par défaut jugé gênant.
abstract final class AppPageTransitions {
  /// Fondu + légère montée. Pour un écran qui prolonge celui d'origine (ouvrir
  /// une recherche depuis une barre déjà à l'écran) : un glissement latéral
  /// romprait le lien entre l'élément touché et celui qui apparaît.
  static CustomTransitionPage<T> fadeUp<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Fondu simple, sans déplacement. Pour un contenu plein écran.
  static CustomTransitionPage<T> fade<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
}
