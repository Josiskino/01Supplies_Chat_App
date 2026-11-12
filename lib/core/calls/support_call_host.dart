import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:uuid/uuid.dart';
import 'package:supplies_calls/support.dart';
import 'package:supplies_calls/serverpod.dart';
import 'package:supplies_calls/livekit.dart';
import '../providers/auth/auth_provider.dart';
export 'package:supplies_calls/support.dart';

const _url = String.fromEnvironment('SUPPORT_CALLS_URL');
final _enabled = supportCallsConfigured(
  enabled: const bool.fromEnvironment('SUPPORT_CALLS_ENABLED'),
  flavor: appFlavor,
  url: _url,
);
const _host = 'chat';
const _nativeChannel = MethodChannel('01calls/native');

class HostCallSessionStorage implements SessionStorage {
  static const storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accountName: '01supplies.chat.support',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const key = '01supplies.chat.support_session';
  @override
  Future<StoredSession?> read() async {
    final raw = await storage.read(key: key);
    if (raw == null) return null;
    try {
      final v = jsonDecode(raw) as Map<String, dynamic>;
      return StoredSession(v['identity'] as String, v['token'] as String);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(StoredSession session) => storage.write(
    key: key,
    value: jsonEncode({'identity': session.identity, 'token': session.token}),
  );
  @override
  Future<void> clear() => storage.delete(key: key);
  static Future<String> deviceId() async {
    const key = '01supplies.chat.support_device';
    final id = await storage.read(key: key) ?? const Uuid().v4();
    await storage.write(key: key, value: id);
    return id;
  }
}

ServerpodCallDataSource _backgroundSource(StoredSession session) {
  final source = ServerpodCallDataSource(_url);
  installSupportBackgroundRefresh(
    source: source,
    expectedSession: session,
    storage: HostCallSessionStorage(),
    host: _host,
    deviceId: HostCallSessionStorage.deviceId,
    accessToken: () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      final token = preferences.getString('token') ?? '';
      return token.isEmpty ? null : token;
    },
  );
  return source;
}

Future<void> _updateMissedCalls(
  List<SupportCall> history,
  String identity,
) async {
  final current = await HostCallSessionStorage().read();
  if (current?.identity != identity) return;
  final seen = DateTime.tryParse(
    await HostCallSessionStorage.storage.read(
          key: 'support_missed_seen:$identity',
        ) ??
        '',
  );
  final missed = missedSupportCalls(history, identity, seen);
  if (Platform.isAndroid) {
    await showAndroidSupportMissed(missed);
  } else if (Platform.isIOS) {
    await _nativeChannel.invokeMethod<void>('showSupportMissed', {
      'count': missed.length,
      'callerName': missed.isEmpty
          ? ''
          : supportMissedCallParams(missed).nameCaller,
    });
  }
}

Future<void> _markHistoryViewed() async {
  final session = await HostCallSessionStorage().read();
  if (session == null) return;
  await HostCallSessionStorage.storage.write(
    key: 'support_missed_seen:${session.identity}',
    value: DateTime.now().toUtc().toIso8601String(),
  );
  if (Platform.isAndroid) {
    await showAndroidSupportMissed(const []);
  } else if (Platform.isIOS) {
    await _nativeChannel.invokeMethod<void>('showSupportMissed', {'count': 0});
  }
}

/// Fan out from the host's existing FCM handler; messaging remains registered.
Future<void> supportCallBackgroundPush(Map<String, dynamic> data) async {
  if (!_enabled || _url.isEmpty || !(Platform.isAndroid || Platform.isIOS)) {
    return;
  }
  final type = data['type'];
  if (type != 'support.call.invited' &&
      type != 'support.call.cancelled' &&
      type != 'support.call.missed') {
    return;
  }
  final session = await HostCallSessionStorage().read();
  final recipient = data['recipient'] ?? data['agentId'] ?? data['recipientId'];
  if (session == null || recipient != session.identity) return;
  final id = data['callId'];
  if (id is! String) return;
  final source = _backgroundSource(session);
  try {
    final call = await ServerpodSupportCallRepository(source).get(id);
    if (type == 'support.call.invited' &&
        call.offeredTo(session.identity) &&
        call.expiresAt.isAfter(DateTime.now().toUtc())) {
      if (!(await FlutterCallkitIncoming.activeCalls()).any(
        (v) => v.id == id,
      )) {
        await FlutterCallkitIncoming.showCallkitIncoming(
          supportCallKitParams(call),
        );
      }
    } else {
      await FlutterCallkitIncoming.endCall(id);
      if (type == 'support.call.missed' || type == 'support.call.cancelled') {
        await _updateMissedCalls(
          await ServerpodSupportCallRepository(source).history(),
          session.identity,
        );
      }
    }
  } catch (_) {
    /* Push cannot grant access or change authoritative state. */
  } finally {
    source.client.close();
  }
}

@pragma('vm:entry-point')
Future<void> supportNativeBackgroundAction(CallEvent event) async {
  if (!_enabled || _url.isEmpty) return;
  final action = supportNativeAction(event);
  if (action == null) return;
  final session = await HostCallSessionStorage().read();
  if (session == null) return;
  final source = _backgroundSource(session);
  final repo = ServerpodSupportCallRepository(source);
  try {
    final call = await repo.get(action.callId);
    switch (action.type) {
      case IncomingActionType.accept:
        if (call.offeredTo(session.identity)) await repo.accept(call.id);
      case IncomingActionType.reject:
        if (call.offeredTo(session.identity)) await repo.reject(call.id);
      case IncomingActionType.end:
        if (call.isActive &&
            (call.caller.id == session.identity ||
                call.agentId == session.identity)) {
          await repo.end(call.id);
        }
      case IncomingActionType.mute:
      case IncomingActionType.unmute:
        break;
    }
  } catch (_) {
  } finally {
    source.client.close();
  }
}

final _dependencies = Provider<_HostDependencies>((ref) {
  final source = ServerpodCallDataSource(_url);
  final value = _HostDependencies(
    source,
    onSystemReset: () => ref.read(supportCallControllerProvider.notifier).end(),
  );
  ref.onDispose(() {
    source.client.close();
    unawaited(value.audio.dispose());
    unawaited(value.microphone.dispose());
  });
  return value;
});

class _HostDependencies {
  _HostDependencies(this.source, {required this.onSystemReset}) {
    native = CallkitSupportNative(
      register: register,
      unregister: unregister,
      onMissed: _updateMissedCalls,
      onHistoryViewed: _markHistoryViewed,
    );
    auth = ApplicationCallAuthRepository(
      source: source,
      storage: HostCallSessionStorage(),
      host: _host,
      deviceId: HostCallSessionStorage.deviceId,
      accessToken: () async {
        final preferences = await SharedPreferences.getInstance();
        await preferences.reload();
        final token = preferences.getString('token') ?? '';
        return token.isEmpty ? null : token;
      },
      onRefreshed: () async {
        final session = await HostCallSessionStorage().read();
        if (session != null) {
          await register(session.identity);
          if (_host == 'chat') {
            await source.client.supportCalls.availability(
              await microphone.isGranted(),
            );
          }
        }
      },
    );
  }
  final Future<void> Function() onSystemReset;
  final ServerpodCallDataSource source;
  final audio = LiveKitAudioSession();
  final microphone = RecordMicrophonePermission();
  late final CallkitSupportNative native;
  late final ApplicationCallAuthRepository auth;
  StreamSubscription<String>? tokens;
  StreamSubscription<RemoteMessage>? messages;
  Future<void> register(String identity) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    await HostCallSessionStorage.storage.write(key: 'support_url', value: _url);
    // Background handler registration is implemented by the Android plugin.
    // iOS receives native actions through AppDelegate / CallKit delegates.
    if (Platform.isAndroid) {
      await FlutterCallkitIncoming.onBackgroundMessage(
        supportNativeBackgroundAction,
      );
    }
    final device = await HostCallSessionStorage.deviceId();
    if (Platform.isAndroid) {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await source.client.calls.registerDevice(device, token, 'fcm', false);
      }
      tokens ??= FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        unawaited(
          source.client.calls
              .registerDevice(device, token, 'fcm', false)
              .catchError((Object _) {}),
        );
      });
      messages ??= FirebaseMessaging.onMessage.listen((message) {
        unawaited(supportCallBackgroundPush(message.data));
      });
    } else {
      _nativeChannel.setMethodCallHandler((call) async {
        if (call.method == 'supportProviderReset') {
          await onSystemReset();
          return;
        }
        if (call.method == 'voipTokenChanged' ||
            call.method == 'alertTokenChanged') {
          await register(identity);
        }
      });
      await _nativeChannel.invokeMethod<void>('enableVoip');
      await _nativeChannel.invokeMethod<void>('enableAlerts');
      final alert = await _nativeChannel.invokeMethod<String>('getAlertToken');
      if (alert != null && alert.isNotEmpty) {
        await source.client.calls.registerDevice(
          '$device:alerts',
          alert,
          'apns-alert',
          await _nativeChannel.invokeMethod<bool>('isSandbox') ?? true,
        );
      }
      final token = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
      if (token is String && token.isNotEmpty) {
        await source.client.calls.registerDevice(
          device,
          token,
          'apns',
          await _nativeChannel.invokeMethod<bool>('isSandbox') ?? true,
        );
      }
    }
  }

  Future<void> unregister() async {
    if (Platform.isIOS) {
      await _nativeChannel.invokeMethod<void>('showSupportMissed', {
        'count': 0,
      });
    }
    await tokens?.cancel();
    tokens = null;
    await messages?.cancel();
    messages = null;
    try {
      final device = await HostCallSessionStorage.deviceId();
      await source.client.calls.unregisterDevice(device);
      if (Platform.isIOS) {
        await source.client.calls.unregisterDevice('$device:alerts');
      }
    } catch (_) {}
    if (Platform.isIOS) await _nativeChannel.invokeMethod<void>('disableVoip');
  }
}

