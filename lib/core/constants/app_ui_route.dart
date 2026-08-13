/// Chemins des routes GoRouter.
///
/// Source unique de vérité : aucune chaîne de route ne doit être écrite en dur
/// ailleurs, sous peine de divergence silencieuse entre le routeur et l'AuthGate.
class AppUiRoute {
  AppUiRoute._();

  // ── Amorçage & authentification ───────────────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';

  // ── Coquille principale (navigation adaptative) ───────────────────────────
  static const String main = '/main';

  // ── Onglets ───────────────────────────────────────────────────────────────
  // Les onglets ne sont pas des routes : ils vivent dans un IndexedStack piloté
  // par `mainTabProvider`. Ces constantes servent aux liens profonds et aux
  // redirections qui doivent viser un onglet précis.
  static const String conversations = '/main/conversations';
  static const String requests = '/main/requests';
  static const String contacts = '/main/contacts';
  static const String profile = '/main/profile';

  // ── Écrans hors coquille ──────────────────────────────────────────────────
  /// Fil de discussion. Le segment `:id` porte l'identifiant de conversation.
  static const String conversationDetail = '/conversation/:id';

  /// Construit le chemin d'une conversation donnée.
  static String conversationDetailPath(String id) => '/conversation/$id';

  static const String settings = '/settings';
  static const String imageViewer = '/image-viewer';
}
