import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Pont entre les fichiers `.env` et le code.
///
/// Seul endroit qui lit `dotenv` : le reste de l'app dépend de ces getters, ce
/// qui rend une clé manquante détectable en un point unique.
class ApiConstant {
  ApiConstant._();

  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  static const String prefix = 'api/';

  /// URL de base incluant le préfixe `api/`, quelle que soit la présence d'un
  /// slash final dans le `.env`.
  static String get baseUrlWithPrefix {
    final base = baseUrl;
    if (base.isEmpty) return prefix;
    return base.endsWith('/') ? '$base$prefix' : '$base/$prefix';
  }

  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  static String get xApiKey => _stripQuotes(dotenv.env['X_API_KEY']);

  /// URL du canal temps réel (Socket.IO). Utilisée par la feature messagerie.
  static String get socketUrl => dotenv.env['SOCKET_URL'] ?? '';

  /// Construit l'URL complète d'un média ; passe-through si déjà absolue.
  static String? buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    final base = baseUrl;
    if (base.isEmpty) return imagePath;
    final normalizedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final normalizedPath = imagePath.startsWith('/')
        ? imagePath
        : '/$imagePath';
    return '$normalizedBase$normalizedPath';
  }

  /// Certains éditeurs de `.env` conservent les guillemets autour des valeurs ;
  /// ils partiraient sinon dans les en-têtes HTTP.
  static String _stripQuotes(String? value) {
    if (value == null || value.isEmpty) return '';
    var v = value.trim();
    if (v.length >= 2 &&
        ((v.startsWith('"') && v.endsWith('"')) ||
            (v.startsWith("'") && v.endsWith("'")))) {
      v = v.substring(1, v.length - 1);
    }
    return v;
  }
}
