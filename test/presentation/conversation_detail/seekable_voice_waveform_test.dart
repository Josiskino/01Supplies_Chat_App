import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/swipe_to_reply.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/seekable_voice_waveform.dart';

/// Stands in for the audio player: records the seeks the waveform asks for.
class _FakeVoicePlayer {
  _FakeVoicePlayer(this.duration, {this.position = Duration.zero});

  final Duration duration;
  Duration position;
  final List<Duration> seeks = [];

  void seek(Duration target) {
    seeks.add(target);
    position = target;
  }
}

const _width = 200.0;
const _label = 'Voice note position';

/// A minimal voice bubble: the waveform plus its time label, which shows the
/// scrubbed position while dragging like the real bubbles do.
class _Bubble extends StatefulWidget {
  const _Bubble({required this.player, this.enabled = true});

  final _FakeVoicePlayer player;
  final bool enabled;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
  Duration? _scrub;

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final scrub = _scrub;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _width,
          child: SeekableVoiceWaveform(
            amplitudes: const [0.3, 0.6, 0.9, 0.4],
            position: player.position,
            duration: player.duration,
            played: Colors.black,
            pending: Colors.grey,
            enabled: widget.enabled,
            semanticsLabel: _label,
            onScrub: (position) => setState(() => _scrub = position),
            onSeek: (target) => setState(() => player.seek(target)),
          ),
        ),
        Text(
          scrub == null
              ? formatVoiceSeekTime(player.position)
              : '${formatVoiceSeekTime(scrub)} / '
                    '${formatVoiceSeekTime(player.duration)}',
          key: const Key('label'),
        ),
      ],
    );
  }
}

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

Offset _at(WidgetTester tester, double fraction) {
  final rect = tester.getRect(find.byType(SeekableVoiceWaveform));
  return Offset(rect.left + rect.width * fraction, rect.center.dy);
}

String _labelText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('label'))).data!;

void main() {
  testWidgets('drag scrubs, then seeks once on release', (tester) async {
    final player = _FakeVoicePlayer(const Duration(seconds: 10));
    await tester.pumpWidget(_app(_Bubble(player: player)));

    final gesture = await tester.startGesture(_at(tester, 0.2));
    await gesture.moveTo(_at(tester, 0.45));
    await gesture.moveTo(_at(tester, 0.7));
    await tester.pump();

    expect(_labelText(tester), '0:07 / 0:10');
    expect(player.seeks, isEmpty);

    await gesture.up();
    await tester.pump();

    expect(player.seeks, hasLength(1));
    expect(player.seeks.single.inMilliseconds, closeTo(7000, 100));
    expect(_labelText(tester), '0:07');
  });

  testWidgets('tap seeks to the tapped position', (tester) async {
    final player = _FakeVoicePlayer(const Duration(seconds: 10));
    await tester.pumpWidget(_app(_Bubble(player: player)));

    await tester.tapAt(_at(tester, 0.5));
    await tester.pump();

    expect(player.seeks.single.inMilliseconds, closeTo(5000, 100));
  });

  testWidgets('drags past the edges clamp to 0 and the duration', (
    tester,
  ) async {
    final player = _FakeVoicePlayer(const Duration(seconds: 10));
    await tester.pumpWidget(_app(_Bubble(player: player)));

    await tester.dragFrom(_at(tester, 0.5), const Offset(_width * 2, 0));
    await tester.pump();
    expect(player.seeks.last, const Duration(seconds: 10));

    await tester.dragFrom(_at(tester, 0.5), const Offset(-_width * 2, 0));
    await tester.pump();
    expect(player.seeks.last, Duration.zero);
  });

  testWidgets('no seek while uploading or with an unknown duration', (
    tester,
  ) async {
    final uploading = _FakeVoicePlayer(const Duration(seconds: 10));
    await tester.pumpWidget(_app(_Bubble(player: uploading, enabled: false)));
    await tester.tapAt(_at(tester, 0.5));
    await tester.dragFrom(_at(tester, 0.2), const Offset(100, 0));
    await tester.pump();
    expect(uploading.seeks, isEmpty);

    final unknown = _FakeVoicePlayer(Duration.zero);
    await tester.pumpWidget(_app(_Bubble(player: unknown)));
    await tester.tapAt(_at(tester, 0.5));
    await tester.dragFrom(_at(tester, 0.2), const Offset(100, 0));
    await tester.pump();
    expect(unknown.seeks, isEmpty);
  });

  testWidgets('a vertical drag on the waveform still scrolls the list', (
    tester,
  ) async {
    final player = _FakeVoicePlayer(const Duration(seconds: 10));
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: controller,
            children: [
              _Bubble(player: player),
              for (var i = 0; i < 30; i++)
                SizedBox(height: 60, child: Text('$i')),
            ],
          ),
        ),
      ),
    );

    await tester.dragFrom(_at(tester, 0.5), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThan(0));
    expect(player.seeks, isEmpty);
  });

  testWidgets('swipe-to-reply works outside the waveform, not on it', (
    tester,
  ) async {
    final player = _FakeVoicePlayer(const Duration(seconds: 10));
    var replies = 0;
    await tester.pumpWidget(
      _app(
        SwipeToReply(
          onReply: () => replies++,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(key: Key('outside'), width: _width, height: 40),
              _Bubble(player: player),
            ],
          ),
        ),
      ),
    );

    await tester.dragFrom(
      tester.getCenter(find.byKey(const Key('outside'))),
      const Offset(75, 0),
    );
    await tester.pumpAndSettle();
    expect(replies, 1);
    expect(player.seeks, isEmpty);

    await tester.dragFrom(_at(tester, 0.2), const Offset(75, 0));
    await tester.pumpAndSettle();
    expect(replies, 1);
    expect(player.seeks, hasLength(1));
  });

  testWidgets('semantics slider steps 5 seconds, clamped', (tester) async {
    final semantics = tester.ensureSemantics();
    final player = _FakeVoicePlayer(
      const Duration(seconds: 10),
      position: const Duration(seconds: 2),
    );
    await tester.pumpWidget(_app(_Bubble(player: player)));

    expect(
      tester.getSemantics(find.byType(SeekableVoiceWaveform)),
      matchesSemantics(
        label: _label,
        value: '0:02',
        increasedValue: '0:07',
        decreasedValue: '0:00',
        isSlider: true,
        hasEnabledState: true,
        isEnabled: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );

    tester.semantics.increase(find.semantics.byLabel(_label));
    await tester.pump();
    expect(player.seeks.last, const Duration(seconds: 7));

    tester.semantics.increase(find.semantics.byLabel(_label));
    await tester.pump();
    expect(player.seeks.last, const Duration(seconds: 10));

    tester.semantics.decrease(find.semantics.byLabel(_label));
    await tester.pump();
    expect(player.seeks.last, const Duration(seconds: 5));

    semantics.dispose();
  });
}
