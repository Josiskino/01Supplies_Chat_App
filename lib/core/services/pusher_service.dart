import 'dart:convert';

import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../utils/app_logger.dart';

/// Repris tel quel de l'app cliente, dont les événements de messagerie
/// transitent déjà par Pusher : s'en écarter obligerait le backend à publier
/// deux fois.
///
/// ⚠️ `pusher_channels_flutter` ne supporte ni macOS ni Windows. Sur ces
/// plateformes le service reste silencieux et le fil ne se met à jour qu'au
/// rechargement — cf. « À trancher » dans le CLAUDE.md.
typedef PusherEventHandler = void Function(Map<String, dynamic> data);

/// Authorizer : appelé par Pusher pour les channels privés. Doit retourner
/// `{auth: '...', channel_data: '...'}` (le backend signe la requête).
typedef PusherAuthorizer =
    Future<Map<String, dynamic>?> Function(String channelName, String socketId);

/// Service Pusher singleton — wrappe `pusher_channels_flutter` avec une
/// API simplifiée : `connect`, `bindEvent`, `unbindEvent`, `disconnect`.
///
/// Les écrans/viewmodels appellent `bindEvent(channel, event, handler)` et
/// le service gère automatiquement le subscribe/unsubscribe selon qu'il
/// reste ou non des handlers sur le channel.
class PusherService {
  PusherChannelsFlutter? _instance;
  bool _isConnected = false;
  final AppLogger _logger = AppLogger();

  // channelName → eventName → list of handlers
  final Map<String, Map<String, List<PusherEventHandler>>> _handlers = {};

  // bindEvent calls received before connect() completes — replayed in connect().
  final List<_PendingBind> _pendingBinds = [];

  bool get isConnected => _isConnected;

  Future<void> connect({
    required String apiKey,
    required String cluster,
    required PusherAuthorizer authorizer,
  }) async {
    if (_isConnected) return;
    if (apiKey.isEmpty) {
      _logger.warning('skipped — empty apiKey', feature: 'Pusher');
      return;
    }

    _instance = PusherChannelsFlutter.getInstance();
    try {
      await _instance!.init(
        apiKey: apiKey,
        cluster: cluster,
        onConnectionStateChange: (current, previous) {
          _logger.info('state $previous → $current', feature: 'Pusher');
        },
        onError: (message, code, error) {
          _logger.error(
            'error: $message (code=$code)',
            feature: 'Pusher',
            error: error,
          );
        },
        onSubscriptionSucceeded: (channelName, data) {
          _logger.info('subscribed OK: $channelName', feature: 'Pusher');
        },
        onSubscriptionError: (message, error) {
          _logger.error(
            'subscription error: $message',
            feature: 'Pusher',
            error: error,
          );
        },
        onEvent: _routeEvent,
        onAuthorizer: (channelName, socketId, options) async {
          _logger.debug(
            'authorizer called',
            feature: 'Pusher',
            data: {'channel': channelName, 'socketId': socketId},
          );
          try {
            final result = await authorizer(channelName, socketId);
            _logger.debug(
              'authorizer returned ${result != null ? "OK" : "NULL"}',
              feature: 'Pusher',
              data: {'channel': channelName},
            );
            return result;
          } catch (e, s) {
            _logger.error(
              'authorize $channelName failed',
              feature: 'Pusher',
              error: e,
              stackTrace: s,
            );
            return null;
          }
        },
      );
      await _instance!.connect();
      _isConnected = true;
      await _drainPendingBinds();
    } catch (e, s) {
      _logger.error(
        'connect failed',
        feature: 'Pusher',
        error: e,
        stackTrace: s,
      );
      _isConnected = false;
    }
  }

  void _routeEvent(PusherEvent event) {
    final channelMap = _handlers[event.channelName];
    if (channelMap == null) return;
    final handlers = channelMap[event.eventName];
    if (handlers == null || handlers.isEmpty) return;

    Map<String, dynamic> data = const {};
    final raw = event.data;
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {}
    } else if (raw is Map<String, dynamic>) {
      data = raw;
    }

    for (final handler in List<PusherEventHandler>.from(handlers)) {
      try {
        handler(data);
      } catch (e, s) {
        _logger.error(
          'handler crashed on ${event.eventName}',
          feature: 'Pusher',
          error: e,
          stackTrace: s,
        );
      }
    }
  }

  Future<void> bindEvent({
    required String channelName,
    required String eventName,
    required PusherEventHandler handler,
  }) async {
    if (_instance == null) {
      _logger.debug(
        'bindEvent queued (pre-init)',
        feature: 'Pusher',
        data: {'channel': channelName, 'event': eventName},
      );
      _pendingBinds.add(_PendingBind(channelName, eventName, handler));
      return;
    }

    final shouldSubscribe = !_handlers.containsKey(channelName);
    _handlers.putIfAbsent(channelName, () => {});
    _handlers[channelName]!.putIfAbsent(eventName, () => []);
    _handlers[channelName]![eventName]!.add(handler);

    if (shouldSubscribe) {
      try {
        await _instance!.subscribe(channelName: channelName);
      } catch (e, s) {
        // Le SDK natif refuse un double abonnement au même canal. C'est bénin :
        // le canal est déjà souscrit et notre handler vient d'être enregistré
        // dans `_handlers` → les events continuent d'être dispatchés. On ne
        // remonte donc pas une erreur bruyante dans ce cas précis.
        if (e.toString().contains('Already subscribed')) {
          _logger.debug(
            'subscribe $channelName: déjà abonné (ignoré, bénin)',
            feature: 'Pusher',
          );
        } else {
          _logger.error(
            'subscribe $channelName failed',
            feature: 'Pusher',
            error: e,
            stackTrace: s,
          );
        }
      }
    }
  }

  Future<void> unbindEvent({
    required String channelName,
    required String eventName,
    PusherEventHandler? handler,
  }) async {
    final channelMap = _handlers[channelName];
    if (channelMap == null) return;

    final eventHandlers = channelMap[eventName];
    if (eventHandlers != null) {
      if (handler == null) {
        channelMap.remove(eventName);
      } else {
        eventHandlers.remove(handler);
        if (eventHandlers.isEmpty) channelMap.remove(eventName);
      }
    }

    if (channelMap.isEmpty) {
      _handlers.remove(channelName);
      try {
        await _instance?.unsubscribe(channelName: channelName);
      } catch (_) {}
    }
  }

  Future<void> disconnect() async {
    _handlers.clear();
    _pendingBinds.clear();
    try {
      await _instance?.disconnect();
    } catch (_) {}
    _isConnected = false;
  }

  Future<void> _drainPendingBinds() async {
    if (_pendingBinds.isEmpty) return;
    _logger.info(
      'replaying ${_pendingBinds.length} queued binding(s)',
      feature: 'Pusher',
    );
    final queued = List<_PendingBind>.from(_pendingBinds);
    _pendingBinds.clear();
    for (final p in queued) {
      await bindEvent(
        channelName: p.channelName,
        eventName: p.eventName,
        handler: p.handler,
      );
    }
  }
}

class _PendingBind {
  _PendingBind(this.channelName, this.eventName, this.handler);
  final String channelName;
  final String eventName;
  final PusherEventHandler handler;
}
