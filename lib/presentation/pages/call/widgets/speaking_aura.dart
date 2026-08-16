import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Halo animé posé derrière l'avatar de la personne qui parle.
///
/// Trois lobes irréguliers, entrelacés et tournant chacun à sa vitesse, dont le
/// rayon respire au rythme d'une voix simulée.
///
/// ## Pourquoi trois formes et non un cercle
///
/// Un cercle qui grossit et rétrécit se lit comme un chargement. Trois lobes
/// déphasés ne se superposent jamais tout à fait : leur enveloppe change de
/// contour à chaque image, ce qui donne l'impression d'une matière vivante
/// plutôt que d'un indicateur. C'est ce que font les assistants vocaux.
///
/// ## Pourquoi trois fréquences incommensurables
///
/// Les vitesses de rotation (0,23 / −0,31 / 0,17 tour par seconde) n'ont pas de
/// diviseur commun : la figure ne se répète donc jamais à l'identique. Avec des
/// vitesses proches, l'œil retrouve la boucle en quelques secondes et l'effet
/// retombe à une animation mécanique.
class SpeakingAura extends StatefulWidget {
  const SpeakingAura({
    super.key,
    required this.size,
    required this.color,
    this.active = true,
  });

  /// Diamètre de l'avatar autour duquel le halo se déploie.
  final double size;

  final Color color;

  /// À l'arrêt, le halo s'efface au lieu de disparaître d'un coup.
  final bool active;

  @override
  State<SpeakingAura> createState() => _SpeakingAuraState();
}

class _SpeakingAuraState extends State<SpeakingAura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // Longue période : c'est le déphasage des lobes qui anime la figure, pas la
    // vitesse du contrôleur.
    duration: const Duration(seconds: 6),
  )..repeat();

  /// Enveloppe de la voix simulée, entre 0 et 1.
  ///
  /// Une somme de sinusoïdes non harmoniques plutôt qu'un aléa : le hasard pur
  /// donne un tremblement nerveux, là où une parole a des respirations et des
  /// accents. C'est la différence entre « ça bouge » et « quelqu'un parle ».
  double _amplitude(double t) {
    final slow = math.sin(t * math.pi * 2 * 0.8);
    final mid = math.sin(t * math.pi * 2 * 2.3 + 1.1);
    final fast = math.sin(t * math.pi * 2 * 5.7 + 2.4);
    final raw = 0.55 + 0.25 * slow + 0.14 * mid + 0.06 * fast;
    return raw.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.active ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return CustomPaint(
              size: Size.square(widget.size * 2.1),
              painter: _AuraPainter(
                phase: t,
                amplitude: _amplitude(t),
                color: widget.color,
                coreRadius: widget.size / 2,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuraPainter extends CustomPainter {
  const _AuraPainter({
    required this.phase,
    required this.amplitude,
    required this.color,
    required this.coreRadius,
  });

  /// Avancement du cycle, entre 0 et 1.
  final double phase;

  /// Intensité de la voix à cet instant.
  final double amplitude;

  final Color color;

  /// Rayon de l'avatar : les lobes partent de son bord, jamais de son centre.
  final double coreRadius;

  /// Vitesse de rotation de chaque lobe, en tours par cycle. Le signe donne le
  /// sens ; les valeurs sont volontairement sans diviseur commun.
  static const List<double> _speeds = [0.23, -0.31, 0.17];

  /// Décalage de phase, pour que les lobes ne respirent pas ensemble.
  static const List<double> _offsets = [0, 2.1, 4.3];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (var i = 0; i < _speeds.length; i++) {
      final localPhase = phase * _speeds[i] * math.pi * 2 + _offsets[i];
      // Chaque lobe respire à son propre rythme autour de l'amplitude commune :
      // la voix les pilote tous, mais aucun ne réagit exactement comme l'autre.
      final breath = 0.85 + 0.15 * math.sin(localPhase * 3);
      final radius = coreRadius * (1.18 + amplitude * 0.42) * breath;

      canvas.drawPath(
        _lobePath(center, radius, localPhase, i),
        Paint()
          ..color = color.withValues(alpha: 0.22 - i * 0.05)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  /// Un lobe : un cercle dont le rayon ondule, tracé en courbes de Bézier.
  ///
  /// La déformation reste faible (±12 %) : au-delà, la forme devient une étoile
  /// et se met à raconter autre chose qu'une voix.
  Path _lobePath(Offset center, double radius, double rotation, int index) {
    const points = 7;
    final path = Path();
    final vertices = <Offset>[];

    for (var i = 0; i < points; i++) {
      final angle = rotation + i * math.pi * 2 / points;
      // Le nombre de bosses varie d'un lobe à l'autre : trois formes au même
      // profil tourneraient comme un seul objet.
      final wobble = 1 + 0.12 * math.sin(angle * (3 + index) + rotation * 2);
      vertices.add(
        center + Offset(math.cos(angle), math.sin(angle)) * (radius * wobble),
      );
    }

    // Fermeture par points milieux : relier les sommets en ligne droite
    // donnerait un polygone, et l'effet de matière disparaîtrait.
    path.moveTo(
      (vertices.first.dx + vertices.last.dx) / 2,
      (vertices.first.dy + vertices.last.dy) / 2,
    );
    for (var i = 0; i < vertices.length; i++) {
      final current = vertices[i];
      final next = vertices[(i + 1) % vertices.length];
      path.quadraticBezierTo(
        current.dx,
        current.dy,
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_AuraPainter old) =>
      old.phase != phase ||
      old.amplitude != amplitude ||
      old.color != color ||
      old.coreRadius != coreRadius;
}
