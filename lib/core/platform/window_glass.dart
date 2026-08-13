import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show Offset;
import 'package:flutter_acrylic/flutter_acrylic.dart';
// Accès direct à `macos_window_utils`, dont `flutter_acrylic` dépend déjà :
// le repositionnement des boutons système n'est pas réexposé par sa façade.
import 'package:macos_window_utils/macos_window_utils.dart';
// `NSWindowButtonType` n'est pas ré-exporté par la façade du package.
import 'package:macos_window_utils/macos/ns_window_button_type.dart';

import '../utils/app_logger.dart';

/// Active la translucidité de la fenêtre desktop (vibrancy macOS, Acrylic
/// Windows).
///
/// Le vibrancy est un effet **du système**, pas de Flutter : c'est le compositeur
/// de l'OS qui floute ce qui se trouve derrière la fenêtre. Flutter ne peut pas le
/// simuler — un fond semi-transparent sans fenêtre translucide ne laisse voir que
/// du noir.
///
/// L'état est exposé par [isEnabled] parce que l'interface doit s'y adapter :
/// quand l'effet n'a pas pu être appliqué, elle peint son propre dégradé plutôt
/// que de flouter du vide.
abstract final class WindowGlass {
  static bool _isEnabled = false;

  /// `true` si la fenêtre est effectivement translucide.
  static bool get isEnabled => _isEnabled;

  /// Hauteur à réserver en haut de la première colonne.
  ///
  /// Quand le contenu s'étend sous la barre de titre, les boutons système de
  /// macOS (fermer, réduire, agrandir) se superposent au coin supérieur gauche.
  /// Sans cette marge, ils recouvriraient le logo du rail — et le clic irait au
  /// bouton système, pas au widget.
  static double get titleBarInset {
    if (!_isEnabled || kIsWeb || !Platform.isMacOS) return 0;
    return 30;
  }

  /// Largeur occupée par les trois boutons système, une fois resserrés.
  ///
  /// macOS les espace de 20 px par défaut, ce qui les fait déborder d'un rail
  /// étroit sur la colonne suivante. [applyTransparentTitleBar] les rapproche à
  /// 16 px, et cette valeur dit au rail la largeur minimale qu'il doit garantir.
  static const double windowButtonsWidth = 62;

  static bool get _isSupportedPlatform =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows);

  /// À appeler dans `bootstrap()`, **avant** `runApp`.
  ///
  /// N'échoue jamais : une fenêtre opaque est un défaut esthétique, pas une raison
  /// d'empêcher l'app de démarrer.
  static Future<void> initialize({required bool isDark}) async {
    if (!_isSupportedPlatform) return;

    try {
      await Window.initialize();

      await Window.setEffect(effect: _effectFor(isDark), dark: isDark);

      _isEnabled = true;
      AppLogger().info(
        'Fenêtre translucide activée',
        feature: 'Window',
        data: {'platform': Platform.operatingSystem},
      );
    } catch (e, stackTrace) {
      // Cause la plus probable : une version de l'OS trop ancienne, ou un canal
      // de plateforme indisponible. L'interface retombe sur son dégradé.
      _isEnabled = false;
      AppLogger().warning(
        'Translucidité indisponible, repli sur un fond peint',
        feature: 'Window',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Matériau de fenêtre adapté au thème.
  ///
  /// En clair, `sidebar` (celui du Finder et de Mail) donne la translucidité la
  /// plus fine. En sombre, il produit un gris moyen qui délave toute l'interface :
  /// `underWindowBackground` est nettement plus sombre et laisse le fond de l'app
  /// imposer sa teinte.
  static WindowEffect _effectFor(bool isDark) {
    if (!Platform.isMacOS) return WindowEffect.acrylic;
    return isDark
        ? WindowEffect.underWindowBackground
        : WindowEffect.sidebar;
  }

  /// Rend la barre de titre transparente et étend le contenu dessous.
  ///
  /// **À appeler après `window_manager`**, jamais avant : celui-ci reconfigure la
  /// fenêtre à son initialisation et annule ces réglages, ce qui laisse une bande
  /// opaque en haut de la fenêtre alors que le reste du verre fonctionne.
  ///
  /// Les boutons système restent visibles : les masquer obligerait à réimplémenter
  /// fermeture et plein écran, pour un gain purement esthétique.
  static Future<void> applyTransparentTitleBar() async {
    if (!_isEnabled || !Platform.isMacOS) return;

    try {
      await Window.makeTitlebarTransparent();
      await Window.enableFullSizeContentView();
      // Sans cela, macOS dessine une ombre portée sous la barre de titre, visible
      // comme une ligne grise en travers du verre.
      await Window.hideTitle();

      // Resserre les trois boutons pour qu'ils tiennent dans la première colonne.
      //
      // L'espacement par défaut de macOS (20 px) les fait déborder d'un rail
      // étroit : le dernier bouton se retrouve sur la colonne de navigation, et
      // c'est lui qui capte le clic. On les rapproche à 16 px et on les décale
      // légèrement, ce qui les contient dans [windowButtonsWidth].
      const left = 14.0;
      const top = 12.0;
      const spacing = 16.0;

      await WindowManipulator.overrideStandardWindowButtonPosition(
        buttonType: NSWindowButtonType.closeButton,
        offset: const Offset(left, top),
      );
      await WindowManipulator.overrideStandardWindowButtonPosition(
        buttonType: NSWindowButtonType.miniaturizeButton,
        offset: const Offset(left + spacing, top),
      );
      await WindowManipulator.overrideStandardWindowButtonPosition(
        buttonType: NSWindowButtonType.zoomButton,
        offset: const Offset(left + spacing * 2, top),
      );
    } catch (e) {
      AppLogger().warning(
        'Barre de titre transparente indisponible',
        feature: 'Window',
        error: e,
      );
    }
  }

  /// Réapplique l'effet après un changement de thème.
  ///
  /// Le matériau porte sa propre variante claire/sombre : sans cet appel, passer
  /// l'app en sombre laisserait un verre clair derrière une interface sombre.
  static Future<void> updateForTheme({required bool isDark}) async {
    if (!_isEnabled) return;

    try {
      await Window.setEffect(effect: _effectFor(isDark), dark: isDark);
    } catch (e) {
      AppLogger().warning(
        'Mise à jour du matériau de fenêtre échouée',
        feature: 'Window',
        error: e,
      );
    }
  }
}
