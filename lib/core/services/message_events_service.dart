import 'dart:async';
import '../../data/models/messaging/message_model.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../abstract/api_client_interface.dart';
import '../constants/api_constant.dart';
import '../constants/api_endpoints_urls.dart';
import '../utils/api_types.dart';
import '../providers/request/api_provider.dart';
import '../providers/auth/auth_provider.dart';
import '../../domain/entity/messaging/conversation_list_entry.dart';
import '../providers/messaging/support_provider.dart';
import '../providers/realtime/realtime_provider.dart';
import '../providers/auth/auth_status_provider.dart';
import '../auth/auth_gate.dart';
import 'pusher_service.dart';

class ConversationRealtimeEvent {
  ConversationRealtimeEvent(
    this.conversationId,
    this.eventName,
    Map<String, dynamic> payload,
  ) : data = normalize(payload);
  final String conversationId;
  final String eventName;
  final Map<String, dynamic> data;
  static Map<String, dynamic> normalize(Map<String, dynamic> payload) {
    var data = payload;
    for (var i = 0; i < 3; i++) {
      final inner = data['data'] is Map ? data['data'] : data['message'];
      if (inner is! Map) {
        break;
      }
      data = Map<String, dynamic>.from(inner);
    }
    return data;
  }
}

class ConversationTyping {
  const ConversationTyping(this.conversationId, this.users);
  final String conversationId;
  final Map<String, String> users;
}

class ConversationPresence {
  const ConversationPresence(this.conversationId, this.members);
  final String conversationId;

  /// Presence means this conversation is open, never global user availability.
  final Map<String, Map<String, dynamic>> members;
}

/// Account-scoped subscriptions. Background and visible-thread ownership are
/// independent, so rebuilding a thread never drops the background channel.
class MessageEventsService with WidgetsBindingObserver {
  MessageEventsService(
    this._ref, {
    PusherService? pusher,
    this.queueRefreshInterval = const Duration(seconds: 30),
  }) : _pusher = pusher ?? PusherService() {
    WidgetsBinding.instance.addObserver(this);
    _connectionSubscription = _pusher.connectionStates.listen(
      _connectionChanged,
    );
    _ref.listen(
      authStatusProvider,
      (_, _) => _sessionChanged(),
      fireImmediately: true,
    );
    _ref.listen(currentUserProvider, (_, _) => _sessionChanged());
  }
  final Ref _ref;
  final PusherService _pusher;
  final Duration queueRefreshInterval;
  Timer? _queueRefreshTimer;
  bool _disposed = false;
  int _generation = 0;
  String? _account;
  Future<void> _sessionWork = Future.value();
  ProviderSubscription<AsyncValue<List<ConversationListEntry>>>?
  _queueSubscription;
  StreamSubscription<RealtimeConnectionState>? _connectionSubscription;
  final Set<String> _background = {};
  final Set<String> _denied = {};
  final Map<String, int> _foreground = {};
  final Map<String, Map<String, PusherEventHandler>> _bindings = {};
  final Map<String, Map<String, PusherEventHandler>> _presenceBindings = {};
  final Map<String, Map<String, Map<String, dynamic>>> _members = {};
  final Map<String, Timer> _typingIdle = {};
  final Map<String, DateTime> _typingSent = {};
  final Map<String, Set<String>> _pendingDelivered = {};
  final Map<String, int> _deliveryRetries = {};
  Timer? _deliveryTimer;
  bool _delivering = false;
  final _threadEvents = StreamController<String>.broadcast();
  final _events = StreamController<ConversationRealtimeEvent>.broadcast();
  final _presence = StreamController<ConversationPresence>.broadcast();
  final _incoming = StreamController<IncomingMessage>.broadcast();
  final _incomingSeen = <String>{};
  final _catchUp = StreamController<String>.broadcast();
  final _typingChanges = StreamController<ConversationTyping>.broadcast();
  final Map<String, Map<String, String>> _typers = {};
  final Map<String, Map<String, Timer>> _typerTimers = {};
  Stream<ConversationTyping> get typingChanges => _typingChanges.stream;
  Map<String, String> typingSnapshot(String id) =>
      Map.unmodifiable(_typers[id] ?? {});
  Map<String, Map<String, dynamic>> presenceSnapshot(String id) =>
      Map.unmodifiable(_members[id] ?? {});
  Stream<String> get threadChanges => _threadEvents.stream;
  Stream<ConversationRealtimeEvent> get conversationEvents => _events.stream;
  Stream<ConversationPresence> get presenceChanges => _presence.stream;
  Stream<IncomingMessage> get incomingMessages => _incoming.stream;
  Stream<String> get catchUpConversations => _catchUp.stream;
  Stream<RealtimeConnectionState> get connectionStates =>
      _pusher.connectionStates;
  bool get isForeground =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  static const _convEvents = [
    'message.new',
    'message.updated',
    'message.deleted',
    'message.delivered',
    'message.read',
    'message.reaction',
    'conversation.updated',
    'client-typing',
  ];

