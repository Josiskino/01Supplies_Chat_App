/// Traduit une erreur API en **message métier** destiné à l'utilisateur.
///
/// Règle : le message serveur brut ne doit **jamais** être affiché tel quel (il
/// part dans les logs). Ici on renvoie :
/// 1. un message métier connu (petite allowlist de cas où le message serveur
///    porte un vrai sens métier) ;
/// 2. sinon un message générique par code HTTP.
abstract final class ApiErrorMessages {
  static String resolve({
    int? statusCode,
    String? serverMessage,
    String? requestPath,
  }) {
    return _known(serverMessage) ?? _byStatus(statusCode, requestPath);
  }

  /// Cas où le message serveur porte un vrai sens métier → message FR dédié.
  static String? _known(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final m = raw.toLowerCase();

    if (m.contains('already exists') ||
        m.contains('already in use') ||
        m.contains('already registered') ||
        m.contains('already taken')) {
      return 'Ce compte existe déjà.';
    }
    if (m.contains('invalid credentials') ||
        m.contains('incorrect password') ||
        m.contains('wrong password') ||
        m.contains('invalid password') ||
        m.contains('invalid email or password')) {
      return 'E-mail ou mot de passe incorrect.';
    }
    if (m.contains('user not found') || m.contains('account not found')) {
      return 'Compte introuvable.';
    }
    if ((m.contains('otp') || m.contains('code')) &&
        (m.contains('invalid') ||
            m.contains('expired') ||
            m.contains('incorrect'))) {
      return 'Code invalide ou expiré.';
    }

    return null;
  }

  /// Un 401 ne veut pas dire la même chose selon l'appel : sur une tentative de
  /// connexion il signifie « identifiants refusés », ailleurs « jeton expiré ».
  /// Sans cette distinction, un mot de passe erroné invite l'utilisateur à « se
  /// reconnecter » — ce qu'il est précisément en train de faire.
  static bool _isCredentialLogin(String? path) {
    if (path == null) return false;
    return path.contains('/auth/login') || path.contains('/auth/register');
  }

  static String _byStatus(int? status, [String? path]) {
    if (status == null) {
      return 'Connexion impossible. Vérifiez votre réseau et réessayez.';
    }
    switch (status) {
      case 400:
        return 'Requête invalide. Vérifiez les informations saisies.';
      case 401:
        if (_isCredentialLogin(path)) {
          return 'E-mail ou mot de passe incorrect.';
        }
        return 'Session expirée. Veuillez vous reconnecter.';
      case 403:
        return "Vous n'êtes pas autorisé à effectuer cette action.";
      case 404:
        return 'Élément introuvable.';
      case 408:
        return 'Délai dépassé. Réessayez.';
      case 409:
        return "Cette action n'a pas pu être effectuée (conflit).";
      case 422:
        return 'Certaines informations sont invalides.';
      case 429:
        return 'Trop de tentatives. Réessayez dans un instant.';
      default:
        if (status >= 500) {
          return 'Une erreur est survenue. Réessayez plus tard.';
        }
        return 'Une erreur est survenue.';
    }
  }
}
