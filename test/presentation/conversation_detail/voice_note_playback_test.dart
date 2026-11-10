import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/services/audio_playback_service.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/voice_note_bubble.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

class FakePlayback implements AudioPlaybackService {
  final positions = StreamController<Duration>.broadcast();
  final durations = StreamController<Duration>.broadcast();
  final states = StreamController<bool>.broadcast();
  final completions = StreamController<void>.broadcast();
  String? source;
  int plays = 0;
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
  Future<void> play(String value) async {
    source = value;
    plays++;
    if (fail) throw StateError('unavailable');
    states.add(true);
  }

  @override
  Future<void> pause() async {
    states.add(false);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await positions.close();
    await durations.close();
    await states.close();
    await completions.close();
  }
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    FakePlayback fake, {
    String? source = 'https://example.com/a.m4a',
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: VoiceNoteBubble(
          voice: VoiceNoteData(
            duration: Duration.zero,
            waveform: const [.3, .5],
            source: source,
          ),
          foreground: Colors.black,
          accent: Colors.blue,
          playerFactory: () => fake,
        ),
      ),
    ),
  );
  testWidgets('plays actual source and follows decoder duration and position', (
    tester,
  ) async {
    final fake = FakePlayback();
    await pump(tester, fake);
    await tester.tap(find.byIcon(CupertinoIcons.play_fill));
    await tester.pump();
    expect(fake.source, 'https://example.com/a.m4a');
    fake.durations.add(const Duration(seconds: 12));
    fake.positions.add(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('0:03'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.pause_fill), findsOneWidget);
    fake.completions.add(null);
    await tester.pump();
    expect(find.text('0:12'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.play_fill), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(fake.disposed, isTrue);
  });
  testWidgets('failed playback exposes retry and retries the source', (
    tester,
  ) async {
    final fake = FakePlayback()..fail = true;
    await pump(tester, fake);
    await tester.tap(find.byIcon(CupertinoIcons.play_fill));
    await tester.pump();
    expect(find.byTooltip('Réessayer la lecture'), findsOneWidget);
    fake.fail = false;
    await tester.tap(find.byTooltip('Réessayer la lecture'));
    await tester.pump();
    expect(fake.plays, 2);
    expect(find.byIcon(CupertinoIcons.pause_fill), findsOneWidget);
  });
  testWidgets('missing audio source is unavailable instead of simulated', (
    tester,
  ) async {
    final fake = FakePlayback();
    await pump(tester, fake, source: null);
    expect(find.byTooltip('Audio indisponible'), findsOneWidget);
    expect(fake.plays, 0);
  });
  testWidgets('decoder stream failure becomes a retryable error', (
    tester,
  ) async {
    final fake = FakePlayback();
    await pump(tester, fake);
    await tester.tap(find.byIcon(CupertinoIcons.play_fill));
    await tester.pump();
    fake.positions.addError(StateError('decoder failed'));
    await tester.pump();
    expect(find.byTooltip('Réessayer la lecture'), findsOneWidget);
  });
  testWidgets('explicit retry refreshes an expired signed audio URL', (
    tester,
  ) async {
    final fake = FakePlayback()..fail = true;
    var refreshes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoiceNoteBubble(
            voice: const VoiceNoteData(
              duration: Duration.zero,
              waveform: [.4],
              source: 'https://example.com/expired.m4a',
            ),
            foreground: Colors.black,
            accent: Colors.blue,
            playerFactory: () => fake,
            refreshSource: () async {
              refreshes++;
              return 'https://example.com/fresh.m4a';
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(CupertinoIcons.play_fill));
    await tester.pump();
    expect(refreshes, 0);
    expect(fake.source, 'https://example.com/expired.m4a');
    fake.fail = false;
    await tester.tap(find.byTooltip('Réessayer la lecture'));
    await tester.pump();
    expect(refreshes, 1);
    expect(fake.source, 'https://example.com/fresh.m4a');
    expect(find.byIcon(CupertinoIcons.pause_fill), findsOneWidget);
  });

  testWidgets(
    'refresh rebuild keeps the pending retry attached to the new URL',
    (tester) async {
      final fake = FakePlayback()..fail = true;
      final fresh = Completer<String?>();
      Future<void> render(String source) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceNoteBubble(
              voice: VoiceNoteData(
                duration: Duration.zero,
                waveform: const [.4],
                source: source,
              ),
              foreground: Colors.black,
              accent: Colors.blue,
              playerFactory: () => fake,
              refreshSource: () => fresh.future,
            ),
          ),
        ),
      );
      await render('https://example.com/expired.m4a');
      await tester.tap(find.byIcon(CupertinoIcons.play_fill));
      await tester.pump();
      fake.fail = false;
      await tester.tap(find.byTooltip('Réessayer la lecture'));
      await tester.pump();
      await render('https://example.com/fresh.m4a');
      fresh.complete('https://example.com/fresh.m4a');
      await tester.pump();
      expect(fake.source, 'https://example.com/fresh.m4a');
      expect(find.byIcon(CupertinoIcons.pause_fill), findsOneWidget);
      expect(fake.disposed, isFalse);
    },
  );
}