  static bool canWatch(ConversationListEntry entry, String me) =>
      entry.ticketId == null || entry.assigneeId == me;

  void _sessionChanged() {
    if (_disposed) {
      return;
    }
    final next = _ref.read(authStatusProvider) == AuthGateStatus.authenticated
        ? _ref.read(currentUserProvider)?.id
        : null;
    if (next == _account) {
      return;
    }
    _account = next;
    final generation = ++_generation;
    _queueSubscription?.close();
    _queueSubscription = null;
    _clearLocal();
    // Fence native callbacks immediately, then serialize the next connection.
    final disconnect = _pusher.disconnect();
    _sessionWork = _sessionWork
        .then((_) async {
          await disconnect;
          if (!_current(generation) || next == null) {
            return;
          }
          final client = _ref.read(apiClientProvider);
          await _pusher.connect(
            apiKey: ApiConstant.pusherAppKey,
            cluster: ApiConstant.pusherCluster,
            authorizer: (channel, socket) async {
              if (!_current(generation)) {
                return null;
              }
              final result = await client.request<Map<String, dynamic>>(
                path: ApiConstant.pusherAuthPath.replaceFirst(
                  RegExp(r'^/'),
                  '',
                ),
                method: HttpMethod.post,
                data: {'socket_id': socket, 'channel_name': channel},
                fromJson: (json) => json.containsKey('auth')
                    ? json
                    : Map<String, dynamic>.from(json['data'] as Map? ?? json),
              );
              if (!_current(generation)) {
                return null;
              }
              return switch (result) {
                ApiSuccess(data: final data) => data,
                _ => null,
              };
            },
          );
          if (!_current(generation)) {
            return;
          }
          for (final event in [
            'conversation.created',
            'support.ticket.updated',
            'notification',
          ]) {
            await _pusher.bindEvent(
              channelName: 'private-user-$next',
              eventName: event,
              handler: (payload) {
                if (_current(generation)) {
                  if (event == 'notification') handleNotification(payload);
                  _ref.invalidate(supportQueueProvider);
                }
              },
            );
          }
          if (!_current(generation)) {
            return;
          }
          _queueSubscription = _ref
              .listen<AsyncValue<List<ConversationListEntry>>>(
                supportQueueProvider,
                (_, value) {
                  final entries = value.value;
                  if (_current(generation) && entries != null) {
                    unawaited(_syncQueue(entries, generation));
                  }
                },
                fireImmediately: true,
              );
          if (queueRefreshInterval > Duration.zero) {
            _queueRefreshTimer = Timer.periodic(queueRefreshInterval, (_) {
              if (_current(generation) &&
                  isForeground &&
                  !_ref.read(supportQueueProvider).isLoading) {
                _ref.invalidate(supportQueueProvider);
              }
            });
          }
        })
        .catchError((Object _) {
          /* A later session can still start after failure. */
        });
  }

