import 'package:flutter/widgets.dart';

import '../responsive/breakpoints.dart';
import 'app_platform.dart';

/// Une destination de la navigation principale, exprimée sans dépendance à un
/// système de design.
///
/// Les implémentations la traduisent en élément de barre Material, en
/// `AdaptiveNavigationDestination` iOS ou en entrée de rail desktop. [sfSymbol]
/// n'est lu que par l'implémentation Apple, qui rend de vrais SF Symbols quand la
/// tab bar UIKit est active.
class PlatformDestination {
  const PlatformDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.cupertinoIcon,
    this.cupertinoSelectedIcon,
    this.sfSymbol,
    this.selectedSfSymbol,
    this.badgeCount = 0,
    this.isSearch = false,
    this.key,
  });

  final IconData icon;

  /// Variante affichée quand la destination est active.
  final IconData selectedIcon;

  /// Icônes Cupertino, utilisées sur Apple quand la barre native n'est pas
  /// disponible (iOS antérieur à 26, iPad en rail, rendu de secours).
  ///
  /// Sans elles, la barre retomberait sur les icônes Material : sur iOS, un jeu
  /// d'icônes étranger à la plateforme se remarque immédiatement.
  final IconData? cupertinoIcon;
  final IconData? cupertinoSelectedIcon;

  final String label;

  /// Nom du SF Symbol (ex. `message`). Ignoré hors Apple.
  final String? sfSymbol;

  /// Variante pleine du SF Symbol (ex. `message.fill`).
  final String? selectedSfSymbol;

  final int badgeCount;

  /// Destination de recherche.
  ///
  /// iOS 26 la détache du groupe et la place dans sa propre pastille, à droite de
  /// la barre — c'est la disposition de l'App Store. Les autres plateformes
  /// l'affichent comme une destination ordinaire.
  final bool isSearch;

  final Key? key;
}

/// Une action de barre de titre, exprimée sans dépendance à un système de design.
///
/// Le contrat ne transporte volontairement pas de `Widget` : un `IconButton`
/// Material passé à une barre de navigation iOS n'y a pas sa place, et
/// `adaptive_platform_ui` attend d'ailleurs son propre type d'action pour pouvoir
/// rendre un `UIBarButtonItem` natif.
class PlatformAction {
  const PlatformAction({
    required this.icon,
    required this.onPressed,
    this.sfSymbol,
    this.label,
  });

  final IconData icon;
  final VoidCallback onPressed;

  /// Nom du SF Symbol, pour la barre d'outils native iOS 26+.
  final String? sfSymbol;

  /// Libellé d'accessibilité, et texte du bouton quand la plateforme en affiche
  /// un plutôt qu'une icône.
  final String? label;
}

/// Une entrée de menu contextuel, exprimée sans dépendance à un système de
/// design.
class PlatformMenuAction {
  const PlatformMenuAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.sfSymbol,
    this.isDestructive = false,
    this.isSelected = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  /// Nom du SF Symbol, pour le menu natif iOS.
  final String? sfSymbol;

  /// Une action destructive est rendue en rouge sur les deux plateformes.
  final bool isDestructive;

  /// Coche l'entrée — un filtre actif, par exemple.
  final bool isSelected;
}

/// Contexte de décision passé aux implémentations.
///
/// Porte **les deux axes à la fois**. C'est indispensable : « iOS » et « iPad en
/// paysage » sont deux questions différentes, et une tab bar d'iPhone étirée sur
/// 1 300 px est un défaut d'interface, pas une adaptation.
class PlatformLayout {
  const PlatformLayout({required this.platform, required this.formFactor});

  /// Construit le contexte depuis une largeur disponible.
  factory PlatformLayout.of({
    required AppPlatform platform,
    required double width,
  }) => PlatformLayout(
    platform: platform,
    formFactor: Breakpoints.formFactorOf(width),
  );

  final AppPlatform platform;
  final FormFactor formFactor;

  bool get isCompact => formFactor == FormFactor.compact;
  bool get isExpanded => formFactor == FormFactor.expanded;

  /// La navigation passe sur le côté dès qu'on quitte le format compact.
  bool get usesLateralNavigation => !isCompact;
}

