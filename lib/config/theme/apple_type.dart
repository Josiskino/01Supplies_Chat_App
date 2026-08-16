import 'package:flutter/widgets.dart';

/// Échelle typographique d'iOS — *Dynamic Type*, taille par défaut « Large ».
///
/// Reprend les onze styles des Human Interface Guidelines avec leurs trois
/// paramètres : corps, interligne et approche. Les valeurs des styles à 17 pt
/// (−0,41 d'approche) et 15 pt (−0,23) sont celles que le SDK Flutter applique
/// lui-même dans `CupertinoTextThemeData`, ce qui les rend vérifiables sans
/// quitter le dépôt.
///
/// ## Pourquoi l'interligne compte plus que le corps
///
/// Un `TextStyle` sans `height` laisse la police imposer sa propre métrique,
/// nettement plus généreuse que celle d'iOS. C'est ce qui donnait des lignes de
/// conversation de 84 pt là où Messages en fait 76, alors que nos corps étaient
/// **déjà** égaux ou inférieurs à ceux d'Apple. Un texte paraît trop grand bien
/// avant que sa taille en points ne soit en cause.
///
/// ## Portée
///
/// Appliquée aux écrans de messagerie, sur les deux plateformes mobiles. L'écart
/// avec Material 3 se limite au corps (17 contre 16) : le prix d'une grille
/// unique est d'un point, celui de deux grilles serait deux jeux de valeurs à
/// tenir en accord.
abstract final class AppleType {
  /// 34 / 41 — titre de grande barre de navigation.
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    height: 41 / 34,
    letterSpacing: 0.37,
    fontWeight: FontWeight.w400,
  );

  /// 28 / 34.
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    letterSpacing: 0.36,
    fontWeight: FontWeight.w400,
  );

  /// 22 / 28.
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    letterSpacing: 0.35,
    fontWeight: FontWeight.w400,
  );

  /// 20 / 25.
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    height: 25 / 20,
    letterSpacing: 0.38,
    fontWeight: FontWeight.w400,
  );

  /// 17 / 22, semi-gras — nom d'un contact, titre d'une cellule.
  ///
  /// Même corps que [body] : c'est la **graisse** qui distingue un intitulé de
  /// son contenu sur iOS, pas la taille. Grossir le nom pour le détacher est le
  /// réflexe qui fait dériver une liste vers le lourd.
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    height: 22 / 17,
    letterSpacing: -0.41,
    fontWeight: FontWeight.w600,
  );

  /// 17 / 22 — corps de texte, bulle de message, champ de saisie.
  static const TextStyle body = TextStyle(
    fontSize: 17,
    height: 22 / 17,
    letterSpacing: -0.41,
    fontWeight: FontWeight.w400,
  );

  /// 16 / 21.
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    height: 21 / 16,
    letterSpacing: -0.31,
    fontWeight: FontWeight.w400,
  );

  /// 15 / 20 — aperçu d'un message, texte secondaire d'une cellule.
  static const TextStyle subheadline = TextStyle(
    fontSize: 15,
    height: 20 / 15,
    letterSpacing: -0.23,
    fontWeight: FontWeight.w400,
  );

  /// 13 / 18 — horodatage d'une liste, séparateur de date.
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    letterSpacing: -0.08,
    fontWeight: FontWeight.w400,
  );

  /// 12 / 16 — horodatage sous une bulle.
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );

  /// 11 / 13 — nom d'expéditeur au-dessus d'une bulle, libellé d'onglet.
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    height: 13 / 11,
    letterSpacing: 0.06,
    fontWeight: FontWeight.w400,
  );
}
