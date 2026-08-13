/// Formats d'écran de l'application.
///
/// Nommage aligné sur les *window size classes* de Material 3, pour éviter
/// d'inventer un vocabulaire maison.
enum FormFactor {
  /// < 600 px — téléphone en portrait, fenêtre desktop très réduite.
  compact,

  /// 600–899 px — tablette en portrait, fenêtre desktop moyenne.
  medium,

  /// >= 900 px — desktop, tablette en paysage.
  expanded,
}

/// Seuils de bascule de mise en page.
///
/// Centralisés ici parce qu'ils sont lus en deux endroits au moins (la coquille
/// de navigation et les extensions de `BuildContext`) : deux jeux de valeurs
/// divergeraient au premier ajustement.
abstract final class Breakpoints {
  /// En dessous : barre de navigation en bas.
  static const double compactMax = 600.0;

  /// À partir de : rail latéral étendu (icône + libellé).
  static const double expandedMin = 900.0;

  static FormFactor formFactorOf(double width) {
    if (width < compactMax) return FormFactor.compact;
    if (width < expandedMin) return FormFactor.medium;
    return FormFactor.expanded;
  }

  /// La navigation passe sur le côté dès qu'on quitte le format compact.
  static bool usesLateralNavigation(double width) =>
      formFactorOf(width) != FormFactor.compact;

  /// Le rail n'affiche les libellés à côté des icônes qu'en format expanded ;
  /// en medium il reste replié pour préserver la largeur du contenu.
  static bool usesExtendedRail(double width) =>
      formFactorOf(width) == FormFactor.expanded;
}
