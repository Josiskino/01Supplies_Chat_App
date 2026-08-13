import 'package:flutter/material.dart';

import '../../../config/theme/design_tokens.dart';
import '../app_platform.dart';
import '../../../presentation/desktop/desktop_workspace_shell.dart';
import '../platform_ui.dart';
import 'material_platform_ui.dart';

/// Rendu de bureau (macOS et Windows).
///
/// Hérite de l'implémentation Material et surcharge ce qui diverge : l'espace de
/// travail à cinq colonnes, des transitions sans déplacement, des indicateurs plus
/// discrets.
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
    // Au-delà du format compact, le bureau a sa propre disposition : un espace de
    // travail à colonnes, où liste et conversation sont visibles ensemble. C'est
    // ce qu'attend un agent qui traite des dizaines de fils sur un grand écran —
    // une pile mobile étirée l'obligerait à naviguer sans cesse.
    //
    // Le `body` (l'IndexedStack des onglets) est ignoré dans ce cas : la
    // navigation desktop ne passe pas par des onglets.
    if (layout.usesLateralNavigation) {
      // `Colors.transparent` et non `backgroundColor` : le Scaffold peindrait
      // sinon une couleur opaque par-dessus le matériau translucide de la
      // fenêtre, et l'effet de verre disparaîtrait entièrement.
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopWorkspaceShell(),
      );
    }

    // Fenêtre réduite sous 600 px : on repasse sur la disposition mobile, seule
    // tenable à cette largeur. C'est aussi pour cela que la bascule lit la
    // largeur et non la plateforme.
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