/// Coquille de l'application : structure de page et navigation principale.
///
/// La coquille est traitée comme **une unité** plutôt qu'en `scaffold()` +
/// `navigation()` séparés. Ce n'est pas un détail : `adaptive_platform_ui` expose
/// sa barre de navigation comme un objet de *configuration* passé au scaffold, et
/// non comme un widget composable. Un contrat qui renverrait la navigation
/// séparément interdirait d'utiliser la tab bar UIKit native.
abstract interface class PlatformShell {
  /// Écran principal : corps + navigation entre les destinations.
  Widget buildShell({
    Key? key,
    required PlatformLayout layout,
    required Widget body,
    required List<PlatformDestination> destinations,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    Color? backgroundColor,
  });

  /// Écran secondaire, poussé sur la pile : titre + corps, sans navigation
  /// principale.
  ///
  /// [titleWidget] remplace le titre texte quand l'en-tête doit porter davantage
  /// — un avatar et un nom cliquable, par exemple. C'est la seule entorse à la
  /// règle « pas de widget dans le contrat », et elle est assumée : il s'agit de
  /// *contenu*, pas d'un contrôle dont l'apparence dépend de la plateforme.
  Widget buildPage({
    Key? key,
    required String title,
    required Widget body,
    Widget? titleWidget,
    List<PlatformAction> actions,
    Color? backgroundColor,
    bool resizeToAvoidBottomInset,
  });
}

/// Contrôles de formulaire.
abstract interface class PlatformControls {
  Widget switchToggle({
    Key? key,
    required bool value,
    required ValueChanged<bool>? onChanged,
  });

  Widget textField({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? placeholder,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool obscureText,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    ValueChanged<String>? onSubmitted,
  });

  Widget primaryButton({
    Key? key,
    required Widget child,
    required VoidCallback? onPressed,
  });

  /// Indicateur d'activité (roue Material ou Cupertino).
  Widget progressIndicator({Key? key, Color? color, double? size});
}

/// Éléments transitoires : dialogues et messages.
abstract interface class PlatformOverlays {
  Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool isDestructive,
  });

  void notify({
    required BuildContext context,
    required String message,
    bool isError,
  });

  /// Demande de choisir une valeur parmi plusieurs, et renvoie son index.
  ///
  /// Les deux plateformes présentent cela très différemment — feuille d'actions
  /// remontant du bas sur iOS, feuille modale sur Android — pour une même
  /// question. C'est exactement le genre de divergence que le contrat absorbe,
  /// plutôt que de laisser chaque écran ouvrir le composant de son choix.
  ///
  /// Renvoie `null` si l'utilisateur referme sans choisir.
  Future<int?> pickOption({
    required BuildContext context,
    required String title,
    required List<String> labels,
    int? selectedIndex,
  });

  /// Enveloppe [child] d'un menu contextuel.
  ///
  /// Déclenché par un appui long sur mobile, par un clic droit sur desktop. Le
  /// rendu diffère radicalement : iOS floute l'arrière-plan et présente un aperçu
  /// agrandi de l'élément, Material ouvre un menu ancré au point de contact. C'est
  /// exactement le genre de divergence que l'abstraction doit absorber, plutôt que
  /// de laisser chaque écran l'improviser.
  Widget contextMenu({
    Key? key,
    required Widget child,
    required List<PlatformMenuAction> actions,
  });
}

/// Transitions de page.
abstract interface class PlatformMotion {
  Duration get pageTransitionDuration;

  Widget buildPageTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  });
}

/// Point d'entrée unique de l'adaptation par plateforme.
///
/// Agrège des contrats par domaine plutôt qu'une classe unique de quarante
/// méthodes : ajouter une plateforme n'oblige à réimplémenter que ce qui diverge
/// réellement, et l'implémentation desktop peut hériter de Material pour tout le
/// reste.
///
/// Résolu via `platformUiProvider`, surchargeable en test.
abstract interface class PlatformUi {
  AppPlatform get platform;

  PlatformShell get shell;
  PlatformControls get controls;
  PlatformOverlays get overlays;
  PlatformMotion get motion;
}