final supportCallHostOverrides = [
  supportCallsEnabledProvider.overrideWithValue(_enabled && _url.isNotEmpty),
  supportMicrophonePermissionProvider.overrideWith(
    (ref) => ref.watch(_dependencies).microphone,
  ),
  supportCallIsAgentProvider.overrideWithValue(true),
  supportCallRepositoryProvider.overrideWith(
    (ref) => ServerpodSupportCallRepository(ref.watch(_dependencies).source),
  ),
  supportCallAuthProvider.overrideWith((ref) => ref.watch(_dependencies).auth),
  supportCallAudioProvider.overrideWith(
    (ref) => ref.watch(_dependencies).audio,
  ),
  supportCallNativeProvider.overrideWith(
    (ref) => ref.watch(_dependencies).native,
  ),
];

/// Runs before runApp so accepting on the lock screen needs no Flutter view.
void restoreSupportCallsHeadless(ProviderContainer container) {
  if (_enabled && _url.isNotEmpty) {
    unawaited(container.read(supportCallControllerProvider.notifier).restore());
  }
}

class SupportCallHost extends ConsumerWidget {
  const SupportCallHost({required this.child, required this.router, super.key});
  final GoRouter router;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_enabled || _url.isEmpty) return child;
    final userId = ref.watch(currentUserProvider)?.id;
    return _SupportCallLifecycle(
      userId: userId?.toString(),
      router: router,
      child: child,
    );
  }
}

