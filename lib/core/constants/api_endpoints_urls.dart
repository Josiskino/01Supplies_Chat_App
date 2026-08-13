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
  // Le module messaging du backend est déjà consommé par les apps client et
  // livreur. Les chemins ci-dessous sont le point d'entrée connu ; la feature
  // les complétera (conversations, messages, pièces jointes, accusés de lecture).
  static const String supportTickets = 'messaging/support/me';

  //**** MEDIA *****//
  static const String mediaUpload = 'media/upload';

  //**** NOTIFICATIONS *****//
  static const String notifications = 'notifications';
  static String markNotificationRead(String id) => 'notifications/$id/read';
  static const String registerDevice = 'notifications/devices';
}
