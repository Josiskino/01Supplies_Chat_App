import 'package:flutter/material.dart';

import '../../../core/responsive/breakpoints.dart';
import 'custom_bottom_nav_bar.dart';
import 'custom_bottom_nav_bar_item.dart';
import 'custom_nav_rail.dart';

/// Coquille de navigation adaptative.
///
/// Bascule sur la **largeur disponible**, jamais sur la plateforme : une fenêtre
/// macOS réduite à 500 px doit se comporter comme un téléphone, et une tablette
/// Android en paysage comme un poste de travail. Tester `Platform.isMacOS`
/// donnerait un rail dans une fenêtre étroite et une barre du bas sur un écran
/// 27 pouces.
///
/// - `< 600 px` : barre de navigation en bas
/// - `600–899 px` : rail latéral replié (icône + libellé dessous)
/// - `>= 900 px` : rail latéral étendu (icône + libellé à droite)
///
/// Le `body` est identique dans les deux dispositions : l'onglet actif et l'état
/// de chaque page survivent donc au redimensionnement de la fenêtre.
class AdaptiveNavScaffold extends StatelessWidget {
  const AdaptiveNavScaffold({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onDestinationSelected,
    required this.body,
    this.railHeader,
    this.railFooter,
    this.backgroundColor,
  });

  final int selectedIndex;
  final List<CustomBottomAppBarItem> items;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  /// Affichés uniquement dans le rail : la barre du bas n'a pas la place.
  final Widget? railHeader;
  final Widget? railFooter;

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    // `LayoutBuilder` plutôt que `MediaQuery` : la coquille peut être imbriquée
    // (fenêtre secondaire, panneau) et doit réagir à sa contrainte réelle, pas à
    // la taille de l'écran.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final useRail = Breakpoints.usesLateralNavigation(width);
        final extended = Breakpoints.usesExtendedRail(width);

        if (!useRail) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: body,
            bottomNavigationBar: CustomBottomAppBar(
              selectedTab: selectedIndex,
              children: items,
              onTap: onDestinationSelected,
            ),
          );
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          body: Row(
            children: [
              CustomNavRail(
                selectedTab: selectedIndex,
                children: items,
                onTap: onDestinationSelected,
                extended: extended,
                header: railHeader,
                footer: railFooter,
              ),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}
