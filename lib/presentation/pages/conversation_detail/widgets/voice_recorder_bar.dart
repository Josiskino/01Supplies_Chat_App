import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
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

  /// Reçoit la note et le **chemin du fichier** capturé, à téléverser.
  final void Function(VoiceNoteData note, String filePath) onSend;
  final VoidCallback onCancel;

  @override
  State<VoiceRecorderBar> createState() => _VoiceRecorderBarState();
}

class _VoiceRecorderBarState extends State<VoiceRecorderBar>
    with SingleTickerProviderStateMixin {
  /// Intervalle entre deux amplitudes — la cadence d'un vrai flux de capture.
  static const Duration _sampleInterval = Duration(milliseconds: 80);

  Timer? _timer;
  Duration _elapsed = Duration.zero;
  final List<double> _waveform = [];

  final AudioRecorder _recorder = AudioRecorder();
  String? _filePath;

  /// Fraction écoulée depuis la dernière amplitude, entre 0 et 1.
  ///
  /// Sans elle, le tracé sautait d'une barre entière tous les dixièmes de
  /// seconde. Le ticker fait glisser la forme d'onde **entre** deux échantillons
  /// et le défilement devient continu.
  late final Ticker _ticker;
  DateTime _lastSample = DateTime.now();
  double _fraction = 0;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    unawaited(_startRecording());

    _timer = Timer.periodic(_sampleInterval, (_) async {
      _lastSample = DateTime.now();
      // L'amplitude réelle du micro, ramenée dans [0,1]. `record` la donne en
      // décibels négatifs : -45 dB correspond au silence ambiant, 0 dB à la
      // saturation.
      double level = 0.3;
      try {
        final amp = await _recorder.getAmplitude();
        level = ((amp.current + 45) / 45).clamp(0.05, 1.0);
      } catch (_) {
        // Micro indisponible : le tracé reste plat plutôt que d'inventer une
        // agitation qui ne correspond à rien.
      }
      if (!mounted) return;
      setState(() {
        _elapsed += _sampleInterval;
        _waveform.add(level);
      });
    });
    _ticker = createTicker((_) {
      final since = DateTime.now().difference(_lastSample).inMicroseconds;
      final next = (since / _sampleInterval.inMicroseconds)
          .clamp(0.0, 1.0)
          .toDouble();
      if (next != _fraction) setState(() => _fraction = next);
    })..start();
  }

  /// Ouvre la capture dans un fichier temporaire.
  ///
  /// AAC dans un conteneur M4A : c'est le format que lisent aussi bien iOS
  /// qu'Android, et celui déjà utilisé par l'app cliente. Un encodage exotique
  /// donnerait des notes que l'un des deux camps ne saurait pas jouer.
  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) widget.onCancel();
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _filePath = path;
    } catch (_) {
      if (mounted) widget.onCancel();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _timer?.cancel();
    // Coupe la capture même si l'écran est quitté sans envoyer : un
    // enregistrement laissé ouvert continue de consommer le micro.
    unawaited(_recorder.stop().catchError((_) => null));
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<void> _send() async {
    _timer?.cancel();
    HapticFeedback.lightImpact();

    final path = await _recorder.stop() ?? _filePath;
    if (path == null || !mounted) {
      widget.onCancel();
      return;
    }
    widget.onSend(
      VoiceNoteData(duration: _elapsed, waveform: List.of(_waveform)),
      path,
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
                    fraction: _fraction,
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
  const _LiveWaveformPainter({
    required this.amplitudes,
    required this.fraction,
    required this.color,
  });

  final List<double> amplitudes;

  /// Avancement entre deux échantillons : décale le tracé d'une fraction de
  /// barre, ce qui rend le défilement continu au lieu de saccadé.
  final double fraction;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 2.5;
    const gap = 2.0;
    const step = barWidth + gap;
    final capacity = (size.width / step).ceil();
    if (capacity <= 0 || amplitudes.isEmpty) return;

    // Seules les dernières barres tiennent : le tracé défile vers la gauche.
    final visible = amplitudes.length <= capacity
        ? amplitudes
        : amplitudes.sublist(amplitudes.length - capacity);
    final paint = Paint()..color = color;
    // Le décalage sub-pixel qui lisse le mouvement.
    final shift = step * fraction;

    for (var i = 0; i < visible.length; i++) {
      final height = (size.height * visible[i]).clamp(3.0, size.height);
      // Aligné à droite : la barre la plus récente reste au bord.
      final x = size.width - (visible.length - i) * step - shift;
      if (x + barWidth < 0) continue;
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
      old.amplitudes.length != amplitudes.length ||
      old.fraction != fraction ||
      old.color != color;
}
