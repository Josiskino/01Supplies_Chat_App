import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supplies_calls/support.dart';
import 'package:window_manager/window_manager.dart';

import 'agent_calls.dart';

part 'desktop_call_alerts.g.dart';

/// Desktop has no CallKit/Telecom ring: an offer must be audible, visible
/// outside the app and bring the window forward, or agents working in another
/// application never notice it.
abstract interface class DesktopCallAlerts {
  /// A new offer arrived. [title]/[body] are already localized.
  Future<void> ring({
    required String title,
    required String body,
    required bool silent,
  });

  /// Every offer was handled, taken or withdrawn.
  Future<void> stop();
}

bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows);

/// Null outside macOS and Windows.
@Riverpod(keepAlive: true)
DesktopCallAlerts? desktopCallAlerts(Ref ref) {
  if (!_isDesktop) return null;
  final alerts = PluginDesktopCallAlerts();
  ref.onDispose(() => unawaited(alerts.dispose()));
  return alerts;
}

/// Agent preference: ring silently (notification and focus still happen).
@Riverpod(keepAlive: true)
class DesktopRingtoneMuted extends _$DesktopRingtoneMuted {
  static const _key = 'calls.desktop_ringtone_muted';

  @override
  bool build() {
    unawaited(_load());
    return false;
  }

  Future<void> _load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getBool(_key) ?? false;
      if (ref.mounted) state = value;
    } catch (_) {}
  }

  Future<void> toggle() async {
    state = !state;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_key, state);
    } catch (_) {}
  }
}

class PluginDesktopCallAlerts implements DesktopCallAlerts {
  static const _notificationId = 8201;
  final _player = AudioPlayer(playerId: '01chat-incoming-call');
  final _notifications = FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;
  bool _ringing = false;

  Future<void> _initialize() => _initializing ??= () async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _notifications.initialize(
      const InitializationSettings(
        macOS: DarwinInitializationSettings(),
        windows: WindowsInitializationSettings(
          appName: '01 Chat',
          appUserModelId: 'ZeroOneSupplies.Chat',
          guid: '6f7d3c1e-2b8a-4f4e-9d61-0c1a5e7b9a24',
        ),
      ),
      onDidReceiveNotificationResponse: (_) => unawaited(_focus()),
    );
  }();

  Future<void> _focus() async {
    try {
      if (await windowManager.isMinimized()) await windowManager.restore();
      await windowManager.show();
      await windowManager.focus();
    } catch (_) {}
  }

  @override
  Future<void> ring({
    required String title,
    required String body,
    required bool silent,
  }) async {
    try {
      await _initialize();
    } catch (_) {}
    if (!silent && !_ringing) {
      _ringing = true;
      try {
        await _player.play(
          BytesSource(ringtoneWav(), mimeType: 'audio/wav'),
          volume: 0.8,
        );
      } catch (_) {
        _ringing = false;
      }
    } else if (silent && _ringing) {
      await _stopSound();
    }
    try {
      await _notifications.show(
        _notificationId,
        title,
        body,
        const NotificationDetails(
          macOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentSound: false,
          ),
          windows: WindowsNotificationDetails(),
        ),
      );
    } catch (_) {}
    await _focus();
  }

  Future<void> _stopSound() async {
    _ringing = false;
    try {
      await _player.stop();
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    await _stopSound();
    try {
      if (_initializing != null) await _notifications.cancel(_notificationId);
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}

Uint8List? _ringtone;

/// Two short dual-tone bursts then silence (3 s), generated in memory so the
/// ringtone ships without a new asset.
Uint8List ringtoneWav() => _ringtone ??= () {
  const rate = 22050;
  const seconds = 3;
  const samples = rate * seconds;
  final data = ByteData(44 + samples * 2);
  void ascii(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, samples * 2, Endian.little);
  for (var i = 0; i < samples; i++) {
    final t = i / rate;
    final on = t < 0.4 || (t >= 0.6 && t < 1.0);
    var value = 0.0;
    if (on) {
      final phase = t < 0.4 ? t : t - 0.6;
      // Short fades avoid clicks at burst edges.
      final envelope = math.min(1.0, math.min(phase, 0.4 - phase) / 0.02);
      value =
          envelope *
          0.35 *
          (math.sin(2 * math.pi * 440 * t) + math.sin(2 * math.pi * 480 * t));
    }
    data.setInt16(44 + i * 2, (value * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}();

/// Rings on desktop while at least one offer is pending; stops as soon as
/// the list empties (answered here, taken elsewhere, withdrawn or expired).
class DesktopIncomingCallAlerter extends ConsumerStatefulWidget {
  const DesktopIncomingCallAlerter({
    super.key,
    required this.child,
    required this.describe,
  });
  final Widget child;

  /// Localized notification title/body for the newest offer.
  final (String, String) Function(BuildContext context, SupportCall call)
  describe;

  @override
  ConsumerState<DesktopIncomingCallAlerter> createState() =>
      _DesktopIncomingCallAlerterState();
}

class _DesktopIncomingCallAlerterState
    extends ConsumerState<DesktopIncomingCallAlerter> {
  Set<String> _known = const {};

  void _onIncoming(List<SupportCall> incoming) {
    final alerts = ref.read(desktopCallAlertsProvider);
    if (alerts == null) return;
    final ids = {for (final call in incoming) call.id};
    final fresh = incoming.where((call) => !_known.contains(call.id)).toList();
    _known = ids;
    if (ids.isEmpty) {
      unawaited(alerts.stop());
      return;
    }
    if (fresh.isEmpty) return;
    final newest = fresh.reduce(
      (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
    );
    final (title, body) = widget.describe(context, newest);
    unawaited(
      alerts.ring(
        title: title,
        body: body,
        silent: ref.read(desktopRingtoneMutedProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      agentCallsProvider.select((s) => s.incoming),
      (_, next) => _onIncoming(next),
    );
    ref.listen(desktopRingtoneMutedProvider, (_, muted) {
      if (muted && _known.isNotEmpty) {
        unawaited(ref.read(desktopCallAlertsProvider)?.stop());
      }
    });
    return widget.child;
  }
}
