import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../../core/services/audio_playback_service.dart';
import '../../../../core/utils/localization_helper.dart';
import '../../../shared/models/conversation_view_data.dart';
import 'seekable_voice_waveform.dart';

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

  /// Position under the finger while the waveform is being scrubbed.
  Duration? _scrubPosition;

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

  /// Moves playback to [target], chosen on the waveform. A playing note
  /// continues from there; a paused or not yet started one will start there.
  Future<void> _seekTo(Duration target) async {
    // A failed note keeps its retry: the next tap renews the link first, then
    // starts from the chosen position.
    setState(() => _position = target);
    try {
      await _ensurePlayer().seek(target);
    } catch (_) {
      // Best effort: the position shown stays the requested one.
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
      _scrubPosition = null;
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
      mainAxisSize: MainAxisSize.max,
      children: [
        Tooltip(
          message: label,
          child: IconButton(
            tooltip: null,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
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
        Expanded(
          child: SeekableVoiceWaveform(
            key: const ValueKey('voice-waveform'),
            amplitudes: widget.voice.waveform,
            position: _position,
            duration: _duration,
            played: widget.accent,
            pending: widget.foreground.withValues(alpha: 0.35),
            enabled: !unavailable,
            // Same height as the play button: the bubble keeps its size.
            hitHeight: 40,
            semanticsLabel: AppLocalizations.of(context)?.voiceNotePosition,
            onScrub: (position) => setState(() => _scrubPosition = position),
            onSeek: (target) => unawaited(_seekTo(target)),
          ),
        ),
        const SizedBox(width: DesignTokens.spaceS),
        Text(
          _scrubPosition != null
              ? '${_format(_scrubPosition!)} / ${_format(_duration)}'
              : _format(
                  _playing || _position > Duration.zero ? _position : _duration,
                ),
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
