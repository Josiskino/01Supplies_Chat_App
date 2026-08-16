import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../shared/models/conversation_view_data.dart';

/// Contenu d'une bulle portant une note vocale : lecture, forme d'onde, durée.
///
/// ⚠️ La lecture est **simulée** : la tête de lecture avance sur un
/// [AnimationController] calé sur la durée annoncée, sans décoder d'audio. Le
/// socle n'a pas de couche média, et la présentation n'a pas à l'attendre pour
/// être jugée. Brancher un vrai lecteur revient à remplacer le contrôleur par la
/// position du flux — la peinture, elle, ne change pas.
class VoiceNoteBubble extends StatefulWidget {
  const VoiceNoteBubble({
    super.key,
    required this.voice,
    required this.foreground,
    required this.accent,
  });

  final VoiceNoteData voice;

  /// Couleur du texte et des icônes, héritée de la bulle qui la contient.
  final Color foreground;

  /// Couleur des barres déjà lues.
  final Color accent;

  @override
  State<VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<VoiceNoteBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.voice.duration,
  );

  @override
  void initState() {
    super.initState();
    // La fin de lecture doit rebasculer le bouton sur « lire ». Rien ne le fait
    // spontanément : `AnimatedBuilder` suit les *valeurs*, et à la dernière
    // image `isAnimating` est encore vrai — c'est le changement de **statut**,
    // émis juste après, qui porte l'information.
    _controller.addStatusListener(_onStatus);
  }

  /// Avancement de la tête de lecture, exposé pour les tests.
  @visibleForTesting
  double get playbackProgress => _controller.value;

  void _onStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed) {
      // Remise à zéro en fin de lecture : la forme d'onde repart vierge et le
      // message redevient « à écouter ». Laissée pleine, elle donnait un
      // message définitivement barré, et le prochain appui semblait sans effet
      // le temps que la tête reparte du début.
      _controller.value = 0;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.isAnimating) {
      _controller.stop();
    } else {
      // Une lecture terminée repart du début plutôt que de rester bloquée.
      if (_controller.value >= 1) _controller.value = 0;
      _controller.forward();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Icon(
              _controller.isAnimating
                  ? CupertinoIcons.pause_fill
                  : CupertinoIcons.play_fill,
              size: 26,
              color: widget.foreground,
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.spaceM),
        Flexible(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: const Size(150, 26),
              painter: _WaveformPainter(
                amplitudes: widget.voice.waveform,
                progress: _controller.value,
                played: widget.accent,
                pending: widget.foreground.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.spaceS),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Pendant la lecture, le compteur montre le temps écoulé ; à
            // l'arrêt, la durée totale. C'est ce que fait WhatsApp, et cela
            // évite d'afficher un 0:00 fixe sur un message non lu.
            // À l'arrêt comme en fin de lecture, c'est la durée totale qui
            // s'affiche : un compteur figé à 0:13 sur une note de 0:14 se lit
            // comme une lecture interrompue.
            final shown = _controller.isAnimating
                ? widget.voice.duration * _controller.value
                : widget.voice.duration;
            return Text(
              _format(shown),
              style: Theme.of(context).textTheme.labelSmall
                  ?.merge(AppleType.caption1)
                  .copyWith(color: widget.foreground.withValues(alpha: 0.75)),
            );
          },
        ),
      ],
    );
  }

  static String _format(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

/// Forme d'onde en barres, la partie lue peinte dans la couleur d'accent.
class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.amplitudes,
    required this.progress,
    required this.played,
    required this.pending,
  });

  final List<double> amplitudes;
  final double progress;
  final Color played;
  final Color pending;

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    const barWidth = 3.0;
    const gap = 2.0;
    const step = barWidth + gap;
    final count = (size.width / step).floor().clamp(1, amplitudes.length);

    void drawBars(Paint paint) {
      for (var i = 0; i < count; i++) {
        // Rééchantillonnage : la forme d'onde stockée est plus fine que le
        // nombre de barres qui tiennent dans la bulle.
        final amplitude = amplitudes[(i * amplitudes.length / count).floor()];
        // Hauteur plancher : une barre nulle laisserait un trou dans le tracé.
        final height = (size.height * amplitude).clamp(3.0, size.height);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              i * step,
              (size.height - height) / 2,
              barWidth,
              height,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
    }

    // Deux passes et un découpage au pixel, plutôt qu'une couleur choisie barre
    // par barre. Comparer l'index à une progression fait basculer une barre
    // entière d'un coup : sur une trentaine de barres pour quatorze secondes,
    // la tête de lecture avançait par à-coups d'une demi-seconde. Le découpage
    // colore la barre en cours **partiellement**, et le mouvement devient
    // continu.
    drawBars(Paint()..color = pending);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    drawBars(Paint()..color = played);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress ||
      old.played != played ||
      old.pending != pending;
}
