import 'package:flutter/cupertino.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/platform/platform_ui.dart';
import '../../core/utils/localization_helper.dart';

/// Déclaration d'une destination, indépendante du système de design.
///
/// Porte à la fois l'icône Material et le nom du SF Symbol : l'implémentation
/// Apple utilise le second pour rendre la tab bar UIKit, les autres le premier.
class NavDestinationSpec {
  const NavDestinationSpec({
    required this.index,
    required this.subPath,
    required this.icon,
    required this.selectedIcon,
    required this.cupertinoIcon,
    required this.cupertinoSelectedIcon,
    required this.sfSymbol,
    required this.selectedSfSymbol,
    required this.label,
    this.isSearch = false,
  });

  /// Position dans l'`IndexedStack` et dans la barre ou le rail.
  final int index;

  /// Segment de route permettant de cibler l'onglet par lien profond
  /// (`/main/conversations`).
  final String subPath;

  final IconData icon;
  final IconData selectedIcon;

  /// Icônes Cupertino, pour le rendu Apple quand la barre native n'est pas
  /// active.
  final IconData cupertinoIcon;
  final IconData cupertinoSelectedIcon;

  /// Nom du SF Symbol, pour le rendu natif iOS.
  final String sfSymbol;
  final String selectedSfSymbol;

  /// Libellé traduit, résolu au build (donc réactif au changement de langue).
  final String Function(AppLocalizations l10n) label;

  /// Destination de recherche, détachée à droite de la barre sur iOS 26.
  final bool isSearch;

  /// Traduit la déclaration en destination consommable par [PlatformShell].
  PlatformDestination toPlatformDestination(
    AppLocalizations l10n, {
    int badgeCount = 0,
  }) {
    return PlatformDestination(
      icon: icon,
      selectedIcon: selectedIcon,
      cupertinoIcon: cupertinoIcon,
      cupertinoSelectedIcon: cupertinoSelectedIcon,
      sfSymbol: sfSymbol,
      selectedSfSymbol: selectedSfSymbol,
      label: label(l10n),
      badgeCount: badgeCount,
      isSearch: isSearch,
      key: ValueKey('nav-$subPath'),
    );
  }
}

/// Source **unique** des destinations.
///
/// Les trois rendus (Material, Cupertino, desktop) lisent cette liste. Des listes
/// séparées divergeraient dès le premier ajout d'onglet — et la divergence serait
/// invisible tant qu'on ne change pas de plateforme.
abstract final class NavDestinations {
  static const List<NavDestinationSpec> all = [
    NavDestinationSpec(
      index: 0,
      subPath: 'conversations',
      icon: Iconsax.message,
      selectedIcon: Iconsax.message5,
      cupertinoIcon: CupertinoIcons.chat_bubble_2,
      cupertinoSelectedIcon: CupertinoIcons.chat_bubble_2_fill,
      sfSymbol: 'message',
      selectedSfSymbol: 'message.fill',
      label: _conversations,
    ),
    NavDestinationSpec(
      index: 1,
      subPath: 'calls',
      icon: Iconsax.call,
      selectedIcon: Iconsax.call5,
      cupertinoIcon: CupertinoIcons.phone,
      cupertinoSelectedIcon: CupertinoIcons.phone_fill,
      sfSymbol: 'phone',
      selectedSfSymbol: 'phone.fill',
      label: _calls,
    ),
    NavDestinationSpec(
      index: 2,
      subPath: 'contacts',
      icon: Iconsax.people,
      selectedIcon: Iconsax.people5,
      cupertinoIcon: CupertinoIcons.person_2,
      cupertinoSelectedIcon: CupertinoIcons.person_2_fill,
      sfSymbol: 'person.2',
      selectedSfSymbol: 'person.2.fill',
      label: _contacts,
    ),
    NavDestinationSpec(
      index: 3,
      subPath: 'settings',
      // Même icône dans les deux états, à dessein. Toute la famille
      // `setting*5` — les variantes pleines — tombe sur des marques
      // combinantes hébraïques (U+05BB à U+05BF) : HarfBuzz leur applique un
      // positionnement de marque et l'engrenage sortait décalé d'une demi-
      // largeur vers la droite dans sa pastille, seul de toute la barre. La
      // seule exception, `setting_45` (U+05BE, ponctuation espaçante), dessine
      // des curseurs et non un engrenage. La sélection reste lisible : pastille
      // teintée, icône colorée et libellé en gras.
      icon: Iconsax.setting_2,
      selectedIcon: Iconsax.setting_2,
      cupertinoIcon: CupertinoIcons.settings,
      cupertinoSelectedIcon: CupertinoIcons.settings_solid,
      sfSymbol: 'gearshape',
      selectedSfSymbol: 'gearshape.fill',
      label: _settings,
    ),
    // Toujours en dernier : iOS 26 la sort du groupe et lui donne sa propre
    // pastille à droite de la barre.
    NavDestinationSpec(
      index: 4,
      subPath: 'search',
      icon: Iconsax.search_normal_1,
      selectedIcon: Iconsax.search_normal,
      cupertinoIcon: CupertinoIcons.search,
      cupertinoSelectedIcon: CupertinoIcons.search,
      sfSymbol: 'magnifyingglass',
      selectedSfSymbol: 'magnifyingglass',
      label: _search,
      isSearch: true,
    ),
  ];

  static int get length => all.length;

  // Les fonctions top-level permettent de garder la liste `const`.
  static String _conversations(AppLocalizations l10n) => l10n.navConversations;
  static String _calls(AppLocalizations l10n) => l10n.navCalls;
  static String _contacts(AppLocalizations l10n) => l10n.navContacts;
  static String _settings(AppLocalizations l10n) => l10n.navSettings;
  static String _search(AppLocalizations l10n) => l10n.search;
}
