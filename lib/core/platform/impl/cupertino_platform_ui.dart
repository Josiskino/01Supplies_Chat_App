import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
// Import ciblé : ce fichier reste volontairement Cupertino, on n'emprunte à
// Material que le conteneur exigé par les widgets partagés.
import 'package:flutter/material.dart' show Material, MaterialType;

import '../../../presentation/main/widgets/custom_bottom_nav_bar_item.dart';
import '../../../presentation/main/widgets/custom_nav_rail.dart';
import '../app_platform.dart';
import '../platform_ui.dart';

/// Rendu Cupertino, cible iOS.
///
/// S'appuie sur `adaptive_platform_ui` pour la coquille et la tab bar : le package
/// sait déléguer à la vraie `UITabBar` d'UIKit sur iOS 26+, ce qu'aucun widget
/// Flutter ne reproduit fidèlement (effet de verre, repli au défilement).
///
/// **Le package est confiné à ce fichier.** C'est délibéré, pour trois raisons
/// concrètes : il est en `0.1.x` avec une API qui évolue vite, il ne déclare pas
/// de support macOS/Windows, et sa détection de plateforme (`PlatformInfo`) lit
/// `dart:io` en statique donc n'est pas surchargeable en test. Toute évolution de
/// son API se répare ici, pas dans les écrans.
class CupertinoPlatformUi implements PlatformUi {
  const CupertinoPlatformUi();

  @override
  AppPlatform get platform => AppPlatform.ios;

  @override
  PlatformShell get shell => const CupertinoShell();

  @override
  PlatformControls get controls => const CupertinoControls();

  @override
  PlatformOverlays get overlays => const CupertinoOverlays();

  @override
  PlatformMotion get motion => const CupertinoMotion();
}

class CupertinoShell implements PlatformShell {
  const CupertinoShell();

