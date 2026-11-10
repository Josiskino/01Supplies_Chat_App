import 'dart:async';
import 'dart:convert';
import '../utils/app_logger.dart';
import 'pusher_transport.dart';

typedef PusherEventHandler = void Function(Map<String, dynamic> data);
typedef PusherAuthorizer =
    Future<Map<String, dynamic>?> Function(String channelName, String socketId);

enum RealtimeConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Shared Pusher protocol connection with desired subscriptions retained across
/// network loss. Each callback and authorization is fenced by connection epoch.
class PusherService {
  PusherService({
    PusherTransport Function()? transportFactory,
    this.retryDelay = const Duration(seconds: 2),
  }) : _transportFactory = transportFactory ?? WebSocketPusherTransport.new;
  final PusherTransport Function() _transportFactory;
  final Duration retryDelay;
  final _logger = AppLogger();
  final _states = StreamController<RealtimeConnectionState>.broadcast(
    sync: true,
  );
  Stream<RealtimeConnectionState> get connectionStates => _states.stream;
  RealtimeConnectionState _state = RealtimeConnectionState.disconnected;
  RealtimeConnectionState get connectionState => _state;
  bool get isConnected => _state == RealtimeConnectionState.connected;
  final Map<String, Map<String, Set<PusherEventHandler>>> _handlers = {};
  final Set<String> _subscribed = {};
  final Set<String> _subscribing = {};
  PusherTransport? _transport;
  StreamSubscription<Object>? _subscription;
  Timer? _retry;
  Timer? _heartbeat;
  Timer? _handshakeTimeout;
  Timer? _pongTimeout;
  Future<void>? _opening;
  int _epoch = 0;
  bool _wanted = false;
  String? _socketId;
  String _apiKey = '';
  String _cluster = '';
  PusherAuthorizer? _authorizer;

  void _setState(RealtimeConnectionState state) {
    if (_state == state) {
      return;
    }
    _state = state;
    if (!_states.isClosed) {
      _states.add(state);
    }
  }

  Future<void> connect({
    required String apiKey,
    required String cluster,
    required PusherAuthorizer authorizer,
  }) async {
    if (apiKey.isEmpty) {
      return;
    }
    _apiKey = apiKey;
    _cluster = cluster;
    _authorizer = authorizer;
    _wanted = true;
    if (isConnected) {
      return;
    }
    final existing = _opening;
    if (existing != null) {
      return existing;
    }
    final opening = _open();
    _opening = opening;
    try {
      await opening;
    } finally {
      if (identical(_opening, opening)) {
        _opening = null;
      }
    }
  }

  Future<void> _open() async {
    final epoch = ++_epoch;
    _retry?.cancel();
    _setState(RealtimeConnectionState.connecting);
    final transport = _transportFactory();
    _transport = transport;
    try {
      await transport.connect(
        Uri.https('ws-$_cluster.pusher.com', '/app/$_apiKey', {
          'protocol': '7',
          'client': '01chat-dart',
          'version': '1.0',
          'flash': 'false',
        }).replace(scheme: 'wss'),
      );
      if (!_wanted || epoch != _epoch) {
        await transport.close();
        return;
      }
      _handshakeTimeout?.cancel();
      _handshakeTimeout = Timer(
        const Duration(seconds: 25),
        () => _lost(epoch),
      );
      _subscription = transport.frames.listen(
        (frame) {
          if (epoch == _epoch) {
            _onFrame(frame, epoch);
          }
        },
        onError: (Object error) {
          if (epoch == _epoch) {
            _lost(epoch);
          }
        },
        onDone: () {
          if (epoch == _epoch) {
            _lost(epoch);
          }
        },
      );
    } catch (error) {
      _logger.warning('Connection unavailable', feature: 'Pusher');
      if (epoch == _epoch) {
        _lost(epoch);
      }
    }
  }