  bool _current(int generation) =>
      !_disposed && _ref.mounted && generation == _generation;
  Future<void> _syncQueue(
    List<ConversationListEntry> entries,
    int generation,
  ) async {
    final me = _account;
    if (me == null) {
      return;
    }
    final wanted = entries
        .where((e) => canWatch(e, me))
        .map((e) => e.conversationId)
        .where((id) => id.isNotEmpty)
        .toSet();
    _denied
      ..clear()
      ..addAll(
        entries
            .where((entry) => !canWatch(entry, me))
            .map((entry) => entry.conversationId),
      );
    final removed = _background.difference(wanted);
    _background
      ..clear()
      ..addAll(wanted);
    for (final id in _denied.toList()) {
      _clearTypers(id);
      await setTyping(id, isTyping: false);
      await _unbindPresence(id);
      if (!_current(generation)) {
        return;
      }
      await _release(id);
    }
    for (final id in removed) {
      if (!_current(generation)) {
        return;
      }
      await _release(id);
    }
    for (final id in wanted) {
      if (!_current(generation)) {
        return;
      }
      if (_background.contains(id)) {
        await _bind(id, generation);
        if (_current(generation) && _foreground.containsKey(id)) {
          await _bindPresence(id, generation);
        }
      }
    }
  }

  Future<void> _bind(String id, int generation) async {
    if (_bindings.containsKey(id) || !_current(generation)) {
      return;
    }
    final handlers = <String, PusherEventHandler>{};
    _bindings[id] = handlers;
    for (final event in _convEvents) {
      void handler(Map<String, dynamic> data) {
        if (_current(generation)) {
          _onConversationEvent(id, event, data);
        }
      }

      handlers[event] = handler;
      await _pusher.bindEvent(
        channelName: 'private-conversation-$id',
        eventName: event,
        handler: handler,
      );
      if (!_current(generation) || !identical(_bindings[id], handlers)) {
        return;
      }
    }
  }

  Future<void> watchConversation(String conversationId) async {
    if (_disposed || _account == null || conversationId.isEmpty) {
      return;
    }
    _foreground.update(conversationId, (v) => v + 1, ifAbsent: () => 1);
    if (_denied.contains(conversationId)) {
      return;
    }
    final generation = _generation;
    await _bind(conversationId, generation);
    if (_current(generation) && _foreground.containsKey(conversationId)) {
      await _bindPresence(conversationId, generation);
    }
  }

  Future<void> unwatchConversation(String conversationId) async {
    final count = _foreground[conversationId] ?? 0;
    if (count > 1) {
      _foreground[conversationId] = count - 1;
      return;
    }
    _foreground.remove(conversationId);
    final presence = _unbindPresence(conversationId);
    final release = _release(conversationId);
    _clearTypers(conversationId);
    await setTyping(conversationId, isTyping: false);
    await presence;
    await release;
  }

  Future<void> _release(String id) async {
    if (!_denied.contains(id) &&
        (_background.contains(id) || _foreground.containsKey(id))) {
      return;
    }
    final handlers = _bindings.remove(id);
    if (handlers == null) {
      return;
    }
    for (final entry in handlers.entries.toList()) {
      await _pusher.unbindEvent(
        channelName: 'private-conversation-$id',
        eventName: entry.key,
        handler: entry.value,
      );
    }
  }

  void _onConversationEvent(
    String id,
    String name,
    Map<String, dynamic> payload,
  ) {
    final event = ConversationRealtimeEvent(id, name, payload);
    _events.add(event);
    if (name == 'client-typing') {
      _remoteTyping(id, event.data);
      return;
    }
    if (name == 'message.new') {
      _removeTyper(id, event.data['senderId']?.toString());
      _queueDelivered(id, event.data);
      _ref
          .read(supportQueueProvider.notifier)
          .recordActivity(
            MessageModel.fromJson({
              ...event.data,
              'conversationId': id,
            }).toEntity(),
            received:
                !(isForeground && id == _ref.read(visibleConversationProvider)),
          );
    }
    _threadEvents.add(id);
    _ref.invalidate(supportQueueProvider);
    if (name != 'message.new' ||
        (isForeground && id == _ref.read(visibleConversationProvider))) {
      return;
    }
    final data = event.data;
    final sender = data['sender'];
    final senderId =
        data['senderId']?.toString() ??
        (sender is Map ? sender['id']?.toString() : null);
    if (senderId == _account) {
      return;
    }
    final author = sender is Map
        ? '${sender['firstName'] ?? ''} ${sender['lastName'] ?? ''}'.trim()
        : '';
    final content = data['content']?.toString() ?? '';
    _emitIncoming(
      data['messageId']?.toString() ?? data['id']?.toString(),
      IncomingMessage(
        conversationId: id,
        author: author.isEmpty ? 'Nouveau message' : author,
        preview: content.isNotEmpty
            ? content
            : switch (data['type']) {
                'audio' => '🎤 Note vocale',
                'image' => '📷 Photo',
                'file' => '📎 Fichier',
                _ => '',
              },
      ),
    );
  }

