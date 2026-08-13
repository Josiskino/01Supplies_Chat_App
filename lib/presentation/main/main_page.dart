import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_colors.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/platform/platform_ui_provider.dart';
import '../../core/providers/navigation/main_tab_provider.dart';
import '../../core/utils/localization_helper.dart';
import '../pages/contacts/contacts_screen.dart';
import '../pages/conversations/conversations_screen.dart';
import '../pages/profile/profile_screen.dart';
import '../pages/requests/requests_screen.dart';
import '../widgets/navigation/double_back_to_exit.dart';
import 'nav_destinations.dart';

/// Coquille principale de l'application.
///
/// Ne connaît **ni** la plateforme **ni** le système de design : elle assemble un
/// corps et une liste de destinations, puis délègue le rendu à [PlatformShell].
/// C'est ce qui permet une tab bar UIKit sur iOS, une barre Material sur Android et
/// un rail sur desktop sans un seul test de plateforme ici.
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
    final platformUi = ref.watch(platformUiProvider);

    // Le compteur de non-lus viendra de la feature messagerie ; en attendant
    // aucun badge n'est affiché.
    const unreadByTab = <int, int>{};

    final destinations = [
      for (final spec in NavDestinations.all)
        spec.toPlatformDestination(
          l10n,
          badgeCount: unreadByTab[spec.index] ?? 0,
        ),
    ];

    // `LayoutBuilder` plutôt que `MediaQuery` : la coquille peut être imbriquée
    // (fenêtre secondaire, panneau) et doit réagir à sa contrainte réelle.
    final shell = LayoutBuilder(
      builder: (context, constraints) {
        final layout = PlatformLayout.of(
          platform: platformUi.platform,
          width: constraints.maxWidth,
        );

        return platformUi.shell.buildShell(
          layout: layout,
          body: IndexedStack(index: selectedIndex, children: _screens),
          destinations: destinations,
          selectedIndex: selectedIndex,
          onSelected: (index) =>
              ref.read(mainTabProvider.notifier).select(index),
          backgroundColor: isDarkMode
              ? AppColors.backgroundColorDark
              : AppColors.backgroundColorLight,
        );
      },
    );

    // Le double-retour ne concerne qu'Android : ailleurs il n'existe pas de geste
    // retour système à intercepter, et sur desktop fermer la fenêtre est déjà un
    // geste délibéré.
    if (!DoubleBackToExit.isSupportedPlatform) {
      return shell;
    }

    return DoubleBackToExit(
      message: "Appuyez encore une fois pour quitter l'application",
      onBackBeforeExit: () {
        // Sur un onglet secondaire, le retour ramène d'abord au premier onglet
        // au lieu de quitter : le comportement attendu d'une app à onglets.
        if (selectedIndex == 0) return false;
        ref.read(mainTabProvider.notifier).select(0);
        return true;
      },
      child: shell,
    );
  }
}
