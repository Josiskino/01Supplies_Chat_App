import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../abstract/api_client_interface.dart';
import '../constants/api_constant.dart';
import '../utils/api_types.dart';
import '../providers/request/api_provider.dart';
import '../providers/auth/auth_provider.dart';
import '../../domain/entity/messaging/conversation_list_entry.dart';
import '../providers/messaging/support_provider.dart';
import '../providers/realtime/realtime_provider.dart';
import '../providers/auth/auth_status_provider.dart';
import '../auth/auth_gate.dart';
import '../utils/app_logger.dart';
import 'pusher_service.dart';

/// Relie les événements Pusher aux providers de la messagerie.
///
/// ## Deux canaux, deux portées
///
/// - `private-user-{id}` : ce qui **apparaît** — une conversation créée, un
///   ticket mis à jour. Écouté en permanence, c'est lui qui fait entrer une
///   nouvelle demande dans la file sans rechargement.
/// - `private-conversation-{id}` : ce qui se dit **dans** un fil. Souscrit pour
///   **toutes les conversations dont on est participant**, pas seulement celle
///   affichée : sans cela, un message arrivé pendant qu'on regarde la liste ne
///   produit ni compteur ni notification, et le canal privé n'accepte de toute
///   façon que les conversations qu'on a rejointes.
///
/// Les noms d'événements sont ceux que l'app cliente écoute déjà : les changer
/// ici couperait l'un des deux bouts de la conversation.
class MessageEventsService {
  MessageEventsService(this._ref) {
    _ref.listen<AuthGateStatus>(authStatusProvider, (previous, next) {
      if (next == AuthGateStatus.authenticated) {
        unawaited(_subscribeUser());
      } else if (next == AuthGateStatus.unauthenticated) {
        unawaited(_disconnect());
      }
    }, fireImmediately: true);

    // La file dit de quelles conversations on est participant : à chaque
    // rechargement, on aligne les abonnements dessus. C'est ce qui fait vivre
    // les compteurs pendant qu'on regarde la liste.
    _ref.listen<AsyncValue<List<ConversationListEntry>>>(supportQueueProvider, (
      _,
      next,
    ) {
      final entries = next.value;
      if (entries != null) unawaited(_syncConversationSubscriptions(entries));
    }, fireImmediately: true);
  }

  final Ref _ref;
  final PusherService _pusher = PusherService();
  final AppLogger _logger = AppLogger();

  String? _userChannel;
  final Set<String> _conversationChannels = {};

  /// Événements du canal utilisateur.
  static const _userEvents = <String>[
    'conversation.created',
    'support.ticket.updated',
  ];

  /// Événements d'un canal de conversation.
  static const _convEvents = <String>[
    'message.new',
    'message.updated',
    'message.deleted',
  ];

  /// Appelé à chaque événement touchant un fil, pour que l'écran se rafraîchisse.
  final _threadEvents = StreamController<String>.broadcast();

  /// Identifiants de conversation dont le fil vient de changer.
  Stream<String> get threadChanges => _threadEvents.stream;

  /// Messages reçus alors que leur conversation n'était pas à l'écran.
  final _incoming = StreamController<IncomingMessage>.broadcast();

  /// À signaler à l'utilisateur : il ne regardait pas ce fil.
  Stream<IncomingMessage> get incomingMessages => _incoming.stream;