  /// Account notifications also reach support observers who cannot subscribe
  /// to the private conversation until they claim it. Share deduplication with
  /// conversation events and FCM so a single message produces one banner.
  void handleNotification(Map<String, dynamic> payload) {
    if (_disposed || _account == null || !isForeground) return;
    final data = ConversationRealtimeEvent.normalize(payload);
    if (data['type'] != 'message.new') return;
    final id = data['conversationId']?.toString();
    if (id == null ||
        id.isEmpty ||
        data['senderId'] == _account ||
        id == _ref.read(visibleConversationProvider)) {
      return;
    }
    final observer = data['visibility'] == 'observer';
    final name = data['senderName']?.toString().trim() ?? '';
    _emitIncoming(
      data['messageId']?.toString(),
      IncomingMessage(
        conversationId: id,
        author: observer
            ? 'Nouveau message support'
            : (name.isEmpty ? 'Nouveau message' : name),
        preview: observer
            ? 'Un client a envoyé un nouveau message au support.'
            : (data['preview'] ??
                      data['body'] ??
                      data['content'] ??
                      'Vous avez reçu un nouveau message.')
                  .toString(),
      ),
    );
  }

  void _emitIncoming(String? messageId, IncomingMessage message) {
    if (messageId != null && messageId.isNotEmpty) {
      if (!_incomingSeen.add(messageId)) return;
      if (_incomingSeen.length > 256) _incomingSeen.remove(_incomingSeen.first);
    }
    _incoming.add(message);
  }

  void _queueDelivered(String conversationId, Map<String, dynamic> data) {
    if (_account == null ||
        _denied.contains(conversationId) ||
        (isForeground && _foreground.containsKey(conversationId))) {
      return;
    }
    final sender = data['senderId']?.toString();
    final id = (data['messageId'] ?? data['id'])?.toString();
    if (sender == null || sender == _account || id == null || id.isEmpty) {
      return;
    }
    _pendingDelivered.putIfAbsent(conversationId, () => {}).add(id);
    _scheduleDelivery(const Duration(milliseconds: 250));
  }

  void _scheduleDelivery(Duration delay) {
    if (_deliveryTimer?.isActive ?? false) {
      return;
    }
    final generation = _generation;
    _deliveryTimer = Timer(delay, () => unawaited(_flushDelivered(generation)));
  }

  Future<void> _flushDelivered(int generation) async {
    if (!_current(generation) || _delivering) {
      return;
    }
    _delivering = true;
    final client = _ref.read(apiClientProvider);
    var retry = false;
    try {
      for (final conversation in _pendingDelivered.keys.toList()) {
        if (!_current(generation)) {
          return;
        }
        if (_denied.contains(conversation) ||
            !_bindings.containsKey(conversation)) {
          _pendingDelivered.remove(conversation);
          continue;
        }
        final pending = _pendingDelivered.remove(conversation)!;
        final ids = pending.toList();
        for (var offset = 0; offset < ids.length; offset += 100) {
          if (!_current(generation) || _denied.contains(conversation)) {
            return;
          }
          final batch = ids.sublist(
            offset,
            (offset + 100).clamp(0, ids.length),
          );
          var success = false;
          var forbidden = false;
          try {
            final result = await client.request<bool>(
              path: ApiEndpoints.markDelivered(conversation),
              method: HttpMethod.post,
              data: {'messageIds': batch},
              fromJson: (_) => true,
            );
            success = result is ApiSuccess<bool>;
            forbidden =
                result is ApiError<bool> &&
                (result.statusCode == 403 || result.statusCode == 404);
          } catch (_) {
            /* Keep explicit IDs for a bounded retry or reconnect. */
          }
          if (!_current(generation)) {
            return;
          }
          if (!success && !forbidden) {
            _pendingDelivered.putIfAbsent(conversation, () => {}).addAll(batch);
            final count = _deliveryRetries.update(
              conversation,
              (value) => value + 1,
              ifAbsent: () => 1,
            );
            retry = retry || count <= 3;
          } else if (success) {
            _deliveryRetries.remove(conversation);
          }
        }
      }
    } finally {
      if (_current(generation)) {
        _delivering = false;
        // Messages can arrive while a batch is in flight. Drain those too,
        // without restarting exhausted retries until the next reconnect.
        if (_pendingDelivered.keys.any(
          (id) => (_deliveryRetries[id] ?? 0) <= 3,
        )) {
          _scheduleDelivery(
            retry
                ? const Duration(seconds: 2)
                : const Duration(milliseconds: 250),
          );
        }
      }
    }
  }

