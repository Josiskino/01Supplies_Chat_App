import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';

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
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
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

    return AdaptiveScaffold(
      key: key,
      // `AdaptiveScaffold` n'expose pas de couleur de fond : on la pose sous le
      // corps. Sans cela, le paramètre serait accepté puis ignoré, et le fond
      // divergerait silencieusement de celui du rendu Material.
      body: _withBackground(body, backgroundColor),
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        // Active la tab bar UIKit quand la version d'iOS le permet ; le package
        // retombe seul sur du Cupertino classique sinon.
        useNativeBottomBar: true,
        selectedIndex: selectedIndex,
        onTap: onSelected,
        items: [
          for (final d in destinations)
            AdaptiveNavigationDestination(
              // `icon` est `dynamic` : un nom de SF Symbol donne le rendu natif,
              // et l'IconData reste le repli quand aucun symbole n'est fourni.
              icon: d.sfSymbol ?? d.icon,
              selectedIcon: d.selectedSfSymbol ?? d.selectedIcon,
              label: d.label,
              badgeCount: d.badgeCount > 0 ? d.badgeCount : null,
            ),
        ],
      ),
    );
  }

  @override
  Widget buildPage({
    Key? key,
    required String title,
    required Widget body,
    List<PlatformAction> actions = const [],
    Color? backgroundColor,
  }) {
    return AdaptiveScaffold(
      key: key,
      appBar: AdaptiveAppBar(
        title: title,
        useNativeToolbar: true,
        actions: actions.isEmpty
            ? null
            : [
                for (final action in actions)
                  AdaptiveAppBarAction(
                    // `iosSymbol` alimente le vrai UIBarButtonItem sur iOS 26+ ;
                    // `icon` reste le repli pour les versions antérieures.
                    iosSymbol: action.sfSymbol,
                    icon: action.icon,
                    title: action.label,
                    onPressed: action.onPressed,
                  ),
              ],
      ),
      body: _withBackground(body, backgroundColor),
    );
  }

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
    return AdaptiveButton.child(
      key: key,
      onPressed: onPressed,
      child: child,
    );
  }

  @override
  Widget progressIndicator({Key? key, Color? color, double? size}) {
    final indicator = CupertinoActivityIndicator(key: key, color: color);
    if (size == null) return indicator;
    return SizedBox(width: size, height: size, child: indicator);
  }
}

class CupertinoOverlays implements PlatformOverlays {
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
