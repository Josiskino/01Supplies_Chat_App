import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../abstract/api_client_interface.dart';
import '../constants/api_endpoints_urls.dart';
import '../utils/api_types.dart';
import '../utils/app_logger.dart';
import 'push_message.dart';
import 'push_session_store.dart';
import 'push_local_notifications.dart';
import 'push_device_identity.dart';
import 'push_read_receipts.dart';

/// SDK boundary: tests never initialize Firebase or invoke native channels.
abstract interface class PushMessaging {
  Future<bool> requestPermission();
  Future<String?> getToken();
  Future<void> deleteToken();
  Stream<String> get tokenRefresh;
  Stream<PushMessage> get foregroundMessages;
  Stream<PushMessage> get openedMessages;
  Future<PushMessage?> getInitialMessage();
}

class FirebasePushMessaging implements PushMessaging {
  @override
  Future<bool> requestPermission() async =>
      (await FirebaseMessaging.instance.requestPermission())
          .authorizationStatus !=
      AuthorizationStatus.denied;
  @override
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();
  @override
  Future<void> deleteToken() => FirebaseMessaging.instance.deleteToken();
  @override
  Stream<String> get tokenRefresh => FirebaseMessaging.instance.onTokenRefresh;
  @override
  Stream<PushMessage> get foregroundMessages =>
      FirebaseMessaging.onMessage.map(PushMessage.fromRemote);
  @override
  Stream<PushMessage> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp.map(PushMessage.fromRemote);
  @override
  Future<PushMessage?> getInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return message == null ? null : PushMessage.fromRemote(message);
  }
}

/// Mobile push ownership follows account identity, not merely login status.
/// Closing the app keeps a valid registration; explicit logout revokes it.
class PushNotificationService {
  PushNotificationService(
    this._client, {
    PushMessaging? messaging,
    PushSessionStore? sessionStore,
    PushLocalNotifications? localNotifications,
    bool? supported,
    String? platform,
    PushDeviceIdentity? deviceIdentity,
    this.registrationRetryDelay = const Duration(seconds: 30),
  }) : _messaging = messaging ?? FirebasePushMessaging(),
       _store = sessionStore ?? SharedPreferencesPushSessionStore(),
       _local = localNotifications ?? NativePushLocalNotifications(),
       _deviceIdentity = deviceIdentity ?? PushDeviceIdentity(),
       isSupported = supported ?? (Platform.isAndroid || Platform.isIOS),
       _platform = platform ?? (Platform.isIOS ? 'ios' : 'android') {
    _opened = StreamController<PushMessage>.broadcast(
      onListen: () => scheduleMicrotask(_flushOpened),
    );
  }
  final ApiClientInterface _client;
  final PushMessaging _messaging;
  final PushSessionStore _store;
  final PushLocalNotifications _local;
  final PushDeviceIdentity _deviceIdentity;
  final bool isSupported;
  final String _platform;
  final _logger = AppLogger();
  final _foreground = StreamController<PushMessage>.broadcast();
  late final StreamController<PushMessage> _opened;
  final _pendingOpened = <PushMessage>[];
  final _foregroundSeen = <String>{};
  final _openedSeen = <String>{};
  final _clearedMessageIds = <String>{};
  Future<void> _readCleanup = Future.value();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  Future<void> _work = Future.value();
  Future<void> _persistence = Future.value();
  Completer<void> _cancel = Completer<void>();
  String? _account;
  String? _registeredToken;
  String? _observedToken;
  int _generation = 0;
  bool _disposed = false;
  final Duration registrationRetryDelay;
  Timer? _registrationRetry;
  Stream<PushMessage> get foregroundMessages => _foreground.stream;
  Stream<PushMessage> get openedMessages => _opened.stream;
  String? get accountId => _account;
  bool _current(int generation) =>
      !_disposed && _account != null && generation == _generation;

