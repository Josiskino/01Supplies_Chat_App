import 'package:flutter/material.dart';

import '../../../config/theme/design_tokens.dart';
import '../app_platform.dart';
import '../platform_ui.dart';
import 'material_platform_ui.dart';

/// Rendu de bureau (macOS et Windows).
///
/// **Provisoire, en attente du design desktop dédié.** Hérite de l'implémentation
/// Material et ne surcharge que ce qui est déjà certain : pas de tab bar en bas,
/// transitions sobres, indicateurs plus petits. Le reste — densité, master-detail,
/// barre de titre — se branchera ici quand la maquette sera disponible, sans
/// toucher aux écrans.
///
/// `adaptive_platform_ui` n'est **pas** utilisé sur cette cible : il ne déclare
/// pas de support macOS/Windows et son rendu natif n'y est pas enregistré.
class DesktopPlatformUi extends MaterialPlatformUi {
  const DesktopPlatformUi(this._platform);

  /// Distingue macOS de Windows. Les deux partagent ce rendu aujourd'hui, mais la
  /// distinction est nécessaire dès qu'un raccourci clavier ou une barre de titre
  /// diverge.
  final AppPlatform _platform;

  @override
  AppPlatform get platform => _platform;

  @override
  PlatformShell get shell => const DesktopShell();

  @override
  PlatformControls get controls => const DesktopControls();

  @override
  PlatformMotion get motion => const DesktopMotion();
}

class DesktopShell extends MaterialShell {
  const DesktopShell();

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
    // Une fenêtre de bureau réduite sous 600 px repasse volontairement sur la
    // barre du bas : c'est la seule disposition tenable à cette largeur. On
    // délègue donc au comportement Material plutôt que de forcer le rail.
    return super.buildShell(
      key: key,
      layout: layout,
      body: body,
      destinations: destinations,
      selectedIndex: selectedIndex,
      onSelected: onSelected,
      backgroundColor: backgroundColor,
    );
  }
}

class DesktopControls extends MaterialControls {
  const DesktopControls();

  @override
  Widget progressIndicator({Key? key, Color? color, double? size}) {
    // Les indicateurs de bureau sont plus discrets : à la souris, un spinner de
    // taille tactile paraît disproportionné.
    return super.progressIndicator(
      key: key,
      color: color,
      size: size ?? DesignTokens.iconS,
    );
  }
}

class DesktopMotion extends MaterialMotion {
  const DesktopMotion();

  @override
  Duration get pageTransitionDuration => DesignTokens.durationFast;

  @override
  Widget buildPageTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) {
    // Fondu seul, sans déplacement. Sur desktop, un glissement de page imite un
    // geste tactile qui n'existe pas et alourdit une navigation faite au clic.
    return FadeTransition(opacity: animation, child: child);
  }
}
