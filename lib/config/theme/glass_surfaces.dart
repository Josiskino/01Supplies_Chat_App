import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Surfaces translucides de l'interface desktop.
///
/// Sur macOS et Windows, la fenêtre est rendue translucide et floute ce qui se
/// trouve derrière (vibrancy natif). Les panneaux doivent donc laisser passer ce
/// fond au lieu d'être peints en blanc opaque.
///
/// Tout passe par ce fichier plutôt que par des `Colors.white.withValues(...)`
/// dispersés : l'opacité d'un verre se règle par tâtonnement, et il faut pouvoir
/// ajuster les cinq colonnes d'un seul endroit sans les désaccorder.
///
/// ## Lisibilité et intensité
///
/// Le glassmorphism dégrade le contraste, et cette interface affiche du texte de
/// 11 à 12 px. La lisibilité est préservée par un **flou fort** plutôt que par une
/// opacité haute : un fond très flouté est uniforme, donc le texte s'y détache,
/// alors qu'un fond peu flouté reste bruité et illisible quelle que soit
/// l'opacité. C'est ce qui permet de descendre à 0,35 sans perdre le texte.
///
/// L'effet est nettement plus lisible en **thème sombre** : du blanc translucide
/// sur un fond clair reste blanc, tandis qu'une surface sombre laisse passer la
/// couleur de l'arrière-plan.
/// ## Deux stratégies selon le thème
///
/// **En clair**, le vibrancy du système suffit : les panneaux sont très
/// translucides et laissent voir le bureau.
///
/// **En sombre**, le matériau vibrancy de macOS produit un gris moyen qui délave
/// toute l'interface — on obtient une bouillie grise sans profondeur. L'app peint
/// donc son propre fond sombre coloré ([GlassBackdrop]), et les panneaux
/// deviennent du verre **sur ce fond** plutôt que sur le bureau. Le rendu est
/// maîtrisé, indépendant du fond d'écran, et les teintes de marque ressortent.
///
/// Les surfaces sombres restent donc modérément translucides : c'est le fond
/// peint, et non le vibrancy, qu'elles laissent passer.
abstract final class GlassSurfaces {
  /// Fond **commun** à toutes les colonnes — rail, navigation, liste, fil,
  /// profil.
  ///
  /// Une seule valeur, et c'est le point important. Les colonnes avaient
  /// auparavant trois voiles distincts (0,45 pour les panneaux, 0,20 pour le fil,
  /// une teinte d'accent pour le rail), dans l'idée de hiérarchiser les surfaces.
  /// À l'usage, l'écart se lisait comme un défaut : le rail paraissait teinté et
  /// le fil délavé, alors que rien ne justifiait que deux colonnes voisines
  /// n'aient pas la même matière.
  ///
  /// L'opacité est calée sur celle de la carte de connexion, qui donne le rendu
  /// recherché : assez de voile pour porter le texte, assez de transparence pour
  /// que le fond reste perceptible.
  static Color surface(bool isDark) => isDark
      ? const Color(0xFF17142B).withValues(alpha: 0.52)
      : Colors.white.withValues(alpha: 0.40);

  /// Bulle reçue et zone de saisie : posées *sur* une surface déjà translucide,
  /// elles doivent rester nettement détachées. Ce sont les surfaces les plus
  /// opaques, parce qu'elles portent le texte le plus lu.
  ///
  /// La teinte sombre est volontairement violacée et non neutre : un gris pur au
  /// milieu d'un fond coloré paraît sale.
  static Color raised(bool isDark) => isDark
      ? const Color(0xFF2A2440).withValues(alpha: 0.82)
      : Colors.white.withValues(alpha: 0.68);

  /// Bordure d'un panneau de verre.
  ///
  /// Un liseré clair est ce qui donne au verre son épaisseur : sans lui, deux
  /// panneaux translucides adjacents se fondent en une seule masse floue. Il
  /// compte d'autant plus que l'opacité est basse.
  static Color border(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.14)
      : Colors.white.withValues(alpha: 0.60);

  /// Séparateur entre colonnes.
  ///
  /// Nettement plus marqué qu'un hairline d'interface opaque : sur du verre, deux
  /// panneaux translucides adjacents se fondent l'un dans l'autre, et un trait à
  /// 6 % d'opacité disparaît complètement. C'est le seul repère qui structure la
  /// lecture des cinq colonnes.
  static Color divider(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.16)
      : Colors.black.withValues(alpha: 0.13);

  /// Séparateur interne à un panneau — sous un en-tête, entre deux sections.
  ///
  /// Un cran en dessous de [divider] : il structure sans découper la colonne.
  static Color innerDivider(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.12)
      : Colors.black.withValues(alpha: 0.10);

  /// Intensité du flou appliqué par [GlassPanel].
  ///
  /// Volontairement élevée : c'est le flou, et non l'opacité, qui rend le texte
  /// lisible sur un fond translucide.
  static const double blurSigma = 34;

  /// Flou réduit, pour les surfaces posées sur du verre déjà flouté.
  static const double blurSigmaSubtle = 12;
}

/// Panneau de verre : fond translucide, flou d'arrière-plan et liseré.
///
/// Le `BackdropFilter` est indispensable même avec le vibrancy système : ce
/// dernier floute ce qui est *derrière la fenêtre*, mais pas ce que l'app peint
/// elle-même. Sans lui, les colonnes laisseraient voir les pixels nets de leurs
/// voisines.
///
/// ⚠️ Coût de rendu : chaque `BackdropFilter` déclenche une passe de composition
/// sur sa zone. C'est acceptable pour cinq panneaux fixes, mais il ne faut pas en
/// mettre un par élément de liste — d'où l'usage réservé aux conteneurs.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.color,
    this.blurSigma = GlassSurfaces.blurSigma,
    this.borderRadius,
    this.border,
    this.width,
  });

  final Widget child;
  final Color? color;
  final double blurSigma;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: width,
      child: ClipRRect(
        // Le clip est obligatoire : un BackdropFilter non borné floute toute la
        // surface de l'écran sous lui, pas seulement la zone du panneau.
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color ?? GlassSurfaces.surface(isDark),
              // `borderRadius` est passé tel quel, y compris `null`.
              // Flutter interdit d'associer un rayon à une bordure non uniforme —
              // et les séparateurs de colonnes n'ont qu'un seul côté. Passer
              // `BorderRadius.zero` au lieu de `null` déclenche l'assertion et
              // fait planter le rendu, alors que la compilation reste silencieuse.
              borderRadius: borderRadius,
              border: border,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Fond coloré peint sous l'interface.
///
/// Sert dans deux cas :
/// - **en thème sombre**, systématiquement : le vibrancy de macOS y produit un
///   gris qui délave tout, donc l'app impose son propre fond ;
/// - **en clair**, uniquement en repli, quand la fenêtre n'a pas pu être rendue
///   translucide. Sans lui, les panneaux flouteraient du blanc sur du blanc.
///
/// Le dégradé sombre est violacé et non gris : c'est ce qui donne au verre quelque
/// chose de coloré à diffuser, et à l'interface sa profondeur.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key, required this.child, this.enabled = true});

  final Widget child;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              // Violet nuit → prune → bleu très sombre. Assez sombre pour que le
              // texte clair porte, assez coloré pour ne pas retomber dans le gris.
              ? [
                  const Color(0xFF1B1438),
                  const Color(0xFF241733),
                  const Color(0xFF0D0B1A),
                ]
              : [
                  accent.withValues(alpha: 0.22),
                  secondary.withValues(alpha: 0.16),
                  accent.withValues(alpha: 0.10),
                ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: child,
    );
  }
}