  /// Await with the old bearer still available before clearing login storage.
  Future<void> setSession(String? account) {
    if (_disposed || !isSupported) {
      return Future.value();
    }
    if (account == _account) {
      if (account == null) {
        _persistence = _persistence
            .catchError((Object _) {})
            .then((_) => _store.writeAccount(null));
        return _persistence;
      }
      return _work;
    }
    _registrationRetry?.cancel();
    _registrationRetry = null;
    final previous = _account;
    final oldToken = _observedToken ?? _registeredToken;
    _account = account;
    final generation = ++_generation;
    if (!_cancel.isCompleted) {
      _cancel.complete();
    }
    _cancel = Completer<void>();
    final cancelling = _cancelSubscriptions();
    _registeredToken = null;
    _observedToken = null;
    _foregroundSeen.clear();
    _openedSeen.clear();
    _clearedMessageIds.clear();
    _pendingOpened.clear();
    // Durable background privacy gate must not wait for a slow network revoke.
    _persistence = _persistence
        .catchError((Object _) {})
        .then((_) => _store.writeAccount(account));
    final persisted = _persistence;
    _work = _work
        .catchError((Object _) {})
        .then((_) async {
          await persisted;
          await cancelling;
          if (previous != null) {
            if (oldToken != null) {
              await _revoke(oldToken);
            }
            try {
              await _messaging.deleteToken().timeout(
                const Duration(seconds: 8),
              );
            } catch (_) {
              _logger.warning('FCM token cleanup unavailable', feature: 'Push');
            }
            try {
              await _local.cancelAll();
            } catch (_) {
              _logger.warning(
                'Local notification cleanup unavailable',
                feature: 'Push',
              );
            }
          }
          if (!_current(generation)) {
            return;
          }
          await _start(generation);
        })
        .catchError((Object error, StackTrace stack) {
          _logger.error(
            'Push session setup unavailable',
            feature: 'Push',
            error: error,
            stackTrace: stack,
          );
        });
    return _work;
  }

  Future<void> _cancelSubscriptions() async {
    final subscriptions = _subscriptions.toList();
    _subscriptions.clear();
    await Future.wait(
      subscriptions.map((subscription) => subscription.cancel()),
    );
  }

  Future<T?> _untilCancelled<T>(Future<T> operation, int generation) async {
    final cancelled = _cancel.future;
    final result = await Future.any<T?>([
      operation,
      cancelled.then<T?>((_) => null),
    ]);
    return _current(generation) ? result : null;
  }

  Future<void> _start(int generation) async {
    final allowed = await _untilCancelled(
      _messaging.requestPermission(),
      generation,
    );
    if (allowed != true || !_current(generation)) {
      return;
    }
    _subscriptions.add(
      _messaging.tokenRefresh.listen((token) {
        if (!_current(generation)) {
          return;
        }
        _observedToken = token;
        _work = _work
            .then((_) async {
              if (_current(generation)) {
                await _registerToken(generation);
              }
            })
            .catchError((Object _) {});
      }),
    );
    _subscriptions.add(
      _messaging.foregroundMessages.listen((message) {
        if (_accept(message, generation, _foregroundSeen)) {
          _foreground.add(message.forSession(_account!));
        }
      }),
    );
    void opened(PushMessage message) {
      if (_accept(message, generation, _openedSeen)) {
        _pendingOpened.add(message.forSession(_account!));
        _flushOpened();
      }
    }

    _subscriptions.add(_messaging.openedMessages.listen(opened));
    _subscriptions.add(_local.openedMessages.listen(opened));
    try {
      await _untilCancelled(_local.initialize(), generation);
    } catch (_) {
      _logger.warning('Local notification setup unavailable', feature: 'Push');
    }
    if (!_current(generation)) {
      return;
    }
    // Never await a cold-start SDK future in the registration serialization.
    unawaited(_initialMessages(generation, opened));
    await _registerToken(generation);
  }

  Future<void> _registerToken(int generation) async {
    if (!_current(generation)) return;
    try {
      final token =
          _observedToken ??
          await _untilCancelled<String?>(_messaging.getToken(), generation);
      if (token == null || token.isEmpty) {
        _retryRegistration(generation);
        return;
      }
      if (_current(generation)) {
        _observedToken = token;
        await _sendToken(token, generation);
      }
    } catch (error, stack) {
      _logger.error(
        'Push device registration unavailable',
        feature: 'Push',
        error: error,
        stackTrace: stack,
      );
      _retryRegistration(generation);
    }
  }

  void _retryRegistration(int generation) {
    if (!_current(generation) || _registrationRetry?.isActive == true) return;
    _registrationRetry = Timer(registrationRetryDelay, () {
      _registrationRetry = null;
      _work = _work
          .catchError((Object _) {})
          .then((_) => _registerToken(generation));
    });
  }

  bool _accept(PushMessage message, int generation, Set<String> seen) {
    if (!_current(generation) ||
        (message.recipientId != null && message.recipientId != _account)) {
      return false;
    }
    final id = message.dedupeId;
    if (id != null) {
      final key = '${message.data['type']}:$id';
      if (!seen.add(key)) {
        return false;
      }
      if (seen.length > 256) {
        seen.remove(seen.first);
      }
    }
    return true;
  }

