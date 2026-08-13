/// Masque les valeurs sensibles avant journalisation.
///
/// Les corps de requête d'authentification transportent des jetons et des mots
/// de passe. Même si les journaux sont coupés en release, un log de debug est
/// couramment copié dans un ticket, un chat ou une capture — et le jeton part
/// avec. Le masquage se fait donc à l'écriture, pas à la lecture.
abstract final class LogRedaction {
  static const Set<String> _sensitiveKeys = {
    'idtoken',
    'id_token',
    'accesstoken',
    'access_token',
    'refreshtoken',
    'refresh_token',
    'token',
    'password',
    'newpassword',
    'oldpassword',
    'confirmpassword',
    'authorization',
    'otp',
    'code',
    'secret',
    'apikey',
    'api_key',
  };

  /// Renvoie une copie de [data] dont les valeurs sensibles sont remplacées.
  ///
  /// Tout ce qui n'est pas une `Map` est rendu tel quel : on ne peut pas
  /// inspecter un `FormData` ou une chaîne sans risquer de fausser le
  /// diagnostic, et ces formes ne portent pas de jeton en pratique.
  static Object? redact(Object? data, {int depth = 0}) {
    // Garde-fou : une structure cyclique ou très profonde ne doit pas faire
    // boucler la journalisation elle-même.
    if (depth > 5) return data;

    if (data is Map) {
      return data.map((key, value) {
        final normalized = key.toString().toLowerCase().replaceAll('_', '');
        if (_sensitiveKeys.contains(normalized) ||
            _sensitiveKeys.contains(key.toString().toLowerCase())) {
          return MapEntry(key, _mask(value));
        }
        return MapEntry(key, redact(value, depth: depth + 1));
      });
    }
    if (data is List) {
      return data.map((e) => redact(e, depth: depth + 1)).toList();
    }
    return data;
  }

  /// Conserve la longueur : savoir qu'un jeton était présent et non vide est
  /// souvent l'information utile au diagnostic.
  static String _mask(Object? value) {
    if (value == null) return 'null';
    final length = value.toString().length;
    return '<masqué:$length caractères>';
  }
}
