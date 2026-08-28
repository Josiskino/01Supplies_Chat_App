import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constant.dart';
import '../providers/auth/auth_provider.dart';
import '../providers/messaging/support_provider.dart';
import '../providers/auth/auth_status_provider.dart';
import '../auth/auth_gate.dart';
import '../utils/app_logger.dart';
import '../utils/preferences.dart';
import 'pusher_service.dart';

/// Relie les événements Pusher aux providers de la messagerie.
///
/// ## Deux canaux, deux portées
///
/// - `private-user-{id}` : ce qui **apparaît** — une conversation créée, un
///   ticket mis à jour. Écouté en permanence, c'est lui qui fait entrer une
///   nouvelle demande dans la file sans rechargement.
/// - `private-conversation-{id}` : ce qui se dit **dans** un fil. Souscrit à
///   l'ouverture d'une conversation, relâché à sa fermeture — s'abonner aux
///   quarante-cinq fils ouverts ferait payer à l'appareil un trafic qu'aucun
///   écran n'affiche.
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
  /// Le backend exige le jeton porteur : sans lui il refuse la signature, et
  /// l'abonnement échoue silencieusement — le fil paraît simplement figé.
  Future<Map<String, dynamic>?> _authorize(
    String channelName,
    String socketId,
  ) async {
    final token = await SharedPreferencesHelper.getValue(StorageKeys.token);
    if (token.isEmpty) return null;

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstant.baseUrlWithPrefix,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      final response = await dio.post(
        ApiConstant.pusherAuthPath.replaceFirst(RegExp(r'^/'), ''),
        data: {'socket_id': socketId, 'channel_name': channelName},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      if (data is Map) return data.cast<String, dynamic>();
      if (data is String) {
        return (jsonDecode(data) as Map).cast<String, dynamic>();
      }
      return null;
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
    unawaited(_threadEvents.close());
    unawaited(_disconnect());
  }
}