  void _remoteTyping(String id, Map<String, dynamic> data) {
    final user = data['userId']?.toString();
    if (user == null || user == _account) {
      return;
    }
    if (data['isTyping'] != true) {
      _removeTyper(id, user);
      return;
    }
    _typers.putIfAbsent(id, () => {})[user] = data['name']?.toString() ?? '';
    final timers = _typerTimers.putIfAbsent(id, () => {});
    timers.remove(user)?.cancel();
    timers[user] = Timer(
      const Duration(seconds: 6),
      () => _removeTyper(id, user),
    );
    _typingChanges.add(ConversationTyping(id, typingSnapshot(id)));
  }

  void _removeTyper(String id, String? user) {
    _typerTimers[id]?.remove(user)?.cancel();
    if (_typers[id]?.remove(user) != null && !_disposed) {
      _typingChanges.add(ConversationTyping(id, typingSnapshot(id)));
    }
  }

  void _clearTypers(String id) {
    for (final timer in _typerTimers.remove(id)?.values ?? <Timer>[]) {
      timer.cancel();
    }
    _typers.remove(id);
    if (!_disposed) {
      _typingChanges.add(ConversationTyping(id, const {}));
    }
  }

  void _connectionChanged(RealtimeConnectionState state) {
    if (state != RealtimeConnectionState.connected) {
      for (final id in _typers.keys.toList()) {
        _clearTypers(id);
      }
      for (final id in _members.keys.toList()) {
        _members[id]?.clear();
        if (!_disposed) {
          _presence.add(ConversationPresence(id, const {}));
        }
      }
    }
    if (_disposed ||
        _account == null ||
        state != RealtimeConnectionState.connected) {
      return;
    }
    _catchUpAll();
  }

  void _catchUpAll() {
    if (_disposed || _account == null) {
      return;
    }
    _ref.invalidate(supportQueueProvider);
    if (_pendingDelivered.isNotEmpty) {
      _deliveryRetries.clear();
      _scheduleDelivery(Duration.zero);
    }
    for (final id in _bindings.keys.toList()) {
      _catchUp.add(id);
      _threadEvents.add(id);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _catchUpAll();
      for (final id in _foreground.keys.toList()) {
        unawaited(_bindPresence(id, _generation));
      }
    } else {
      for (final id in _foreground.keys.toList()) {
        unawaited(setTyping(id, isTyping: false));
        unawaited(_unbindPresence(id));
      }
    }
  }

