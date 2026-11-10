import 'dart:async';

import '../../../../core/services/audio_recording_service.dart';

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
class VoiceRecorderBar extends StatefulWidget {
  const VoiceRecorderBar({
    super.key,
    required this.onSend,
    required this.onCancel,
    this.sessionFactory,
  });

  /// Reçoit la note et le **chemin du fichier** capturé, à téléverser.
  final void Function(VoiceNoteData note, String filePath) onSend;
  final VoidCallback onCancel;
  final VoiceRecordingSession Function()? sessionFactory;

  @override
  State<VoiceRecorderBar> createState() => _VoiceRecorderBarState();
}

class _VoiceRecorderBarState extends State<VoiceRecorderBar>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// Intervalle entre deux amplitudes — la cadence d'un vrai flux de capture.
  static const Duration _sampleInterval = Duration(milliseconds: 80);

  Timer? _timer;
  Duration _elapsed = Duration.zero;
  final List<double> _waveform = [];

  late final VoiceRecordingSession _session;
  bool _ready = false;
  bool _sending = false;
  bool _sampling = false;

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
    WidgetsBinding.instance.addObserver(this);
    HapticFeedback.mediumImpact();
    _session = widget.sessionFactory?.call() ?? VoiceRecordingSession();
    unawaited(_startRecording());
    _ticker = createTicker((_) {
      final since = DateTime.now().difference(_lastSample).inMicroseconds;
      final next = (since / _sampleInterval.inMicroseconds)
          .clamp(0.0, 1.0)
          .toDouble();
      if (next != _fraction) setState(() => _fraction = next);
    })..start();
  }

  Future<void> _startRecording() async {
    try {
      final started = await _session.start();
      if (!mounted || !started) return;
      setState(() => _ready = true);
      _timer = Timer.periodic(_sampleInterval, (_) => unawaited(_sample()));
    } catch (error) {
      if (!mounted) return;
      _notifyError(error);
      widget.onCancel();
    }
  }

  Future<void> _sample() async {
    if (_sampling || !_ready || _sending) return;
    _sampling = true;
    try {
      final level = await _session.amplitude();
      if (!mounted) return;
      _lastSample = DateTime.now();
      setState(() {
        _elapsed = _session.elapsed;
        // Keep capture memory bounded even if a recording lasts several hours.
        if (_waveform.length >= 1500) _waveform.removeRange(0, 750);
        _waveform.add(level);
      });
    } catch (_) {
      /* An amplitude read must not interrupt capture. */
    } finally {
      _sampling = false;
    }
  }

  void _notifyError(Object error) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          error is VoiceRecordingException
              ? error.message
              : 'Impossible d’enregistrer le vocal. Réessayez.',
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
      unawaited(_session.close());
      widget.onCancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _timer?.cancel();
    unawaited(_session.close());
    super.dispose();
  }

  Future<void> _send() async {
    if (!_ready || _sending) return;
    setState(() => _sending = true);
    _timer?.cancel();
    HapticFeedback.lightImpact();
    try {
      final recording = await _session.finish();
      if (!mounted) {
        // Completion after navigation has no outgoing operation to own the file.
        await deleteTemporaryVoiceRecording(recording.path);
        return;
      }
      widget.onSend(
        VoiceNoteData(
          duration: recording.duration,
          waveform: List.of(_waveform),
          source: recording.path,
        ),
        recording.path,
      );
    } catch (error) {
      if (!mounted) return;
      _notifyError(error);
      widget.onCancel();
    }
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
              onTap: _ready && !_sending ? _send : null,
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
