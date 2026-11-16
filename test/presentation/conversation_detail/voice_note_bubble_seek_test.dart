import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/services/audio_playback_service.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/seekable_voice_waveform.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/voice_note_bubble.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

class _FakePlayback implements AudioPlaybackService {
  final positions = StreamController<Duration>.broadcast();
  final durations = StreamController<Duration>.broadcast();
  final states = StreamController<bool>.broadcast();
  final completions = StreamController<void>.broadcast();
  final sources = <String>[];
  final seeks = <Duration>[];
  Completer<void>? seeking;
  bool fail = false;
  bool disposed = false;

  @override
  Stream<Duration> get position => positions.stream;
  @override
  Stream<Duration> get duration => durations.stream;
  @override
  Stream<bool> get playing => states.stream;
  @override
  Stream<void> get completed => completions.stream;

  @override
  Future<void> play(String source) async {
    sources.add(source);
    if (fail) throw StateError('expired');
    states.add(true);
  }

  @override
  Future<void> pause() async => states.add(false);

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
    final pending = seeking;
    if (pending != null) await pending.future;
  }

  @override
  Future<void> dispose() async => disposed = true;
}

Widget _app(
  _FakePlayback fake, {
  Future<String?> Function()? refresh,
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  theme: ThemeData(brightness: brightness),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 250,
        child: VoiceNoteBubble(
          voice: const VoiceNoteData(
            duration: Duration(seconds: 10),
            waveform: [.3, .5, .8],
            source: 'https://example.com/expired.m4a',
          ),
          foreground: Colors.black,
          accent: Colors.blue,
          playerFactory: () => fake,
          refreshSource: refresh,
        ),
      ),
    ),
  ),
);

Offset _at(WidgetTester tester, double fraction) {
  final rect = tester.getRect(find.byType(SeekableVoiceWaveform));
  return Offset(rect.left + rect.width * fraction, rect.center.dy);
}

void main() {
  testWidgets('seeking a failed note keeps its retry, which renews the link', (
    tester,
  ) async {
    final fake = _FakePlayback()..fail = true;
    var refreshes = 0;
    await tester.pumpWidget(
      _app(
        fake,
        refresh: () async {
          refreshes++;
          return 'https://example.com/fresh.m4a';
        },
      ),
    );
    await tester.tap(find.byIcon(CupertinoIcons.play_fill));
    await tester.pump();
    expect(find.byTooltip('Réessayer la lecture'), findsOneWidget);

    await tester.tapAt(_at(tester, 0.6));
    await tester.pump();
    expect(fake.seeks.single.inMilliseconds, closeTo(6000, 150));
    expect(find.byTooltip('Réessayer la lecture'), findsOneWidget);

    fake.fail = false;
    await tester.tap(find.byTooltip('Réessayer la lecture'));
    await tester.pump();
    expect(refreshes, 1);
    expect(fake.sources.last, 'https://example.com/fresh.m4a');
  });

  testWidgets('disposing the bubble while a seek is in flight is safe', (
    tester,
  ) async {
    final fake = _FakePlayback()..seeking = Completer<void>();
    await tester.pumpWidget(_app(fake));
    await tester.tapAt(_at(tester, 0.5));
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    fake.seeking!.complete();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(fake.disposed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a seek while paused keeps the note paused', (tester) async {
    final fake = _FakePlayback();
    await tester.pumpWidget(_app(fake));
    await tester.tap(find.byIcon(CupertinoIcons.play_fill));
    await tester.pump();
    await tester.tap(find.byIcon(CupertinoIcons.pause_fill));
    await tester.pump();

    await tester.tapAt(_at(tester, 0.3));
    await tester.pump();
    expect(fake.seeks.single.inMilliseconds, closeTo(3000, 150));
    expect(find.byIcon(CupertinoIcons.play_fill), findsOneWidget);
    expect(find.text('0:03'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits 320 px at text scale 1.3 while scrubbing '
        '(${brightness.name})', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: _app(_FakePlayback(), brightness: brightness),
        ),
      );
      final gesture = await tester.startGesture(_at(tester, 0.1));
      await gesture.moveTo(_at(tester, 0.6));
      await tester.pump();
      expect(find.text('0:06 / 0:10'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await gesture.up();
      await tester.pump();
    });
  }
}
