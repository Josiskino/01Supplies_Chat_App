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
import '../../presentation/pages/conversation_detail/conversation_detail_screen.dart';
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
      // Les trois écrans du cycle de session (splash → login → coquille) sont
      // enchaînés par un fondu et non par la transition par défaut. Ce n'est pas
      // une navigation hiérarchique : personne ne « pousse » le login sur le
      // splash, c'est l'état de session qui change sous les pieds de
      // l'utilisateur. Un glissement latéral — ou pire, la bascule sèche du
      // desktop — donne l'impression d'un écran arraché.
      GoRoute(
        path: AppUiRoute.splash,
        pageBuilder: (context, state) => AppPageTransitions.session(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppUiRoute.login,
        pageBuilder: (context, state) => AppPageTransitions.session(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),

      // Coquille de navigation. Route **plate**, pas un ShellRoute : les onglets
      // vivent dans un IndexedStack piloté par `mainTabProvider`, ce qui préserve
      // leur état et suit la convention des autres apps du dépôt.
      GoRoute(
        path: AppUiRoute.main,
        pageBuilder: (context, state) => AppPageTransitions.session(
          key: state.pageKey,
          child: const MainPage(),
        ),
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

      // Fil de discussion. Poussé sur la pile plutôt que placé dans la coquille :
      // sur mobile, ouvrir une conversation doit masquer la barre d'onglets et
      // offrir un retour, comme dans toutes les messageries.
      GoRoute(
        path: AppUiRoute.conversationDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ConversationDetailScreen(
            conversationId: state.pathParameters['id'] ?? '',
            contactName: extra?['contactName'] as String?,
          );
        },
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

  /// Bascule de session : splash → login → coquille.
  ///
  /// Fondu accompagné d'une très légère montée d'échelle. La page entrante se
  /// superpose à la sortante, ce qui donne un fondu enchaîné plutôt qu'un
  /// remplacement — l'écran ne se vide jamais.
  ///
  /// Plus longue que les transitions ordinaires (420 ms) : un changement de
  /// session est un moment de rupture, pas un déplacement dans une pile. Trop
  /// courte, elle donne le « clac » que la bascule sèche produisait déjà.
  ///
  /// L'échelle part de 0,98 et non de 0,90 : au-delà de quelques pour cent, le
  /// mouvement se lit comme un zoom et attire l'œil sur la transition elle-même
  /// plutôt que sur l'écran qui arrive.
  static CustomTransitionPage<T> session<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
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
