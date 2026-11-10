import 'package:audioplayers/audioplayers.dart';

/// Decoder boundary: presentation follows the audio device, never an animation.
abstract interface class AudioPlaybackService {
  Stream<Duration> get position;
  Stream<Duration> get duration;
  Stream<bool> get playing;
  Stream<void> get completed;
  Future<void> play(String source);
  Future<void> pause();
  Future<void> dispose();
}

class DeviceAudioPlaybackService implements AudioPlaybackService {
  final AudioPlayer _player = AudioPlayer();
  String? _source;

  @override
  Stream<Duration> get position => _player.onPositionChanged;
  @override
  Stream<Duration> get duration => _player.onDurationChanged;
  @override
  Stream<bool> get playing =>
      _player.onPlayerStateChanged.map((state) => state == PlayerState.playing);
  @override
  Stream<void> get completed => _player.onPlayerComplete;

  @override
  Future<void> play(String source) async {
    if (_source == source && _player.state == PlayerState.paused) {
      await _player.resume();
      return;
    }
    final uri = Uri.tryParse(source);
    final remote = uri?.scheme == 'https' || uri?.scheme == 'http';
    await _player.play(remote ? UrlSource(source) : DeviceFileSource(source));
    _source = source;
  }

  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> dispose() => _player.dispose();
}

/// A voice message takes the foreground from the previous one across threads.
class VoicePlaybackCoordinator {
  static final shared = VoicePlaybackCoordinator();
  AudioPlaybackService? _active;
  Future<void> activate(AudioPlaybackService player) async {
    final previous = _active;
    _active = player;
    if (previous != null && !identical(previous, player)) {
      await previous.pause();
    }
  }

  void release(AudioPlaybackService player) {
    if (identical(_active, player)) _active = null;
  }
}
