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
import '../../presentation/pages/calls/widgets/agent_call_widgets.dart';
import '../constants/app_ui_route.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/auth/auth_provider.dart';
import '../utils/app_logger.dart';
import 'agent_calls.dart';
import 'calls_sign_out.dart';
import 'desktop_call_alerts.dart';
export 'package:supplies_calls/support.dart';

// Production and development default to their own calls service, so a
// Shorebird patch built without dart-defines cannot silently disable calls.
final _config = resolveSupportCallsBuildConfig(
  flavor: appFlavor,
  enabledDefine: const String.fromEnvironment('SUPPORT_CALLS_ENABLED'),
  urlDefine: const String.fromEnvironment('SUPPORT_CALLS_URL'),
);
final _url = _config.url;
final _enabled = _config.enabled;
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
///
/// The package helper rings from the payload first and validates afterwards,
/// so a slow network never delays the incoming UI; stale offers are dismissed.
Future<void> supportCallBackgroundPush(Map<String, dynamic> data) async {
  if (!_enabled || _url.isEmpty || !Platform.isAndroid) return;
  if (!supportCallPushTypes.contains(data['type'])) return;
  final session = await HostCallSessionStorage().read();
  if (session == null) return;
  final source = _backgroundSource(session);
  try {
    await handleSupportCallPush(
      data: data,
      identity: session.identity,
      repository: ServerpodSupportCallRepository(source),
      onMissed: _updateMissedCalls,
      diagnostics: _logDiagnostic,
    );
  } catch (_) {
    /* Push cannot grant access or change authoritative state. */
  } finally {
    source.client.close();
  }
}

void _logDiagnostic(String event, {String? callId, String? detail}) {
  AppLogger().warning(
    'Support call diagnostic: $event',
    feature: 'Calls',
    data: {'callId': ?callId, 'detail': ?detail},
  );
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
      // Availability is the agent's own choice, persisted server-side; a
      // token refresh only re-registers the push device.
      onRefreshed: () async {
        final session = await HostCallSessionStorage().read();
        if (session != null) await register(session.identity);
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
  supportCallDiagnosticsProvider.overrideWithValue(_logDiagnostic),
  if (_enabled && _url.isNotEmpty) ...[
    callsSignOutProvider.overrideWith(_HostCallsSignOut.new),
    missedCallsSeenStoreProvider.overrideWithValue(
      _SecureMissedCallsSeenStore(),
    ),
  ],
];

class _HostCallsSignOut implements CallsSignOut {
  _HostCallsSignOut(this._ref);
  final Ref _ref;

  /// Ends the call, unregisters the device, reports the agent offline and
  /// closes the calls session, then forgets the stored calls session.
  @override
  Future<void> run() async {
    try {
      await _ref.read(supportCallControllerProvider.notifier).logout();
    } finally {
      await HostCallSessionStorage().clear();
    }
  }
}

class _SecureMissedCallsSeenStore implements MissedCallsSeenStore {
  @override
  Future<DateTime?> read(String identity) async => DateTime.tryParse(
    await HostCallSessionStorage.storage.read(
          key: 'support_missed_seen:$identity',
        ) ??
        '',
  );
}

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
  late final _offersEntry = OverlayEntry(
    builder: (context) => SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: IncomingCallsPanel(elevated: true, router: widget.router),
          ),
        ),
      ),
    ),
  );
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
          // Explicit sign-out already ran this before clearing the main
          // session; this covers expired sessions and account switches.
          // Logout needs the stored calls session, so clear it afterwards.
          await ref.read(supportCallControllerProvider.notifier).logout();
          await HostCallSessionStorage().clear();
        }
        await _sync();
      });
    }
  }

  /// The microphone is requested on the first availability switch or the
  /// first call, with an explanation, never right after login.
  Future<void> _sync() async {
    if (mounted && widget.userId != null) {
      await ref.read(supportCallControllerProvider.notifier).ensureReady();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.userId != null) {
      final controller = ref.read(supportCallControllerProvider.notifier);
      unawaited(controller.ensureReady().then((_) => controller.reconcile()));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calls = ref.watch(agentCallsProvider);
    final call = calls.active;
    final router = widget.router;
    return DesktopIncomingCallAlerter(
      describe: (context, offer) {
        final l10n = lookupAppLocalizations(Localizations.localeOf(context));
        return (
          l10n.callNotificationTitle(offer.caller.name),
          offer.context.reference,
        );
      },
      child: ListenableBuilder(
        listenable: router.routerDelegate,
        builder: (context, _) {
          final onCallScreen =
              router.routerDelegate.currentConfiguration.isNotEmpty &&
              router.routerDelegate.currentConfiguration.last.matchedLocation ==
                  AppUiRoute.call;
          final showOffers = calls.incoming.isNotEmpty && !onCallScreen;
          final showBanner =
              call != null && call.isActive && !onCallScreen && !showOffers;
          return Stack(
            children: [
              widget.child,
              if (showOffers)
                // Own Overlay: this layer sits above the router's Navigator,
                // where tooltips would otherwise find none.
                Positioned.fill(child: Overlay(initialEntries: [_offersEntry])),
              if (showBanner)
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
                        title: Text(call.caller.name),
                        subtitle: Text(call.context.reference),
                        onTap: () => router.push(AppUiRoute.call),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (calls.inCall) const CallsWaitingIndicator(),
                            // No tooltip: this layer has no Overlay.
                            Semantics(
                              label: lookupAppLocalizations(
                                Localizations.localeOf(context),
                              ).callOpen,
                              button: true,
                              child: IconButton(
                                icon: const Icon(Icons.open_in_full),
                                onPressed: () => router.push(AppUiRoute.call),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
