import 'package:audioplayers/audioplayers.dart';

/// Decoder boundary: presentation follows the audio device, never an animation.
abstract interface class AudioPlaybackService {
  Stream<Duration> get position;
  Stream<Duration> get duration;
  Stream<bool> get playing;
  Stream<void> get completed;
  Future<void> play(String source);
  Future<void> pause();

  /// Moves playback to [position]. Before the source is loaded (or once it
  /// has finished), the position is kept and the next [play] starts there.
  Future<void> seek(Duration position);
  Future<void> dispose();
}

class DeviceAudioPlaybackService implements AudioPlaybackService {
  /// [player] is for tests; a real one is created otherwise.
  DeviceAudioPlaybackService({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  String? _source;

  /// Start position chosen before the source was loaded.
  Duration? _startAt;

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
    final startAt = _startAt;
    await _player.play(
      remote ? UrlSource(source) : DeviceFileSource(source),
      position: startAt != null && startAt > Duration.zero ? startAt : null,
    );
    // A position picked while the note was loading lands now that it plays.
    final pickedWhileLoading = _startAt;
    _startAt = null;
    _source = source;
    if (pickedWhileLoading != null && pickedWhileLoading != startAt) {
      try {
        await _player.seek(pickedWhileLoading);
      } catch (_) {
        // Not blocking: playback goes on from where it started.
      }
    }
  }

  @override
  Future<void> seek(Duration position) async {
    final state = _player.state;
    if (_source != null &&
        (state == PlayerState.playing || state == PlayerState.paused)) {
      await _player.seek(position);
      return;
    }
    _startAt = position;
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
