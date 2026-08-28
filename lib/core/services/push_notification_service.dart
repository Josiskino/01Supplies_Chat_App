import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../abstract/api_client_interface.dart';
import '../constants/api_endpoints_urls.dart';
import '../utils/api_types.dart';
import '../utils/app_logger.dart';

/// Notifications système, via Firebase Cloud Messaging.
///
/// ## Ce que ce service fait, et ne fait pas
///
/// Il obtient le jeton de l'appareil et le confie au backend, qui envoie déjà
/// des push de messagerie — l'app cliente les reçoit et les route depuis
/// longtemps. Il ne compose aucune notification : c'est le serveur qui décide
/// quoi dire et à qui.
///
/// ## Limites de plateforme
///
/// Android et iOS seulement. `firebase_messaging` ne supporte pas Windows, et
/// macOS exige une configuration APNs distincte que le projet n'a pas.
///
/// ⚠️ **Le simulateur iOS n'obtient jamais de jeton APNs.** Sur simulateur,
/// `getToken()` renvoie `null` et aucune notification n'arrivera : la
/// vérification demande un appareil physique.
class PushNotificationService {
  PushNotificationService(this._client);

  final ApiClientInterface _client;
  final AppLogger _logger = AppLogger();

  String? _registeredToken;

  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  /// Demande l'autorisation, récupère le jeton et l'enregistre.
  ///
  /// Appelé après la connexion : l'endpoint est authentifié, et un jeton
  /// déposé sans session ne serait rattaché à personne.
  Future<void> registerDevice() async {
    if (!isSupported) return;

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _logger.info(
          'Notifications refusées par l’utilisateur',
          feature: 'Push',
        );
        return;
      }

      // Sur iOS, le jeton FCM n'existe qu'une fois le jeton APNs obtenu ;
      // le simulateur n'en produit jamais, d'où ce garde-fou explicite.
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        _logger.warning(
          'Aucun jeton FCM — simulateur, ou APNs non configuré',
          feature: 'Push',
        );
        return;
      }

      await _sendToken(token);

      // Le jeton peut être renouvelé par le système à tout moment : sans cet
      // abonnement, l'appareil devient injoignable sans que rien ne le signale.
      messaging.onTokenRefresh.listen(_sendToken);
    } catch (e, s) {
      // Une notification qui ne s'installe pas ne doit pas empêcher d'utiliser
      // l'application.
      _logger.error(
        'Enregistrement des notifications impossible',
        feature: 'Push',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _sendToken(String token) async {
    if (token == _registeredToken) return;

    final result = await _client.request<bool>(
      path: ApiEndpoints.devices,
      method: HttpMethod.post,
      data: {'fcmToken': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      fromJson: (_) => true,
    );

    switch (result) {
      case ApiSuccess():
        _registeredToken = token;
        _logger.info(
          'Appareil enregistré pour les notifications',
          feature: 'Push',
        );
      case ApiError(message: final message):
        _logger.error('Enregistrement refusé : $message', feature: 'Push');
    }
  }
}
