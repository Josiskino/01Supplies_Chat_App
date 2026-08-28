import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/auth_gate.dart';
import '../../services/push_notification_service.dart';
import '../auth/auth_status_provider.dart';
import '../request/api_provider.dart';

part 'push_provider.g.dart';

@Riverpod(keepAlive: true)
PushNotificationService pushNotifications(Ref ref) =>
    PushNotificationService(ref.watch(apiClientProvider));

/// Enregistre l'appareil dès qu'une session s'ouvre.
///
/// Lié à l'authentification et non au démarrage : l'endpoint est authentifié, et
/// un jeton déposé sans session ne serait rattaché à aucun compte — l'appareil
/// resterait injoignable.
@Riverpod(keepAlive: true)
void pushRegistration(Ref ref) {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

  ref.listen<AuthGateStatus>(authStatusProvider, (previous, next) {
    if (next == AuthGateStatus.authenticated) {
      unawaited(ref.read(pushNotificationsProvider).registerDevice());
    }
  }, fireImmediately: true);
}

/// Conversation à ouvrir suite au tap sur une notification.
///
/// Le message porte `conversationId` — même charge utile que celle routée par
/// l'app cliente. Sans cet aiguillage, toucher une notification ouvrirait
/// l'accueil, obligeant à retrouver la discussion à la main.
@Riverpod(keepAlive: true)
Stream<PushRoute> pushRoute(Ref ref) {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
    return const Stream.empty();
  }

  final controller = StreamController<PushRoute>.broadcast();

  // Application ouverte en arrière-plan, l'utilisateur touche la notification.
  final sub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final route = PushRoute.fromData(message.data);
    if (route != null) controller.add(route);
  });

  // Application lancée **depuis** la notification : le message est consommé une
  // seule fois, et se perd si personne ne le demande au démarrage.
  unawaited(
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message == null) return;
      final route = PushRoute.fromData(message.data);
      if (route != null) controller.add(route);
    }),
  );

  ref.onDispose(() {
    unawaited(sub.cancel());
    unawaited(controller.close());
  });

  return controller.stream;
}

/// Destination extraite d'une notification.
class PushRoute {
  const PushRoute({required this.conversationId, required this.title});

  final String conversationId;
  final String title;

  static PushRoute? fromData(Map<String, dynamic> data) {
    final id = data['conversationId']?.toString();
    if (id == null || id.isEmpty) return null;
    return PushRoute(
      conversationId: id,
      title:
          data['senderName']?.toString() ??
          data['conversationName']?.toString() ??
          'Conversation',
    );
  }
}