  void _flushOpened() {
    if (_disposed || _account == null || !_opened.hasListener) {
      return;
    }
    final messages = _pendingOpened.toList();
    _pendingOpened.clear();
    for (final message in messages) {
      if (message.recipientId == _account) {
        _opened.add(message);
      }
    }
  }

  Future<void> _initialMessages(
    int generation,
    void Function(PushMessage) opened,
  ) async {
    for (final operation in [
      _messaging.getInitialMessage(),
      _local.getInitialMessage(),
    ]) {
      try {
        final message = await operation;
        if (_current(generation) && message != null) {
          opened(message);
        }
      } catch (_) {
        /* No initial notification is a valid startup state. */
      }
    }
  }

  Future<void> _sendToken(String token, int generation) async {
    if (!_current(generation) || token.isEmpty || token == _registeredToken) {
      return;
    }
    final deviceId = await _deviceIdentity.getDeviceId();
    if (!_current(generation)) return;
    final result = await _client
        .request<bool>(
          path: ApiEndpoints.devices,
          method: HttpMethod.post,
          data: {
            'fcmToken': token,
            'platform': _platform,
            'deviceId': deviceId,
          },
          fromJson: (_) => true,
        )
        .timeout(const Duration(seconds: 10));
    if (_current(generation) && result is ApiSuccess<bool>) {
      _registeredToken = token;
      _logger.info('FCM device registration confirmed', feature: 'Push');
      _registrationRetry?.cancel();
      _registrationRetry = null;
      await _verifyActiveDevice(deviceId, generation);
    } else if (_current(generation)) {
      final status = result is ApiError<bool> ? result.statusCode : null;
      _logger.warning(
        'Push device registration rejected (HTTP $status)',
        feature: 'Push',
      );
      _retryRegistration(generation);
    }
  }

  Future<void> _verifyActiveDevice(String deviceId, int generation) async {
    try {
      final result = await _client
          .request<bool>(
            path: ApiEndpoints.devices,
            method: HttpMethod.get,
            fromJson: (json) {
              final data = json['data'] is Map ? json['data'] as Map : json;
              return (data['devices'] as List? ?? const [])
                  .whereType<Map>()
                  .any(
                    (device) =>
                        device['deviceId'] == deviceId &&
                        device['platform'] == _platform,
                  );
            },
          )
          .timeout(const Duration(seconds: 10));
      if (!_current(generation)) return;
      if (result is ApiSuccess<bool> && result.data) {
        _logger.info(
          'FCM active device verified by GET users/me/devices',
          feature: 'Push',
        );
      } else {
        _logger.warning(
          'FCM registration accepted; active device verification unavailable',
          feature: 'Push',
        );
      }
    } catch (_) {
      _logger.warning(
        'FCM active device verification unavailable',
        feature: 'Push',
      );
    }
  }

  Future<void> _revoke(String token) async {
    try {
      await _client
          .request<bool>(
            path: ApiEndpoints.devices,
            method: HttpMethod.delete,
            data: {'fcmToken': token},
            fromJson: (_) => true,
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      _logger.warning(
        'Push device revoke unavailable; rotating local token',
        feature: 'Push',
      );
    }
  }

  Future<void> markMessagesRead(Iterable<String> messageIds) {
    final owner = _account;
    final generation = _generation;
    if (!isSupported || owner == null || _disposed) return Future.value();
    final ids = messageIds.where((id) => id.isNotEmpty).toSet();
    _readCleanup = _readCleanup
        .catchError((Object _) {})
        .then((_) async {
          if (!_current(generation)) return;
          final pending = ids.difference(_clearedMessageIds);
          if (pending.isEmpty) return;
          await rememberReadPushMessages(owner, pending);
          if (!_current(generation)) return;
          await _local.cancelMessages(pending);
          if (!_current(generation)) return;
          _clearedMessageIds.addAll(pending);
          while (_clearedMessageIds.length > 1000) {
            _clearedMessageIds.remove(_clearedMessageIds.first);
          }
        })
        .catchError((Object _) {
          _logger.warning(
            'Read notification cleanup unavailable',
            feature: 'Push',
          );
        });
    return _readCleanup;
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _registrationRetry?.cancel();
    ++_generation;
    if (!_cancel.isCompleted) {
      _cancel.complete();
    }
    _pendingOpened.clear();
    await _cancelSubscriptions();
    await _local.dispose();
    await _foreground.close();
    await _opened.close();
  }
}
