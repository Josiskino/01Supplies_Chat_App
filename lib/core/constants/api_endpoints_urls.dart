/// Chemins de l'API, relatifs à `ApiConstant.baseUrlWithPrefix`.
///
/// Regroupés par domaine. La feature messagerie complétera la section
/// correspondante ; les chemins exacts sont à confirmer contre
/// `GET /api/spec.json`.
class ApiEndpoints {
  ApiEndpoints._();

  //**** AUTHENTICATION *****//
  static const String login = 'auth/login';
  static const String logout = 'auth/logout';
  static const String refreshTokens = 'auth/refresh-tokens';
  static const String profile = 'auth/profile';
  static const String validateToken = 'auth/validate-token';
  static const String forgotPassword = 'auth/forgot-password';
  static const String resetPassword = 'auth/reset-password';
  static const String changePassword = 'auth/change-password';

  //**** USERS *****//
  static const String users = 'users';
  static String userById(String id) => 'users/$id';

  //**** MESSAGING *****//
  // Le module messaging est partagé avec les apps client et livreur.
  //
  // ⚠️ Deux vues distinctes des tickets, à ne pas confondre :
  //  - `supportQueue` : **tous** les tickets de la plateforme, la file commune
  //    que les admins se répartissent. C'est ce que montre l'onglet
  //    Conversations.
  //  - `myTickets` : ceux qui vous sont assignés. Vide tant qu'on ne s'est
  //    saisi de rien — ce qui donne une app vide si on l'utilise pour la liste.
  static const String supportQueue = 'messaging/support';
  static const String myTickets = 'messaging/support/me';
  static String claimTicket(String id) => 'messaging/support/$id/claim';
  static String assignTicket(String id) => 'messaging/support/$id/assign';

  static const String conversations = 'messaging/conversations';
  static const String messages = 'messaging/messages';
  static String messagesOfConversation(String id) =>
      'messaging/messages/conversation/$id';
  static String markRead(String conversationId) =>
      'messaging/conversations/$conversationId/read';
  static String markDelivered(String conversationId) =>
      'messaging/conversations/$conversationId/delivered';

  //**** NOTIFICATIONS *****//
  /// Enregistre le jeton FCM de l'appareil, pour que le backend puisse le
  /// joindre quand l'application est fermée.
  static const String devices = 'users/me/devices';
  static String device(String deviceId) => 'users/me/devices/$deviceId';

  //**** MEDIA *****//
  static const String mediaUpload = 'media/upload';

  //**** NOTIFICATIONS *****//
  static const String notifications = 'notifications';
  static String markNotificationRead(String id) => 'notifications/$id/read';
  static const String registerDevice = 'notifications/devices';
}
