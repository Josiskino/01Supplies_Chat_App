import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

abstract interface class VoiceCaptureDevice {
  Future<bool> hasPermission();
  Future<void> start(String path);
  Future<double> amplitude();
  Future<String?> stop();
  Future<void> cancel();
  Future<void> dispose();
}

class MicrophoneCaptureDevice implements VoiceCaptureDevice {
  final AudioRecorder _recorder = AudioRecorder();
  @override
  Future<bool> hasPermission() => _recorder.hasPermission();
  @override
  Future<void> start(String path) => _recorder.start(
    const RecordConfig(
      encoder: AudioEncoder.aacLc,
      sampleRate: 44100,
      bitRate: 96000,
    ),
    path: path,
  );
  @override
  Future<double> amplitude() async =>
      (((await _recorder.getAmplitude()).current + 45) / 45).clamp(0.05, 1.0);
  @override
  Future<String?> stop() => _recorder.stop();
  @override
  Future<void> cancel() => _recorder.cancel();
  @override
  Future<void> dispose() => _recorder.dispose();
}

class VoiceRecordingException implements Exception {
  const VoiceRecordingException(this.message);
  final String message;
}

class CapturedVoiceRecording {
  const CapturedVoiceRecording(this.path, this.duration);
  final String path;
  final Duration duration;
}

Future<String> _createRecordingPath() async {
  final directory = await getTemporaryDirectory();
  return '${directory.path}/voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
}

/// Only recordings created by this app may be removed. Picked files are untouched.
Future<void> deleteTemporaryVoiceRecording(String path) async {
  try {
    final root = await getTemporaryDirectory();
    final file = File(path);
    if (file.parent.absolute.path != root.absolute.path ||
        !RegExp(r'^voice_\d+\.m4a$').hasMatch(file.uri.pathSegments.last)) {
      return;
    }
    if (await file.exists()) await file.delete();
  } catch (_) {
    /* Cleanup must not turn an acknowledged send into a failure. */
  }
}

/// Serializes native start/stop/dispose and transfers ownership only on finish.
class VoiceRecordingSession {
  VoiceRecordingSession({
    VoiceCaptureDevice? device,
    Future<String> Function()? createPath,
    Future<void> Function(String)? deleteFile,
    this.minimumDuration = const Duration(milliseconds: 700),
  }) : _device = device ?? MicrophoneCaptureDevice(),
       _createPath = createPath ?? _createRecordingPath,
       _deleteFile = deleteFile ?? deleteTemporaryVoiceRecording;
  final VoiceCaptureDevice _device;
  final Future<String> Function() _createPath;
  final Future<void> Function(String) _deleteFile;
  final Duration minimumDuration;
  final Stopwatch _clock = Stopwatch();
  Future<bool>? _starting;
  Future<CapturedVoiceRecording>? _finishing;
  Future<void>? _closing;
  String? _path;
  bool _closed = false;
  bool _active = false;
  bool _transferred = false;
  Duration get elapsed => _clock.elapsed;
  Future<bool> start() => _starting ??= _start();
  Future<bool> _start() async {
    if (!await _device.hasPermission()) {
      if (_closed) return false;
      throw const VoiceRecordingException(
        'Autorisez le microphone pour enregistrer une note vocale.',
      );
    }
    if (_closed) return false;
    _path = await _createPath();
    if (_closed) return false;
    await _device.start(_path!);
    _active = true;
    if (_closed) return false;
    _clock.start();
    return true;
  }

  Future<double> amplitude() =>
      _active && !_closed ? _device.amplitude() : Future.value(0.05);
  Future<CapturedVoiceRecording> finish() => _finishing ??= _finish();
  Future<CapturedVoiceRecording> _finish() async {
    if (!await start() || _closed || !_active) {
      throw const VoiceRecordingException('Enregistrement indisponible.');
    }
    final path = await _device.stop() ?? _path;
    _active = false;
    _clock.stop();
    if (_closed || path == null) {
      throw const VoiceRecordingException('Enregistrement interrompu.');
    }
    if (elapsed < minimumDuration) {
      throw const VoiceRecordingException(
        'Le vocal est trop court. Enregistrez au moins une seconde.',
      );
    }
    _transferred = true;
    return CapturedVoiceRecording(path, elapsed);
  }

  Future<void> close() {
    _closed = true;
    return _closing ??= _close();
  }

  Future<void> _close() async {
    try {
      await _starting;
    } catch (_) {
      /* Failed start still owns cleanup. */
    }
    try {
      await _finishing;
    } catch (_) {
      /* Failed stop still owns cleanup. */
    }
    _clock.stop();
    if (!_transferred) {
      if (_active) {
        try {
          await _device.cancel();
        } catch (_) {}
        _active = false;
      }
      final path = _path;
      if (path != null) {
        try {
          await _deleteFile(path);
        } catch (_) {}
      }
    }
    try {
      await _device.dispose();
    } catch (_) {
      /* Detached native resource. */
    }
  }
}
