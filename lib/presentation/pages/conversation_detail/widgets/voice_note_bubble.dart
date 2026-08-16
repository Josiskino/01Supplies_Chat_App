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
  void dispose() {
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
          child: Icon(
            _controller.isAnimating
                ? CupertinoIcons.pause_fill
                : CupertinoIcons.play_fill,
            size: 26,
            color: widget.foreground,
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
            final elapsed = widget.voice.duration * _controller.value;
            final shown = _controller.value == 0 || _controller.value >= 1
                ? widget.voice.duration
                : elapsed;
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
    final playedUntil = count * progress;

    for (var i = 0; i < count; i++) {
      // Rééchantillonnage : la forme d'onde stockée est plus fine que le nombre
      // de barres qui tiennent dans la bulle.
      final amplitude = amplitudes[(i * amplitudes.length / count).floor()];
      // Hauteur plancher : une barre nulle laisserait un trou dans le tracé.
      final height = (size.height * amplitude).clamp(3.0, size.height);
      final x = i * step;
      final top = (size.height - height) / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barWidth, height),
          const Radius.circular(1.5),
        ),
        Paint()..color = i < playedUntil ? played : pending,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress ||
      old.played != played ||
      old.pending != pending;
}
