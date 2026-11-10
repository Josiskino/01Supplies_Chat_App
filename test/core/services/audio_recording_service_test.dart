import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/services/audio_recording_service.dart';

class FakeCapture implements VoiceCaptureDevice {
  Completer<bool>? permission;
  Completer<void>? starting;
  int starts = 0, stops = 0, cancels = 0, disposes = 0;
  @override
  Future<bool> hasPermission() => permission?.future ?? Future.value(true);
  @override
  Future<void> start(String path) async {
    starts++;
    await starting?.future;
  }

  @override
  Future<double> amplitude() async => .5;
  @override
  Future<String?> stop() async {
    stops++;
    return '/tmp/voice_test.m4a';
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }

  @override
  Future<void> dispose() async {
    disposes++;
  }
}

void main() {
  test('closing during permission prevents microphone start', () async {
    final device = FakeCapture()..permission = Completer<bool>();
    final session = VoiceRecordingSession(
      device: device,
      createPath: () async => '/tmp/voice_test.m4a',
      deleteFile: (_) async {},
    );
    final start = session.start();
    final close = session.close();
    device.permission!.complete(true);
    expect(await start, isFalse);
    await close;
    expect(device.starts, 0);
    expect(device.disposes, 1);
  });
  test(
    'closing while native start is pending cancels and deletes once',
    () async {
      final device = FakeCapture()..starting = Completer<void>();
      final deleted = <String>[];
      final session = VoiceRecordingSession(
        device: device,
        createPath: () async => '/tmp/voice_test.m4a',
        deleteFile: (p) async {
          deleted.add(p);
        },
      );
      final start = session.start();
      await Future<void>.delayed(Duration.zero);
      final close = session.close();
      device.starting!.complete();
      expect(await start, isFalse);
      await close;
      expect(device.cancels, 1);
      expect(device.disposes, 1);
      expect(deleted, ['/tmp/voice_test.m4a']);
    },
  );
  test(
    'successful finish transfers file ownership and closes without deleting',
    () async {
      final device = FakeCapture();
      final deleted = <String>[];
      final session = VoiceRecordingSession(
        device: device,
        minimumDuration: Duration.zero,
        createPath: () async => '/tmp/voice_test.m4a',
        deleteFile: (p) async {
          deleted.add(p);
        },
      );
      expect(await session.start(), isTrue);
      final recording = await session.finish();
      expect(recording.path, '/tmp/voice_test.m4a');
      await session.close();
      expect(deleted, isEmpty);
      expect(device.stops, 1);
      expect(device.disposes, 1);
    },
  );
  test('denied permission is actionable and never starts recording', () async {
    final device = FakeCapture()
      ..permission = Completer<bool>()
      ..permission!.complete(false);
    final session = VoiceRecordingSession(
      device: device,
      createPath: () async => '/tmp/voice_test.m4a',
      deleteFile: (_) async {},
    );
    await expectLater(session.start(), throwsA(isA<VoiceRecordingException>()));
    await session.close();
    expect(device.starts, 0);
  });
}
