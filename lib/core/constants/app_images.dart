/// Chemins des assets images.
class AppImages {
  AppImages._();

  static const String appIcon = 'assets/icon/app_icon.png';

  /// Fond de l'écran de connexion, cadré en portrait (2:3).
  ///
  /// En JPEG et non en PNG : l'image n'est faite que de dégradés, où le JPEG
  /// descend à 184 Ko contre 1,8 Mo, sans artefact visible.
  static const String authBackground = 'assets/images/auth_background.jpg';

  /// Variante paysage (3:2) du fond de connexion.
  ///
  /// Deux fichiers plutôt qu'un seul recadré : `BoxFit.cover` ne sait que
  /// rogner. Une composition portrait posée sur une fenêtre macOS n'en laisserait
  /// voir qu'une bande verticale, amputée de ses deux lobes.
  static const String authBackgroundWide =
      'assets/images/auth_background_wide.jpg';
}
