import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Fond d'appel : des taches de couleur très floutées sur du noir.
///
/// La palette est tirée **une fois par appel** à partir d'une graine, et ne
/// bouge plus ensuite. Un fond qui se recompose à chaque image détournerait
/// l'attention d'un écran dont l'objet est ailleurs ; un fond identique à chaque
/// fois, lui, rend les appels indiscernables les uns des autres dans le
/// souvenir.
///
/// Les couleurs ne sont pas tirées composante par composante : un aléa complet
/// produit des teintes boueuses une fois sur deux. Ce sont des **palettes
/// entières**, choisies à la main, qui sont tirées au sort — l'aléa ne porte
/// que sur la position et la taille des taches.
class CallBackdrop extends StatelessWidget {
  const CallBackdrop({super.key, required this.seed, required this.child});

  /// Graine de l'appel. Deux appels différents doivent en avoir deux distinctes.
  final int seed;

  final Widget child;

  /// Palettes de quatre teintes, toutes tenables sur du noir.
  static const List<List<Color>> _palettes = [
    // Forêt : vert profond, sapin, bleu nuit, prune.
    [
      Color(0xFF1B5E3F),
      Color(0xFF0F3D2E),
      Color(0xFF1A2E5C),
      Color(0xFF4A2B6B),
    ],
    // Marque : violet et orange 01Supplies, tenus par un indigo.
    [
      Color(0xFF6F52ED),
      Color(0xFF3B2A8C),
      Color(0xFFFF7D28),
      Color(0xFF2A1B4D),
    ],
    // Crépuscule : magenta, prune, bleu profond.
    [
      Color(0xFF8E2D6B),
      Color(0xFF4A1F52),
      Color(0xFF1E2A6E),
      Color(0xFF6B2340),
    ],
    // Océan : cyan, teal, bleu, indigo.
    [
      Color(0xFF0E5C6B),
      Color(0xFF12707A),
      Color(0xFF17407A),
      Color(0xFF2B2E7A),
    ],
    // Braise : orange brûlé, rouge sombre, prune.
    [
      Color(0xFFB35424),
      Color(0xFF7A2020),
      Color(0xFF5C2350),
      Color(0xFF2E1A3D),
    ],
  ];

  /// Palettes exposées aux tests.
  @visibleForTesting
  static List<List<Color>> get debugPalettes => _palettes;

  @override
  Widget build(BuildContext context) {
    final random = math.Random(seed);
    final palette = _palettes[seed.abs() % _palettes.length];

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF07070A)),
        // Le flou est appliqué à l'ensemble des taches d'un coup : un
        // `ImageFiltered` par tache multiplierait les passes de composition pour
        // le même résultat.
        //
        // `ImageFiltered` et non `BackdropFilter` : on floute ce que ce
        // sous-arbre peint, pas ce qui se trouve derrière lui — un
        // `BackdropFilter` ici ne flouterait que le noir.
        IgnorePointer(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 110, sigmaY: 110),
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (var i = 0; i < palette.length; i++)
                  _Blob(
                    color: palette[i],
                    // Positions tirées mais bornées : les taches doivent
                    // couvrir les quatre coins, sinon le fond se réduit à une
                    // seule zone colorée sur un écran par ailleurs noir.
                    alignment: Alignment(
                      (i.isEven ? -1 : 1) * (0.35 + random.nextDouble() * 0.75),
                      (i < 2 ? -1 : 1) * (0.35 + random.nextDouble() * 0.75),
                    ),
                    sizeFactor: 0.55 + random.nextDouble() * 0.35,
                  ),
              ],
            ),
          ),
        ),
        // Voile assombrissant : les taches donnent l'ambiance, mais les
        // contrôles et le minuteur doivent rester lisibles quelle que soit la
        // palette tirée. Sans lui, la palette « braise » avale le texte blanc.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x99000000), Color(0x4D000000), Color(0xB3000000)],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.color,
    required this.alignment,
    required this.sizeFactor,
  });

  final Color color;
  final Alignment alignment;

  /// Diamètre, en fraction de la plus petite dimension de l'écran.
  final double sizeFactor;

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final diameter = shortest * sizeFactor;

    return Align(
      alignment: alignment,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Opacité modérée : à pleine intensité, deux taches qui se recouvrent
          // saturent et le fond vire à l'aplat.
          color: color.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}