class _SupportCallLifecycle extends ConsumerStatefulWidget {
  const _SupportCallLifecycle({
    required this.userId,
    required this.router,
    required this.child,
  });
  final GoRouter router;
  final String? userId;
  final Widget child;
  @override
  ConsumerState<_SupportCallLifecycle> createState() =>
      _SupportCallLifecycleState();
}

class _SupportCallLifecycleState extends ConsumerState<_SupportCallLifecycle>
    with WidgetsBindingObserver {
  String? _microphonePromptedForUser;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_sync);
  }

  @override
  void didUpdateWidget(covariant _SupportCallLifecycle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      Future.microtask(() async {
        if (oldWidget.userId != null) {
          await HostCallSessionStorage().clear();
          await ref.read(supportCallControllerProvider.notifier).logout();
        }
        await _sync();
      });
    }
  }

  Future<void> _sync() async {
    if (mounted && widget.userId != null) {
      final controller = ref.read(supportCallControllerProvider.notifier);
      await controller.ensureReady();
      if (mounted &&
          _host == 'chat' &&
          _microphonePromptedForUser != widget.userId &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          ref.read(supportCallControllerProvider).active?.isActive != true) {
        _microphonePromptedForUser = widget.userId;
        await controller.prepareMicrophone();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_host == 'chat') unawaited(_sync());
      unawaited(ref.read(supportCallControllerProvider.notifier).reconcile());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = ref.watch(supportCallControllerProvider).active;
    final router = widget.router;
    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final visible =
            call != null &&
            call.isActive &&
            router.routerDelegate.currentConfiguration.last.matchedLocation !=
                '/call';
        return Stack(
          children: [
            widget.child,
            if (visible)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Material(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(Icons.call),
                      title: Text(
                        call.caller.id ==
                                ref.read(supportCallControllerProvider).identity
                            ? call.agentName ?? 'Assistance 01Supplies'
                            : call.caller.name,
                      ),
                      subtitle: Text(call.context.reference),
                      onTap: () => router.push('/call'),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_full),
                        onPressed: () => router.push('/call'),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
