import 'package:flutter/widgets.dart';
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
    required this.sfSymbol,
    required this.selectedSfSymbol,
    required this.label,
  });

  /// Position dans l'`IndexedStack` et dans la barre ou le rail.
  final int index;

  /// Segment de route permettant de cibler l'onglet par lien profond
  /// (`/main/conversations`).
  final String subPath;

  final IconData icon;
  final IconData selectedIcon;

  /// Nom du SF Symbol, pour le rendu natif iOS.
  final String sfSymbol;
  final String selectedSfSymbol;

  /// Libellé traduit, résolu au build (donc réactif au changement de langue).
  final String Function(AppLocalizations l10n) label;

  /// Traduit la déclaration en destination consommable par [PlatformShell].
  PlatformDestination toPlatformDestination(
    AppLocalizations l10n, {
    int badgeCount = 0,
  }) {
    return PlatformDestination(
      icon: icon,
      selectedIcon: selectedIcon,
      sfSymbol: sfSymbol,
      selectedSfSymbol: selectedSfSymbol,
      label: label(l10n),
      badgeCount: badgeCount,
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
      sfSymbol: 'message',
      selectedSfSymbol: 'message.fill',
      label: _conversations,
    ),
    NavDestinationSpec(
      index: 1,
      subPath: 'requests',
      icon: Iconsax.receipt_item,
      selectedIcon: Iconsax.receipt_item5,
      sfSymbol: 'shippingbox',
      selectedSfSymbol: 'shippingbox.fill',
      label: _requests,
    ),
    NavDestinationSpec(
      index: 2,
      subPath: 'contacts',
      icon: Iconsax.people,
      selectedIcon: Iconsax.people5,
      sfSymbol: 'person.2',
      selectedSfSymbol: 'person.2.fill',
      label: _contacts,
    ),
    NavDestinationSpec(
      index: 3,
      subPath: 'profile',
      icon: Iconsax.user,
      selectedIcon: Iconsax.user_tag,
      sfSymbol: 'person.crop.circle',
      selectedSfSymbol: 'person.crop.circle.fill',
      label: _profile,
    ),
  ];

  static int get length => all.length;

  // Les fonctions top-level permettent de garder la liste `const`.
  static String _conversations(AppLocalizations l10n) => l10n.navConversations;
  static String _requests(AppLocalizations l10n) => l10n.navRequests;
  static String _contacts(AppLocalizations l10n) => l10n.navContacts;
  static String _profile(AppLocalizations l10n) => l10n.navProfile;
}
