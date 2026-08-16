import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../shared/models/conversation_view_data.dart';

/// Barre d'enregistrement d'une note vocale, en remplacement du composer.
///
/// Reprend le geste de WhatsApp : un point rouge qui pulse, le temps qui court,
/// « Glisser pour annuler » à gauche, et l'envoi à droite.
///
/// ⚠️ Rien n'est **réellement capturé** : la forme d'onde est générée, le
/// minuteur est un [Timer]. Ajouter la capture demanderait `record`, la
/// permission micro sur quatre plateformes et une politique de stockage — un
/// chantier à part, qui n'a pas à retarder la validation de l'interface. Le
/// point d'accroche est [onSend], qui reçoit déjà un [VoiceNoteData] complet.
class VoiceRecorderBar extends StatefulWidget {
  const VoiceRecorderBar({
    super.key,
    required this.onSend,
    required this.onCancel,
  });

  final ValueChanged<VoiceNoteData> onSend;
  final VoidCallback onCancel;

  @override
  State<VoiceRecorderBar> createState() => _VoiceRecorderBarState();
}

class _VoiceRecorderBarState extends State<VoiceRecorderBar> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  final List<double> _waveform = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _elapsed += const Duration(milliseconds: 100);
        // Une amplitude par 100 ms, comme le ferait un vrai flux.
        _waveform.add(0.25 + _random.nextDouble() * 0.75);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _send() {
    _timer?.cancel();
    HapticFeedback.lightImpact();
    widget.onSend(
      VoiceNoteData(duration: _elapsed, waveform: List.of(_waveform)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceS),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                _timer?.cancel();
                widget.onCancel();
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceS),
                child: Icon(
                  CupertinoIcons.trash,
                  size: DesignTokens.iconS,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            const _PulsingDot(),
            const SizedBox(width: DesignTokens.spaceS),
            Text(
              _format(_elapsed),
              style: theme.textTheme.bodyMedium
                  ?.merge(AppleType.subheadline)
                  .copyWith(
                    fontFeatures: const [
                      // Chiffres à chasse fixe : sans eux, le compteur tressaute à
                      // chaque changement de dizaine.
                      FontFeature.tabularFigures(),
                    ],
                  ),
            ),
            const SizedBox(width: DesignTokens.spaceM),
            Expanded(
              child: ClipRect(
                child: CustomPaint(
                  size: const Size(double.infinity, 24),
                  painter: _LiveWaveformPainter(
                    amplitudes: _waveform,
                    color: theme.colorScheme.primary.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.spaceS),
            GestureDetector(
              onTap: _send,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.arrow_up,
                  size: DesignTokens.iconS,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _format(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

/// Point rouge clignotant — le repère universel d'un enregistrement en cours.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.25).animate(_controller),
      child: Container(
        width: 9,
        height: 9,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemRed,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Forme d'onde qui défile pendant la capture : les barres récentes à droite.
class _LiveWaveformPainter extends CustomPainter {
  const _LiveWaveformPainter({required this.amplitudes, required this.color});

  final List<double> amplitudes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 2.5;
    const gap = 2.0;
    const step = barWidth + gap;
    final capacity = (size.width / step).floor();
    if (capacity <= 0 || amplitudes.isEmpty) return;

    // Seules les dernières barres tiennent : le tracé défile vers la gauche.
    final visible = amplitudes.length <= capacity
        ? amplitudes
        : amplitudes.sublist(amplitudes.length - capacity);
    final paint = Paint()..color = color;

    for (var i = 0; i < visible.length; i++) {
      final height = (size.height * visible[i]).clamp(3.0, size.height);
      // Aligné à droite : la barre la plus récente reste au bord.
      final x = size.width - (visible.length - i) * step;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (size.height - height) / 2, barWidth, height),
          const Radius.circular(1.25),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LiveWaveformPainter old) =>
      old.amplitudes.length != amplitudes.length || old.color != color;
}
