import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/services/audio_playback_service.dart';

/// Audio player double: records what the service asks, and can hold `play`
/// in a loading phase like a remote source does.
class _FakeAudioPlayer extends Fake implements AudioPlayer {
  PlayerState _state = PlayerState.stopped;
  Completer<void>? loading;
  final playedFrom = <Duration?>[];
  final seeks = <Duration>[];
  int resumes = 0;

  @override
  PlayerState get state => _state;

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    playedFrom.add(position);
    final pending = loading;
    if (pending != null) await pending.future;
    _state = PlayerState.playing;
  }

  @override
  Future<void> pause() async => _state = PlayerState.paused;

  @override
  Future<void> resume() async {
    resumes++;
    _state = PlayerState.playing;
  }

  @override
  Future<void> seek(Duration position) async => seeks.add(position);

  void finish() => _state = PlayerState.completed;
}

const _url = 'https://example.com/note.m4a';

void main() {
  test('a position picked before the first play is where it starts, '
      'once', () async {
    final player = _FakeAudioPlayer();
    final service = DeviceAudioPlaybackService(player: player);

    await service.seek(const Duration(seconds: 4));
    expect(player.seeks, isEmpty);

    await service.play(_url);
    expect(player.playedFrom.single, const Duration(seconds: 4));

    player.finish();
    await service.play(_url);
    expect(player.playedFrom.last, isNull);
  });

  test(
    'a seek made while the first play loads is applied once it plays',
    () async {
      final player = _FakeAudioPlayer()..loading = Completer<void>();
      final service = DeviceAudioPlaybackService(player: player);

      final playing = service.play(_url);
      await service.seek(const Duration(seconds: 7));
      expect(player.seeks, isEmpty);

      player.loading!.complete();
      await playing;
      expect(player.seeks, [const Duration(seconds: 7)]);
    },
  );

  test('a playing or paused note seeks directly', () async {
    final player = _FakeAudioPlayer();
    final service = DeviceAudioPlaybackService(player: player);
    await service.play(_url);

    await service.seek(const Duration(seconds: 2));
    expect(player.seeks, [const Duration(seconds: 2)]);

    await service.pause();
    await service.seek(const Duration(seconds: 5));
    expect(player.seeks.last, const Duration(seconds: 5));
    expect(player.state, PlayerState.paused);

    // Resuming does not reload nor jump back.
    await service.play(_url);
    expect(player.resumes, 1);
    expect(player.playedFrom, hasLength(1));
  });

  test('a finished note restarts from the position picked after it', () async {
    final player = _FakeAudioPlayer();
    final service = DeviceAudioPlaybackService(player: player);
    await service.play(_url);
    player.finish();

    await service.seek(const Duration(seconds: 3));
    expect(player.seeks, isEmpty);

    await service.play(_url);
    expect(player.playedFrom.last, const Duration(seconds: 3));
  });
}
