import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Voice note waveform the user can drag or tap to move through the note.
///
/// While the finger moves, the played part follows it and [onScrub] reports
/// the position under the finger so the bubble can show it in its time label.
/// The player is only moved once, through [onSeek], when the finger lifts (or
/// on a simple tap).
///
/// Horizontal drags that start on the waveform are claimed by its own
/// [HorizontalDragGestureRecognizer]: the list keeps scrolling vertically and
/// swipe-to-reply keeps working everywhere else in the bubble. When seeking is
/// impossible (note still uploading, unknown duration), no gesture is
/// registered at all so the parent gestures behave as before.
class SeekableVoiceWaveform extends StatefulWidget {
  const SeekableVoiceWaveform({
    super.key,
    required this.amplitudes,
    required this.position,
    required this.duration,
    required this.played,
    required this.pending,
    required this.onSeek,
    this.onScrub,
    this.enabled = true,
    this.height = 26,
    this.hitHeight = 36,
    this.semanticsLabel,
    this.seekStep = const Duration(seconds: 5),
  });

  /// Normalised amplitudes, 0 to 1.
  final List<double> amplitudes;

  /// Current playback position.
  final Duration position;

  /// Total length of the note; seeking is disabled while it is zero.
  final Duration duration;
  final Color played;
  final Color pending;

  /// Called with the target position on tap, at the end of a drag and on the
  /// accessibility increase/decrease actions. Always within 0..[duration].
  final ValueChanged<Duration> onSeek;

  /// Position under the finger while scrubbing, then null when it ends.
  final ValueChanged<Duration?>? onScrub;

  /// False while the note cannot be played (uploading, no source).
  final bool enabled;

  /// Visual height of the bars.
  final double height;

  /// Height of the touch area, centred on the bars. Never smaller than
  /// [height].
  final double hitHeight;

  /// Accessibility label of the slider.
  final String? semanticsLabel;

  /// Step of the accessibility increase/decrease actions.
  final Duration seekStep;

  bool get canSeek => enabled && duration > Duration.zero;

  @override
  State<SeekableVoiceWaveform> createState() => _SeekableVoiceWaveformState();
}

class _SeekableVoiceWaveformState extends State<SeekableVoiceWaveform> {
  /// Fraction under the finger while dragging, null otherwise.
  double? _scrubFraction;
  double _width = 0;

  @override
  void didUpdateWidget(covariant SeekableVoiceWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_scrubFraction != null && !widget.canSeek) {
      _scrubFraction = null;
      // The parent is building right now: calling it back synchronously
      // would be a setState during build. Tell it once the frame is done.
      final onScrub = widget.onScrub;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) onScrub?.call(null);
      });
    }
  }

  double _fractionAt(Offset localPosition) {
    if (_width <= 0) return 0;
    return (localPosition.dx / _width).clamp(0.0, 1.0);
  }

  Duration _positionAt(double fraction) => Duration(
    milliseconds: (widget.duration.inMilliseconds * fraction).round(),
  );

  Duration _clamp(Duration value) {
    if (value < Duration.zero) return Duration.zero;
    if (value > widget.duration) return widget.duration;
    return value;
  }

  void _scrubTo(Offset localPosition) {
    final fraction = _fractionAt(localPosition);
    setState(() => _scrubFraction = fraction);
    widget.onScrub?.call(_positionAt(fraction));
  }

  void _onDragStart(DragStartDetails details) {
    if (!widget.canSeek) return;
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      HapticFeedback.selectionClick();
    }
    _scrubTo(details.localPosition);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_scrubFraction == null) return;
    _scrubTo(details.localPosition);
  }

  void _onDragEnd(DragEndDetails details) {
    final fraction = _scrubFraction;
    if (fraction == null) return;
    setState(() => _scrubFraction = null);
    widget.onScrub?.call(null);
    if (widget.canSeek) widget.onSeek(_positionAt(fraction));
  }

  void _onDragCancel() {
    if (_scrubFraction == null) return;
    setState(() => _scrubFraction = null);
    widget.onScrub?.call(null);
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.canSeek) return;
    widget.onSeek(_positionAt(_fractionAt(details.localPosition)));
  }

  void _step(Duration delta) {
    if (!widget.canSeek) return;
    widget.onSeek(_clamp(widget.position + delta));
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.duration.inMilliseconds;
    final progress =
        _scrubFraction ??
        (total > 0 ? widget.position.inMilliseconds / total : 0.0);
    final hitHeight = widget.hitHeight < widget.height
        ? widget.height
        : widget.hitHeight;

    Widget child = SizedBox(
      height: hitHeight,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _width = constraints.maxWidth;
          return Center(
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
              child: CustomPaint(
                painter: VoiceWaveformPainter(
                  amplitudes: widget.amplitudes,
                  progress: progress.clamp(0.0, 1.0),
                  played: widget.played,
                  pending: widget.pending,
                ),
              ),
            ),
          );
        },
      ),
    );

    if (widget.canSeek) {
      child = RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: <Type, GestureRecognizerFactory>{
          HorizontalDragGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                HorizontalDragGestureRecognizer
              >(HorizontalDragGestureRecognizer.new, (recognizer) {
                recognizer
                  ..dragStartBehavior = DragStartBehavior.down
                  ..onStart = _onDragStart
                  ..onUpdate = _onDragUpdate
                  ..onEnd = _onDragEnd
                  ..onCancel = _onDragCancel;
              }),
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                TapGestureRecognizer.new,
                (recognizer) => recognizer.onTapUp = _onTapUp,
              ),
        },
        child: MouseRegion(cursor: SystemMouseCursors.click, child: child),
      );
    }

    final shown = _scrubFraction != null
        ? _positionAt(_scrubFraction!)
        : _clamp(widget.position);
    return Semantics(
      container: true,
      slider: true,
      enabled: widget.canSeek,
      label: widget.semanticsLabel,
      value: formatVoiceSeekTime(shown),
      increasedValue: formatVoiceSeekTime(_clamp(shown + widget.seekStep)),
      decreasedValue: formatVoiceSeekTime(_clamp(shown - widget.seekStep)),
      onIncrease: widget.canSeek ? () => _step(widget.seekStep) : null,
      onDecrease: widget.canSeek ? () => _step(-widget.seekStep) : null,
      child: ExcludeSemantics(child: child),
    );
  }
}

/// `m:ss` used by the accessibility value of [SeekableVoiceWaveform].
String formatVoiceSeekTime(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Voice note bars (3 px wide), the played part painted in [played].
class VoiceWaveformPainter extends CustomPainter {
  const VoiceWaveformPainter({
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
    final count = (size.width / step).floor().clamp(1, 1000);
    final spacing = count > 1 ? (size.width - barWidth) / (count - 1) : 0.0;

    void drawBars(Paint paint) {
      for (var i = 0; i < count; i++) {
        // Resampling: the stored waveform is finer than the number of bars
        // that fit in the bubble.
        final amplitude = amplitudes[(i * amplitudes.length / count).floor()];
        // Minimum height: a zero bar would leave a hole in the drawing.
        final height = (size.height * amplitude).clamp(3.0, size.height);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              i * spacing,
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

    // Two passes clipped at the pixel rather than a colour per bar: the bar
    // under the playhead is coloured partially, so the motion is continuous.
    drawBars(Paint()..color = pending);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    drawBars(Paint()..color = played);
    canvas.restore();
  }

  @override
  bool shouldRepaint(VoiceWaveformPainter old) =>
      old.progress != progress ||
      old.played != played ||
      old.pending != pending ||
      old.amplitudes != amplitudes;
}
