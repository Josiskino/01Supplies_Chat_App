import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_colors.dart';
import '../../core/providers/navigation/main_tab_provider.dart';
import '../../core/utils/localization_helper.dart';
import '../pages/contacts/contacts_screen.dart';
import '../pages/conversations/conversations_screen.dart';
import '../pages/profile/profile_screen.dart';
import '../pages/requests/requests_screen.dart';
import '../widgets/navigation/double_back_to_exit.dart';
import 'nav_destinations.dart';
import 'widgets/adaptive_nav_scaffold.dart';
import 'widgets/custom_bottom_nav_bar_item.dart';

/// Coquille principale de l'application.
///
/// Les quatre onglets sont montés dans un `IndexedStack` : leur état (position de
/// défilement, brouillon de message en cours de saisie) survit au changement
/// d'onglet, ce qu'un `switch` sur l'index détruirait à chaque bascule.
class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  /// Construites une seule fois : recréer la liste à chaque build remplacerait
  /// les widgets et réinitialiserait l'état préservé par l'`IndexedStack`.
  static const List<Widget> _screens = [
    ConversationsScreen(),
    RequestsScreen(),
    ContactsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final l10n = LocalizationHelper.of(context);
    final selectedIndex = ref.watch(mainTabProvider);

    // Le compteur de non-lus viendra de la feature messagerie ; en attendant
    // aucun badge n'est affiché.
    const unreadByTab = <int, int>{};

    final items = [
      for (final destination in NavDestinations.all)
        CustomBottomAppBarItem(
          icon: destination.icon,
          selectedIcon: destination.selectedIcon,
          text: destination.label(l10n),
          badgeCount: unreadByTab[destination.index] ?? 0,
          itemKey: ValueKey('nav-${destination.subPath}'),
        ),
    ];

    final scaffold = AdaptiveNavScaffold(
      selectedIndex: selectedIndex,
      items: items,
      onDestinationSelected: (index) =>
          ref.read(mainTabProvider.notifier).select(index),
      backgroundColor: isDarkMode
          ? AppColors.backgroundColorDark
          : AppColors.backgroundColorLight,
      body: IndexedStack(index: selectedIndex, children: _screens),
    );

    // Le double-retour ne concerne qu'Android : ailleurs il n'existe pas de
    // geste retour système à intercepter, et sur desktop fermer la fenêtre est
    // déjà un geste délibéré.
    if (kIsWeb || !DoubleBackToExit.isSupportedPlatform) {
      return scaffold;
    }

    return DoubleBackToExit(
      message: "Appuyez encore une fois pour quitter l'application",
      onBackBeforeExit: () {
        // Sur un onglet secondaire, le retour ramène d'abord au premier onglet
        // au lieu de quitter : c'est le comportement attendu d'une app à onglets.
        if (selectedIndex == 0) return false;
        ref.read(mainTabProvider.notifier).select(0);
        return true;
      },
      child: scaffold,
    );
  }
}
