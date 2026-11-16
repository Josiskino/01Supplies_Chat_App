import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/seekable_voice_waveform.dart';

/// Hosts the waveform like a real bubble: the scrubbed position lives in the
/// parent state, and a [Container] (a component widget) sits in between, so
/// a callback fired while the parent rebuilds would hit "setState during
/// build".
class _Host extends StatefulWidget {
  const _Host({
    required this.duration,
    this.position = Duration.zero,
    this.enabled = true,
    this.width = 200,
    this.seeks,
  });

  final Duration duration;
  final Duration position;
  final bool enabled;
  final double width;
  final List<Duration>? seeks;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  Duration? scrub;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: widget.width,
          padding: EdgeInsets.zero,
          child: SeekableVoiceWaveform(
            amplitudes: const [0.2, 0.9, 0.5, 0.7],
            position: widget.position,
            duration: widget.duration,
            played: Colors.black,
            pending: Colors.grey,
            enabled: widget.enabled,
            onScrub: (value) => setState(() => scrub = value),
            onSeek: (target) => widget.seeks?.add(target),
          ),
        ),
        Text(
          scrub == null ? '-' : formatVoiceSeekTime(scrub!),
          key: const Key('scrub'),
        ),
      ],
    );
  }
}

Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(body: Center(child: child)),
      ),
    );

Offset _at(WidgetTester tester, double fraction) {
  final rect = tester.getRect(find.byType(SeekableVoiceWaveform));
  return Offset(rect.left + rect.width * fraction, rect.center.dy);
}

double _paintedProgress(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(SeekableVoiceWaveform),
      matching: find.byType(CustomPaint),
    ),
  );
  return (paint.painter! as VoiceWaveformPainter).progress;
}

String _scrubText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('scrub'))).data!;