  void _lost(int epoch) {
    if (epoch != _epoch) {
      return;
    }
    ++_epoch;
    _socketId = null;
    _subscribed.clear();
    _subscribing.clear();
    _heartbeat?.cancel();
    _handshakeTimeout?.cancel();
    _pongTimeout?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(_transport?.close());
    _transport = null;
    if (!_wanted) {
      _setState(RealtimeConnectionState.disconnected);
      return;
    }
    _setState(RealtimeConnectionState.reconnecting);
    _retry?.cancel();
    _retry = Timer(retryDelay, () {
      if (_wanted) {
        unawaited(_open());
      }
    });
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is String) {
      try {
        value = jsonDecode(value);
      } catch (_) {
        return {};
      }
    }
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  void _onFrame(Object frame, int epoch) {
    final envelope = _map(frame);
    final event = envelope['event']?.toString();
    final data = _map(envelope['data']);
    final channel = envelope['channel']?.toString();
    if (event == 'pusher:connection_established') {
      _handshakeTimeout?.cancel();
      _socketId = data['socket_id']?.toString();
      if (_socketId == null) {
        return;
      }
      _setState(RealtimeConnectionState.connected);
      _heartbeat?.cancel();
      final timeout = (data['activity_timeout'] as num?)?.toInt() ?? 120;
      _heartbeat = Timer.periodic(Duration(seconds: timeout.clamp(10, 120)), (
        _,
      ) {
        _send({'event': 'pusher:ping', 'data': {}});
        _pongTimeout?.cancel();
        _pongTimeout = Timer(const Duration(seconds: 30), () => _lost(epoch));
      });
      for (final name in _handlers.keys.toList()) {
        unawaited(_subscribe(name, epoch));
      }
      return;
    }
    if (event == 'pusher:ping') {
      _send({'event': 'pusher:pong', 'data': {}});
      return;
    }
    if (event == 'pusher:pong') {
      _pongTimeout?.cancel();
      return;
    }
    if (event == 'pusher:error') {
      _lost(epoch);
      return;
    }
    if (channel == null || event == null) {
      return;
    }
    if (event == 'pusher_internal:subscription_succeeded') {
      _subscribing.remove(channel);
      _subscribed.add(channel);
    }
    final callbacks = _handlers[channel]?[event]?.toList() ?? [];
    for (final handler in callbacks) {
      try {
        handler(data);
      } catch (error, stack) {
        _logger.error(
          'Event handler failed',
          feature: 'Pusher',
          error: error,
          stackTrace: stack,
        );
      }
    }
  }

  Future<void> _subscribe(String channel, int epoch) async {
    final socket = _socketId;
    if (socket == null ||
        !_handlers.containsKey(channel) ||
        _subscribed.contains(channel) ||
        !_subscribing.add(channel)) {
      return;
    }
    try {
      Map<String, dynamic> auth = {};
      if (channel.startsWith('private-') || channel.startsWith('presence-')) {
        final signed = await _authorizer?.call(channel, socket);
        if (signed == null || signed['auth'] == null) {
          throw StateError('Authorization unavailable');
        }
        auth = signed;
      }
      if (epoch != _epoch || !_wanted || !_handlers.containsKey(channel)) {
        return;
      }
      _send({
        'event': 'pusher:subscribe',
        'data': {'channel': channel, ...auth},
      });
    } catch (_) {
      if (epoch == _epoch) {
        _subscribing.remove(channel);
        // A failed authorization is retried only on explicit rebinding or a
        // reconnect, avoiding infinite retries for revoked support access.
      }
    }
  }

  Future<void> bindEvent({
    required String channelName,
    required String eventName,
    required PusherEventHandler handler,
  }) async {
    _handlers
        .putIfAbsent(channelName, () => {})
        .putIfAbsent(eventName, () => {})
        .add(handler);
    if (isConnected) {
      await _subscribe(channelName, _epoch);
    }
  }

  Future<void> unbindEvent({
    required String channelName,
    required String eventName,
    PusherEventHandler? handler,
  }) async {
    final events = _handlers[channelName];
    if (events == null) {
      return;
    }
    if (handler == null) {
      events.remove(eventName);
    } else {
      events[eventName]?.remove(handler);
      if (events[eventName]?.isEmpty ?? false) {
        events.remove(eventName);
      }
    }
    if (events.isEmpty) {
      _handlers.remove(channelName);
      _subscribed.remove(channelName);
      _subscribing.remove(channelName);
      if (isConnected) {
        _send({
          'event': 'pusher:unsubscribe',
          'data': {'channel': channelName},
        });
      }
    }
  }

  Future<bool> trigger({
    required String channelName,
    required String eventName,
    required Map<String, dynamic> data,
  }) async {
    if (!isConnected ||
        !_subscribed.contains(channelName) ||
        !eventName.startsWith('client-') ||
        !(channelName.startsWith('private-') ||
            channelName.startsWith('presence-'))) {
      return false;
    }
    _send({'event': eventName, 'channel': channelName, 'data': data});
    return true;
  }

  void _send(Map<String, dynamic> frame) => _transport?.send(jsonEncode(frame));
  Future<void> disconnect() async {
    _wanted = false;
    ++_epoch;
    _retry?.cancel();
    _heartbeat?.cancel();
    _handshakeTimeout?.cancel();
    _pongTimeout?.cancel();
    _socketId = null;
    _handlers.clear();
    _subscribed.clear();
    _subscribing.clear();
    final subscription = _subscription;
    _subscription = null;
    final transport = _transport;
    _transport = null;
    _opening = null;
    _setState(RealtimeConnectionState.disconnected);
    await subscription?.cancel();
    await transport?.close();
  }

  Future<void> dispose() async {
    await disconnect();
    await _states.close();
  }
}
