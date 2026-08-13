import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_completed_provider.g.dart';

/// Indique si l'écran de démarrage a fini de jouer son animation.
///
/// Sans ce verrou, le splash ne serait jamais visible : `bootstrap()` précharge
/// les providers avant `runApp()`, donc le redirect de GoRouter tranche dès le
/// premier frame et quitte l'écran aussitôt.
///
/// `keepAlive` : le splash ne doit se jouer qu'une fois par lancement. En
/// auto-dispose, le démontage de l'écran remettrait le drapeau à `false` et
/// rejouerait l'animation à la première redirection suivante.
@Riverpod(keepAlive: true)
class SplashCompletedNotifier extends _$SplashCompletedNotifier {
  @override
  bool build() => false;

  void complete() {
    if (state) return;
    state = true;
  }
}