void main() {
  group('durations', () {
    testWidgets('a note shorter than a second still seeks in ms', (
      tester,
    ) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _app(_Host(duration: const Duration(milliseconds: 600), seeks: seeks)),
      );
      await tester.tapAt(_at(tester, 0.5));
      await tester.pump();
      expect(seeks.single.inMilliseconds, closeTo(300, 10));
    });

    testWidgets('a two hour note seeks and formats minutes past 59', (
      tester,
    ) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _app(_Host(duration: const Duration(hours: 2), seeks: seeks)),
      );
      final gesture = await tester.startGesture(_at(tester, 0.1));
      await gesture.moveTo(_at(tester, 0.5));
      await tester.pump();
      expect(_scrubText(tester), '60:00');
      await gesture.up();
      await tester.pump();
      expect(seeks.single.inMinutes, closeTo(60, 1));
      expect(formatVoiceSeekTime(const Duration(minutes: 75)), '75:00');
    });

    testWidgets('seeking turns on when the duration arrives late', (
      tester,
    ) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _app(_Host(duration: Duration.zero, seeks: seeks)),
      );
      await tester.tapAt(_at(tester, 0.5));
      await tester.pump();
      expect(seeks, isEmpty);

      await tester.pumpWidget(
        _app(_Host(duration: const Duration(seconds: 8), seeks: seeks)),
      );
      await tester.tapAt(_at(tester, 0.5));
      await tester.pump();
      expect(seeks.single.inMilliseconds, closeTo(4000, 100));
    });

    testWidgets('a position past the duration paints full, never more', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const _Host(
            duration: Duration(seconds: 4),
            position: Duration(seconds: 9),
          ),
        ),
      );
      expect(_paintedProgress(tester), 1.0);
    });
  });

  group('scrub state', () {
    testWidgets('the painted part follows the finger, not the player', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const _Host(
            duration: Duration(seconds: 10),
            position: Duration(seconds: 1),
          ),
        ),
      );
      final gesture = await tester.startGesture(_at(tester, 0.2));
      await gesture.moveTo(_at(tester, 0.8));
      await tester.pump();
      // The player reports a new position mid-drag: the finger still wins.
      await tester.pumpWidget(
        _app(
          const _Host(
            duration: Duration(seconds: 10),
            position: Duration(seconds: 2),
          ),
        ),
      );
      expect(_paintedProgress(tester), closeTo(0.8, 0.01));
      await gesture.up();
      await tester.pump();
    });

    testWidgets('losing the ability to seek mid-drag clears the scrub '
        'without seeking or throwing', (tester) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _app(_Host(duration: const Duration(seconds: 10), seeks: seeks)),
      );
      final gesture = await tester.startGesture(_at(tester, 0.2));
      await gesture.moveTo(_at(tester, 0.6));
      await tester.pump();
      expect(_scrubText(tester), '0:06');

      await tester.pumpWidget(
        _app(
          _Host(
            duration: const Duration(seconds: 10),
            enabled: false,
            seeks: seeks,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(_scrubText(tester), '-');

      await gesture.up();
      await tester.pump();
      expect(seeks, isEmpty);
    });

    testWidgets('removing the waveform mid-drag does not seek', (tester) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _app(_Host(duration: const Duration(seconds: 10), seeks: seeks)),
      );
      final gesture = await tester.startGesture(_at(tester, 0.2));
      await gesture.moveTo(_at(tester, 0.6));
      await tester.pump();
      await tester.pumpWidget(_app(const SizedBox()));
      await gesture.up();
      await tester.pump();
      expect(seeks, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  group('layout and platforms', () {
    testWidgets('RTL: the touched spot matches the painted progress', (
      tester,
    ) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _app(
          _Host(duration: const Duration(seconds: 10), seeks: seeks),
          direction: TextDirection.rtl,
        ),
      );
      final gesture = await tester.startGesture(_at(tester, 0.5));
      await gesture.moveTo(_at(tester, 0.3));
      await tester.pump();
      // Bars are painted from the left in both directions, so the finger
      // position maps to the same fraction.
      expect(_paintedProgress(tester), closeTo(0.3, 0.01));
      await gesture.up();
      await tester.pump();
      expect(seeks.single.inMilliseconds, closeTo(3000, 100));
    });

    testWidgets('touch area is taller than the bars, and reacts there', (
      tester,
    ) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _app(_Host(duration: const Duration(seconds: 10), seeks: seeks)),
      );
      final rect = tester.getRect(find.byType(SeekableVoiceWaveform));
      expect(rect.height, inInclusiveRange(32, 40));
      // 2 px from the top edge: outside the 26 px bars, inside the target.
      await tester.tapAt(Offset(rect.center.dx, rect.top + 2));
      await tester.pump();
      expect(seeks, hasLength(1));
    });

    testWidgets('fits a 320 px screen at text scale 1.3', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: _app(const _Host(duration: Duration(seconds: 10), width: 150)),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    for (final platform in TargetPlatform.values) {
      final mobile =
          platform == TargetPlatform.android || platform == TargetPlatform.iOS;
      testWidgets('selection haptic on drag start: '
          '${mobile ? 'yes' : 'no'} on ${platform.name}', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        final haptics = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              haptics.add(call.arguments as String);
            }
            return null;
          },
        );
        await tester.pumpWidget(
          _app(const _Host(duration: Duration(seconds: 10))),
        );
        await tester.dragFrom(_at(tester, 0.2), const Offset(60, 0));
        await tester.pump();
        expect(
          haptics,
          mobile ? ['HapticFeedbackType.selectionClick'] : isEmpty,
        );
        debugDefaultTargetPlatformOverride = null;
      });
    }

    testWidgets('a long press on the waveform reaches the bubble menu', (
      tester,
    ) async {
      final seeks = <Duration>[];
      var longPresses = 0;
      await tester.pumpWidget(
        _app(
          GestureDetector(
            onLongPress: () => longPresses++,
            child: _Host(duration: const Duration(seconds: 10), seeks: seeks),
          ),
        ),
      );
      await tester.longPressAt(_at(tester, 0.5));
      await tester.pump();
      expect(longPresses, 1);
      expect(seeks, isEmpty);
    });

    testWidgets('mouse drag scrubs like touch', (tester) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _app(_Host(duration: const Duration(seconds: 10), seeks: seeks)),
      );
      final gesture = await tester.startGesture(
        _at(tester, 0.1),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(_at(tester, 0.9));
      await gesture.up();
      await tester.pump();
      expect(seeks.single.inMilliseconds, closeTo(9000, 100));
    });
  });
}