  @override
  Widget buildShell({
    Key? key,
    required PlatformLayout layout,
    required Widget body,
    required List<PlatformDestination> destinations,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    Color? backgroundColor,
  }) {
    // Sur iPad large, la tab bar d'iPhone étirée serait un défaut d'interface :
    // on passe au rail, comme les apps iPadOS natives.
    if (layout.usesLateralNavigation) {
      return CupertinoPageScaffold(
        key: key,
        backgroundColor: backgroundColor,
        child: Row(
          children: [
            CustomNavRail(
              selectedTab: selectedIndex,
              children: [
                for (final d in destinations)
                  CustomBottomAppBarItem(
                    icon: d.cupertinoIcon ?? d.icon,
                    selectedIcon: d.cupertinoSelectedIcon ?? d.selectedIcon,
                    text: d.label,
                    badgeCount: d.badgeCount,
                    itemKey: d.key,
                  ),
              ],
              onTap: onSelected,
              extended: layout.isExpanded,
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    // `Builder` : les couleurs d'icônes doivent être lues dans le thème, et
    // `buildShell` ne reçoit pas de `BuildContext`.
    return Builder(
      builder: (context) => AdaptiveScaffold(
        key: key,
        // Le package pose un voile clair sous sa barre d'outils et un flou derrière
        // la tab bar. Sur un fond d'app coloré, ces deux effets se voient comme des
        // rectangles blancs qui ne correspondent à rien — d'autant que la barre
        // native apporte déjà son propre matériau.
        enableToolbarGradient: false,
        enableBlur: false,
        // `AdaptiveScaffold` n'expose pas de couleur de fond : on la pose sous le
        // corps. Sans cela, le paramètre serait accepté puis ignoré, et le fond
        // divergerait silencieusement de celui du rendu Material.
        //
        // Le contenu s'étend **sous** la tab bar, il n'est pas rogné au-dessus.
        //
        // C'est tout l'intérêt du verre d'iOS 26 : la barre laisse voir ce qui
        // défile dessous. La couper au ras de la barre ne lui laisse qu'un aplat
        // uni à diffuser, et elle paraît alors simplement blanche.
        //
        // La place nécessaire est donc annoncée via le `MediaQuery` — comme le fait
        // le package pour la barre du haut — et les listes la consomment en marge
        // **interne**. Le dernier message reste ainsi atteignable tout en glissant
        // sous le verre pendant le défilement.
        body: _withBackground(
          _withMaterial(
            Builder(
              builder: (context) {
                final mq = MediaQuery.of(context);
                return MediaQuery(
                  data: mq.copyWith(
                    padding: mq.padding.copyWith(
                      bottom: mq.padding.bottom + _floatingTabBarHeight,
                    ),
                  ),
                  child: body,
                );
              },
            ),
          ),
          backgroundColor,
        ),
        bottomNavigationBar: AdaptiveBottomNavigationBar(
          // Active la tab bar UIKit quand la version d'iOS le permet ; le package
          // retombe seul sur du Cupertino classique sinon.
          useNativeBottomBar: true,
          // Les couleurs d'icônes sont, elles, bien transmises au natif.
          selectedItemColor: CupertinoTheme.of(context).primaryColor,
          unselectedItemColor: CupertinoColors.systemGrey,
          selectedIndex: selectedIndex,
          onTap: onSelected,
          items: [
            for (final d in destinations)
              AdaptiveNavigationDestination(
                // `icon` est `dynamic` : un nom de SF Symbol donne le rendu natif
                // sur iOS 26+. En repli, on prend l'icône **Cupertino** et non
                // l'icône Material — un jeu d'icônes étranger à la plateforme se
                // remarque immédiatement sur iOS.
                icon: d.sfSymbol ?? d.cupertinoIcon ?? d.icon,
                selectedIcon:
                    d.selectedSfSymbol ??
                    d.cupertinoSelectedIcon ??
                    d.selectedIcon,
                label: d.label,
                badgeCount: d.badgeCount > 0 ? d.badgeCount : null,
                // Détache la destination dans sa propre pastille à droite.
                isSearch: d.isSearch,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildPage({
    Key? key,
    required String title,
    required Widget body,
    Widget? titleWidget,
    List<PlatformAction> actions = const [],
    Color? backgroundColor,
    bool resizeToAvoidBottomInset = true,
  }) {
    return AdaptiveScaffold(
      key: key,
      enableToolbarGradient: false,
      enableBlur: false,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: AdaptiveAppBar(
        title: title,
        titleWidget: titleWidget,
        // La barre native ne sait pas héberger un widget Flutter : dès qu'un
        // titre riche est demandé, on repasse sur la barre Cupertino.
        useNativeToolbar: titleWidget == null,
        actions: actions.isEmpty
            ? null
            : [
                for (final action in actions)
                  AdaptiveAppBarAction(
                    // `iosSymbol` alimente le vrai UIBarButtonItem sur iOS 26+ ;
                    // `icon` reste le repli pour les versions antérieures.
                    iosSymbol: action.sfSymbol,
                    icon: action.icon,
                    // `title` n'est volontairement pas transmis : le package
                    // l'affiche a la place de l'icone, ce qui remplacait le
                    // bouton par son libelle en toutes lettres.
                    onPressed: action.onPressed,
                  ),
              ],
      ),
      // `SafeArea` et **non** un padding calculé à la main.
      //
      // `AdaptiveScaffold` ajoute déjà la hauteur de la barre d'outils au
      // `MediaQuery.padding.top` du body — il le documente dans son propre code.
      // Un padding manuel s'y ajoutait donc, ce qui doublait l'espace sous le
      // titre. `SafeArea` consomme exactement ce que le scaffold a déclaré, ni
      // plus ni moins.
      body: SafeArea(
        top: true,
        bottom: false,
        child: _withBackground(_withMaterial(body), backgroundColor),
      ),
    );
  }

  /// Hauteur de la tab bar flottante, marge de détachement comprise.
  ///
  /// Ajoutée au `MediaQuery.padding.bottom` du corps de page : les listes s'en
  /// servent comme marge interne, sans que le contenu cesse de défiler dessous.
  static const double _floatingTabBarHeight = 64;

  /// Fournit un ancêtre `Material` transparent.
  ///
  /// La coquille Cupertino n'en contient aucun, alors que `TextField`, `InkWell`
  /// ou `Tooltip` en exigent un — d'ou le « No Material widget found » des qu'un
  /// ecran partage entre les plateformes en utilise un. `MaterialType.transparency`
  /// ne peint rien : il ne fait qu'exister dans l'arbre.
  static Widget _withMaterial(Widget child) =>
      Material(type: MaterialType.transparency, child: child);

  /// Applique une couleur de fond sous [child].
  ///
  /// `AdaptiveScaffold` ne prend pas de couleur de fond ; sans ce repli, la teinte
  /// définie par l'appelant serait perdue sur iOS uniquement — le genre d'écart
  /// qu'on ne remarque qu'en comparant deux appareils côte à côte.
  static Widget _withBackground(Widget child, Color? color) {
    if (color == null) return child;
    return ColoredBox(color: color, child: child);
  }
}

class CupertinoControls implements PlatformControls {
  const CupertinoControls();

  @override
  Widget switchToggle({
    Key? key,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return AdaptiveSwitch(key: key, value: value, onChanged: onChanged);
  }

  @override
  Widget textField({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? placeholder,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    ValueChanged<String>? onSubmitted,
  }) {
    return AdaptiveTextField(
      key: key,
      controller: controller,
      // iOS n'a pas de libellé flottant : le label devient le placeholder.
      placeholder: placeholder ?? label,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
    );
  }

  @override
  Widget primaryButton({
    Key? key,
    required Widget child,
    required VoidCallback? onPressed,
  }) {
    // Le constructeur par défaut n'accepte qu'un libellé texte ; `.child` est
    // nécessaire pour laisser passer un indicateur de chargement.
    return AdaptiveButton.child(key: key, onPressed: onPressed, child: child);
  }

  @override
  Widget progressIndicator({Key? key, Color? color, double? size}) {
    final indicator = CupertinoActivityIndicator(key: key, color: color);
    if (size == null) return indicator;
    return SizedBox(width: size, height: size, child: indicator);
  }
}

class CupertinoOverlays implements PlatformOverlays {
  @override
  Future<int?> pickOption({
    required BuildContext context,
    required String title,
    required List<String> labels,
    int? selectedIndex,
  }) {
    // Feuille d'actions remontant du bas : la présentation d'iOS pour un choix
    // court. Au-delà d'une poignée d'options, le système attend une sous-page —
    // les réglages de cette app n'en ont pas.
    return showCupertinoModalPopup<int>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(title),
        actions: [
          for (var i = 0; i < labels.length; i++)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop(i),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(labels[i]),
                  if (i == selectedIndex) ...[
                    const SizedBox(width: 8),
                    const Icon(CupertinoIcons.check_mark, size: 18),
                  ],
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Annuler'),
        ),
      ),
    );
  }

  const CupertinoOverlays();

  @override
  Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool isDestructive = false,
  }) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  void notify({
    required BuildContext context,
    required String message,
    bool isError = false,
  }) {
    // iOS n'a pas de snackbar : le package rend une bannière conforme aux
    // conventions de la plateforme.
    AdaptiveSnackBar.show(
      context,
      message: message,
      type: isError ? AdaptiveSnackBarType.error : AdaptiveSnackBarType.info,
    );
  }

  @override
  Widget contextMenu({
    Key? key,
    required Widget child,
    required List<PlatformMenuAction> actions,
  }) {
    // `AdaptiveContextMenu` reproduit le menu contextuel d'iOS : appui long, flou
    // de l'arrière-plan, aperçu agrandi de l'élément, puis la liste d'actions. Le
    // reproduire à la main demanderait un `Hero`, un `BackdropFilter` et une
    // animation d'échelle — pour un résultat toujours approximatif.
    return AdaptiveContextMenu(
      key: key,
      actions: [
        for (final action in actions)
          AdaptiveContextMenuAction(
            title: action.label,
            icon: action.icon,
            isDestructive: action.isDestructive,
            onPressed: action.onPressed,
          ),
      ],
      // Largeur bornée obligatoire.
      //
      // `CupertinoContextMenu` extrait le contenu de son parent pour l'animer en
      // overlay. Une ligne de liste bâtie sur un `Row` avec des `Expanded` y perd
      // ses contraintes de largeur, et la mise en page échoue — l'appui long fait
      // alors planter l'écran. Fixer la largeur à celle de la fenêtre reproduit
      // ce que la ligne avait dans la liste.
      child: Builder(
        builder: (context) =>
            SizedBox(width: MediaQuery.sizeOf(context).width, child: child),
      ),
    );
  }
}

class CupertinoMotion implements PlatformMotion {
  const CupertinoMotion();

  @override
  Duration get pageTransitionDuration => const Duration(milliseconds: 400);

  @override
  Widget buildPageTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) {
    // `CupertinoPageTransition` plutôt qu'un slide approché : on récupère la
    // courbe exacte du système et le décalage de la page sortante.
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: false,
      child: child,
    );
  }
}
