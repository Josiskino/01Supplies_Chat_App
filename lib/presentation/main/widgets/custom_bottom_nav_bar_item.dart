import 'package:flutter/widgets.dart';

/// Élément de la navigation principale, rendu à l'identique par la barre du bas
/// et par le rail latéral.
class CustomBottomAppBarItem {
  const CustomBottomAppBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.text,
    this.badgeCount = 0,
    this.itemKey,
  });

  final IconData icon;

  /// Variante affichée quand l'élément est actif.
  final IconData selectedIcon;

  final String text;

  /// Valeur du badge (messages non lus). `<= 0` : aucun badge. Au-delà de 9, on
  /// affiche « 9+ » — un compteur exact prendrait plus de place que l'icône.
  final int badgeCount;

  /// Clé optionnelle, pour cibler l'élément depuis un test ou un tour guidé.
  final Key? itemKey;
}
