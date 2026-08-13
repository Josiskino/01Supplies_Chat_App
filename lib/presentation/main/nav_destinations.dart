import 'package:flutter/widgets.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/utils/localization_helper.dart';

/// Une destination de la navigation principale.
class NavDestination {
  const NavDestination({
    required this.index,
    required this.subPath,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  /// Position dans l'`IndexedStack` et dans la barre/le rail.
  final int index;

  /// Segment de route permettant de cibler l'onglet par lien profond
  /// (`/main/conversations`).
  final String subPath;

  final IconData icon;

  /// Variante pleine, affichée quand l'onglet est actif.
  final IconData selectedIcon;

  /// Libellé traduit, résolu au build (donc réactif au changement de langue).
  final String Function(AppLocalizations l10n) label;
}

/// Source **unique** des destinations.
///
/// La barre du bas et le rail latéral lisent cette liste. Deux listes séparées
/// divergeraient dès le premier ajout d'onglet — et la divergence serait
/// invisible tant qu'on ne redimensionne pas la fenêtre.
abstract final class NavDestinations {
  static const List<NavDestination> all = [
    NavDestination(
      index: 0,
      subPath: 'conversations',
      icon: Iconsax.message,
      selectedIcon: Iconsax.message5,
      label: _conversations,
    ),
    NavDestination(
      index: 1,
      subPath: 'requests',
      icon: Iconsax.receipt_item,
      selectedIcon: Iconsax.receipt_item5,
      label: _requests,
    ),
    NavDestination(
      index: 2,
      subPath: 'contacts',
      icon: Iconsax.people,
      selectedIcon: Iconsax.people5,
      label: _contacts,
    ),
    NavDestination(
      index: 3,
      subPath: 'profile',
      icon: Iconsax.user,
      selectedIcon: Iconsax.user_tag,
      label: _profile,
    ),
  ];

  static int get length => all.length;

  // Les tear-offs de fonctions top-level permettent de garder la liste `const`.
  static String _conversations(AppLocalizations l10n) => l10n.navConversations;
  static String _requests(AppLocalizations l10n) => l10n.navRequests;
  static String _contacts(AppLocalizations l10n) => l10n.navContacts;
  static String _profile(AppLocalizations l10n) => l10n.navProfile;
}