  /// Aligne les abonnements sur les conversations dont on est participant.
  ///
  /// Une demande que personne n'a prise est exclue : le canal privé refuse de
  /// signer pour qui n'y participe pas, et chaque tentative repartirait en
  /// boucle de réessais.
  Future<void> _syncConversationSubscriptions(
    List<ConversationListEntry> entries,
  ) async {
    final me = _ref.read(currentUserProvider)?.id;
    if (me == null) return;

    final wanted = entries
        .where((e) => !e.isUnclaimed)
        .map((e) => e.conversationId)
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final id in wanted) {
      await watchConversation(id);
    }
  }

  Future<void> _ensureConnected() async {
    if (_pusher.isConnected) return;
    await _pusher.connect(
      apiKey: ApiConstant.pusherAppKey,
      cluster: ApiConstant.pusherCluster,
      authorizer: _authorize,
    );
  }

  /// Signe l'abonnement à un canal privé.
  ///
  /// Passe par le client de l'application et **non** par un Dio neuf : c'est
  /// l'intercepteur qui porte le jeton et le renouvelle. Avec un client brut,
  /// une signature demandée après expiration échouait sans rien retenter, et
  /// l'abonnement était perdu jusqu'au redémarrage — le fil paraissait
  /// simplement figé.
  Future<Map<String, dynamic>?> _authorize(
    String channelName,
    String socketId,
  ) async {
    try {
      final result = await _ref
          .read(apiClientProvider)
          .request<Map<String, dynamic>>(
            path: ApiConstant.pusherAuthPath.replaceFirst(RegExp(r'^/'), ''),
            method: HttpMethod.post,
            data: {'socket_id': socketId, 'channel_name': channelName},
            // La signature arrive parfois à la racine, parfois sous `data`.
            fromJson: (json) {
              if (json.containsKey('auth')) return json;
              final inner = json['data'];
              if (inner is Map<String, dynamic>) return inner;
              return json;
            },
          );
      return switch (result) {
        ApiSuccess(data: final d) => d,
        _ => null,
      };
    } catch (e) {
      _logger.error('Pusher auth failed', feature: 'Realtime', error: e);
      return null;
    }
  }

  Future<void> _subscribeUser() async {
    final userId = _ref.read(currentUserProvider)?.id;
    if (userId == null || userId.isEmpty) return;

    final channel = 'private-user-$userId';
    if (_userChannel == channel) return;

    await _ensureConnected();
    for (final event in _userEvents) {
      await _pusher.bindEvent(
        channelName: channel,
        eventName: event,
        handler: (data) => _onUserEvent(event, data),
      );
    }
    _userChannel = channel;
    _logger.info('Abonné à $channel', feature: 'Realtime');
  }

  /// Écoute un fil précis. Idempotent : rouvrir un écran ne double pas les
  /// abonnements, ce qui ferait arriver chaque message en double.
  Future<void> watchConversation(String conversationId) async {
    if (conversationId.isEmpty) return;
    final channel = 'private-conversation-$conversationId';
    if (_conversationChannels.contains(channel)) return;

    await _ensureConnected();
    for (final event in _convEvents) {
      await _pusher.bindEvent(
        channelName: channel,
        eventName: event,
        handler: (data) => _onConversationEvent(conversationId, event, data),
      );
    }
    _conversationChannels.add(channel);
  }

  Future<void> unwatchConversation(String conversationId) async {
    final channel = 'private-conversation-$conversationId';
    if (!_conversationChannels.remove(channel)) return;
    for (final event in _convEvents) {
      await _pusher.unbindEvent(channelName: channel, eventName: event);
    }
  }

  void _onUserEvent(String event, Map<String, dynamic> data) {
    _logger.debug('Événement $event', feature: 'Realtime');
    // Une demande vient d'arriver ou de changer d'état : la file n'est plus à
    // jour. On la recharge plutôt que d'y insérer un élément à la main, faute
    // de quoi son tri et ses compteurs divergeraient du serveur.
    _ref.invalidate(supportQueueProvider);
  }

  void _onConversationEvent(
    String conversationId,
    String event,
    Map<String, dynamic> data,
  ) {
    _logger.debug('Événement $event sur $conversationId', feature: 'Realtime');
    _threadEvents.add(conversationId);

    // La file porte les compteurs de non-lus : elle doit être relue, sinon la
    // pastille reste sur sa valeur du dernier chargement.
    _ref.invalidate(supportQueueProvider);

    if (event != 'message.new') return;
    // Un message arrivé sous les yeux de l'utilisateur ne se notifie pas.
    if (conversationId == _ref.read(visibleConversationProvider)) return;

    final me = _ref.read(currentUserProvider)?.id;
    final sender = _senderIdOf(data);
    // Ses propres messages ne se notifient pas — ils reviennent par le canal
    // comme tous les autres.
    if (sender != null && sender == me) return;

    _incoming.add(
      IncomingMessage(
        conversationId: conversationId,
        author: _senderNameOf(data),
        preview: (data['content'] ?? '').toString(),
      ),
    );
  }

  static String? _senderIdOf(Map<String, dynamic> data) {
    final direct = data['senderId'];
    if (direct is String && direct.isNotEmpty) return direct;
    final sender = data['sender'];
    if (sender is Map) return sender['id']?.toString();
    return null;
  }

  static String _senderNameOf(Map<String, dynamic> data) {
    final sender = data['sender'];
    if (sender is Map) {
      final name = [
        sender['firstName'],
        sender['lastName'],
      ].whereType<String>().join(' ').trim();
      if (name.isNotEmpty) return name;
    }
    return 'Nouveau message';
  }

  Future<void> _disconnect() async {
    for (final channel in _conversationChannels.toList()) {
      for (final event in _convEvents) {
        await _pusher.unbindEvent(channelName: channel, eventName: event);
      }
    }
    _conversationChannels.clear();
    final user = _userChannel;
    if (user != null) {
      for (final event in _userEvents) {
        await _pusher.unbindEvent(channelName: user, eventName: event);
      }
    }
    _userChannel = null;
    await _pusher.disconnect();
  }

  void dispose() {
    unawaited(_incoming.close());
    unawaited(_threadEvents.close());
    unawaited(_disconnect());
  }
}

/// Un message arrivé hors du fil affiché.
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
