import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../../core/services/audio_playback_service.dart';
import '../../../shared/models/conversation_view_data.dart';

class VoiceNoteBubble extends StatefulWidget {
  const VoiceNoteBubble({
    super.key,
    required this.voice,
    required this.foreground,
    required this.accent,
    this.playerFactory,
    this.refreshSource,
  });
  final VoiceNoteData voice;
  final Color foreground;
  final Color accent;
  final AudioPlaybackService Function()? playerFactory;

  /// Re-signs a remote attachment after an explicit retry, when available.
  final Future<String?> Function()? refreshSource;
  @override
  State<VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<VoiceNoteBubble> {
  AudioPlaybackService? _player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _loading = false;
  bool _error = false;
  int _generation = 0;
  bool _refreshing = false;
  String? _playbackSource;

  @override
  void initState() {
    super.initState();
    _duration = widget.voice.duration;
    _playbackSource = widget.voice.source;
  }

  AudioPlaybackService _ensurePlayer() {
    if (_player != null) return _player!;
    final player = widget.playerFactory?.call() ?? DeviceAudioPlaybackService();
    _player = player;
    _subscriptions.addAll([
      player.position.listen((value) {
        if (mounted) setState(() => _position = value);
      }, onError: _onPlaybackError),
      player.duration.listen((value) {
        if (mounted) setState(() => _duration = value);
      }, onError: _onPlaybackError),
      player.playing.listen((value) {
        if (mounted) setState(() => _playing = value);
      }, onError: _onPlaybackError),
      player.completed.listen((_) {
        if (mounted) {
          setState(() {
            _playing = false;
            _position = Duration.zero;
          });
        }
      }, onError: _onPlaybackError),
    ]);
    return player;
  }

  void _onPlaybackError(Object error, StackTrace stack) {
    if (!mounted) return;
    setState(() {
      _playing = false;
      _loading = false;
      _error = true;
    });
  }

  @visibleForTesting
  double get playbackProgress => _duration.inMilliseconds <= 0
      ? 0
      : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);

  Future<void> _toggle() async {
    var source = _playbackSource;
    if (source == null || source.isEmpty || _loading) return;
    final retry = _error;
    final generation = _generation;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      if (retry && widget.refreshSource != null) {
        _refreshing = true;
        final refreshed = await widget.refreshSource!();
        if (!mounted || generation != _generation) return;
        source = refreshed?.isNotEmpty == true ? refreshed! : _playbackSource!;
        _playbackSource = source;
      }
      final player = _ensurePlayer();
      if (_playing) {
        await player.pause();
      } else {
        await VoicePlaybackCoordinator.shared.activate(player);
        if (!mounted || generation != _generation) return;
        await player.play(source);
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = true;
          _playing = false;
        });
      }
    } finally {
      if (mounted && generation == _generation) {
        _refreshing = false;
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _releasePlayer() async {
    final player = _player;
    _player = null;
    if (player != null) VoicePlaybackCoordinator.shared.release(player);
    final subscriptions = List<StreamSubscription<dynamic>>.of(_subscriptions);
    _subscriptions.clear();
    await Future.wait(subscriptions.map((sub) => sub.cancel()));
    if (player != null) {
      try {
        await player.dispose();
      } catch (_) {
        /* Already detached. */
      }
    }
  }

  @override
  void didUpdateWidget(covariant VoiceNoteBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.voice.source != widget.voice.source) {
      _playbackSource = widget.voice.source;
      // Refreshing the thread can deliver the new URL before its future
      // completes. Keep that retry alive and let it start the refreshed source.
      if (_refreshing) {
        _position = Duration.zero;
        _duration = widget.voice.duration;
        return;
      }
      _generation++;
      unawaited(_releasePlayer());
      _position = Duration.zero;
      _duration = widget.voice.duration;
      _playing = false;
      _loading = false;
      _error = false;
    }
  }

  @override
  void dispose() {
    _generation++;
    unawaited(_releasePlayer());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unavailable =
        widget.voice.source == null || widget.voice.source!.isEmpty;
    final label = unavailable
        ? 'Audio indisponible'
        : _error
        ? 'Réessayer la lecture'
        : _playing
        ? 'Mettre en pause'
        : 'Lire la note vocale';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: label,
          child: IconButton(
            tooltip: null,
            onPressed: unavailable || _loading ? null : _toggle,
            icon: _loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.foreground,
                    ),
                  )
                : Icon(
                    _error
                        ? CupertinoIcons.arrow_clockwise
                        : _playing
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                    size: 26,
                    color: widget.foreground,
                  ),
          ),
        ),
        const SizedBox(width: DesignTokens.spaceS),
        Flexible(
          child: CustomPaint(
            size: const Size(150, 26),
            painter: _WaveformPainter(
              amplitudes: widget.voice.waveform,
              progress: playbackProgress,
              played: widget.accent,
              pending: widget.foreground.withValues(alpha: 0.35),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.spaceS),
        Text(
          _format(_playing ? _position : _duration),
          style: Theme.of(context).textTheme.labelSmall
              ?.merge(AppleType.caption1)
              .copyWith(color: widget.foreground.withValues(alpha: 0.75)),
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