  Future<void> setTyping(
    String conversationId, {
    required bool isTyping,
  }) async {
    if (_disposed || _account == null) {
      return;
    }
    _typingIdle.remove(conversationId)?.cancel();
    if (isTyping &&
        (!isForeground || !_foreground.containsKey(conversationId))) {
      return;
    }
    if (isTyping) {
      _typingIdle[conversationId] = Timer(
        const Duration(seconds: 4),
        () => unawaited(setTyping(conversationId, isTyping: false)),
      );
    }
    final now = DateTime.now();
    final last = _typingSent[conversationId];
    if (isTyping &&
        last != null &&
        now.difference(last) < const Duration(seconds: 3)) {
      return;
    }
    if (!isTyping && last == null) {
      return;
    }
    final generation = _generation;
    final sent = await _pusher.trigger(
      channelName: 'private-conversation-$conversationId',
      eventName: 'client-typing',
      data: {
        'userId': _account,
        'name': _ref.read(currentUserProvider)?.displayName ?? '',
        'isTyping': isTyping,
      },
    );
    if (!_current(generation)) {
      return;
    }
    if (sent && isTyping) {
      _typingSent[conversationId] = now;
    } else if (!isTyping) {
      _typingSent.remove(conversationId);
    }
  }

  Future<void> _bindPresence(String id, int generation) async {
    if (_presenceBindings.containsKey(id) ||
        !isForeground ||
        _denied.contains(id)) {
      return;
    }
    final handlers = <String, PusherEventHandler>{};
    _presenceBindings[id] = handlers;
    for (final event in [
      'pusher_internal:subscription_succeeded',
      'pusher_internal:member_added',
      'pusher_internal:member_removed',
    ]) {
      void handler(Map<String, dynamic> data) {
        if (!_current(generation) ||
            !identical(_presenceBindings[id], handlers)) {
          return;
        }
        final members = _members.putIfAbsent(id, () => {});
        if (event.endsWith('subscription_succeeded')) {
          members.clear();
          final presence = data['presence'];
          final hash = presence is Map ? presence['hash'] : null;
          if (hash is Map) {
            for (final member in hash.entries) {
              members[member.key.toString()] = member.value is Map
                  ? Map<String, dynamic>.from(member.value as Map)
                  : {};
            }
          }
        } else if (event.endsWith('member_added')) {
          final memberId = data['user_id']?.toString();
          if (memberId != null) {
            members[memberId] = data['user_info'] is Map
                ? Map<String, dynamic>.from(data['user_info'] as Map)
                : {};
          }
        } else {
          members.remove(data['user_id']?.toString());
        }
        _presence.add(ConversationPresence(id, Map.unmodifiable(members)));
      }

      handlers[event] = handler;
      await _pusher.bindEvent(
        channelName: 'presence-conversation-$id',
        eventName: event,
        handler: handler,
      );
      if (!_current(generation) ||
          !identical(_presenceBindings[id], handlers)) {
        return;
      }
    }
  }

  Future<void> _unbindPresence(String id) async {
    final handlers = _presenceBindings.remove(id);
    _members.remove(id);
    if (!_disposed) {
      _presence.add(ConversationPresence(id, const {}));
    }
    if (handlers == null) {
      return;
    }
    for (final entry in handlers.entries.toList()) {
      await _pusher.unbindEvent(
        channelName: 'presence-conversation-$id',
        eventName: entry.key,
        handler: entry.value,
      );
    }
  }

  void _clearLocal() {
    _incomingSeen.clear();
    _queueRefreshTimer?.cancel();
    _deliveryTimer?.cancel();
    _pendingDelivered.clear();
    _deliveryRetries.clear();
    _delivering = false;
    for (final id in _members.keys.toList()) {
      if (!_disposed) {
        _presence.add(ConversationPresence(id, const {}));
      }
    }
    for (final id in _typers.keys.toList()) {
      _clearTypers(id);
    }
    for (final timer in _typingIdle.values) {
      timer.cancel();
    }
    _typingIdle.clear();
    _typingSent.clear();
    _denied.clear();
    _background.clear();
    _foreground.clear();
    _bindings.clear();
    _presenceBindings.clear();
    _members.clear();
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    _queueSubscription?.close();
    unawaited(_connectionSubscription?.cancel());
    _clearLocal();
    unawaited(_pusher.dispose());
    unawaited(_threadEvents.close());
    unawaited(_events.close());
    unawaited(_presence.close());
    unawaited(_incoming.close());
    unawaited(_catchUp.close());
    unawaited(_typingChanges.close());
  }
}

class IncomingMessage {
  const IncomingMessage({
    required this.conversationId,
    required this.author,
    required this.preview,
  });
  final String conversationId;
  final String author;
  final String preview;
}
