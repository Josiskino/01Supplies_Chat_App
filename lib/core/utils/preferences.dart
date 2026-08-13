import '../abstract/local_storage_interface.dart';
import '../services/local_storage/shared_preferences_storage.dart';

/// Façade d'accès au stockage local.
///
/// Passe par [LocalStorageInterface] plutôt que par SharedPreferences
/// directement : c'est ce qui permet à [setStorage] de substituer une
/// implémentation en mémoire dans les tests.
class SharedPreferencesHelper {
  SharedPreferencesHelper._();

  static LocalStorageInterface _storage = SharedPreferencesStorage();

  /// Remplace l'implémentation de stockage (tests, changement de package).
  static void setStorage(LocalStorageInterface storage) {
    _storage = storage;
  }

  static Future<String> getValue(String key) => _storage.getString(key);

  static Future<int> getIntValue(String key) => _storage.getInt(key);

  static Future<bool?> getBoolValue(String key) => _storage.getBool(key);

  static Future<bool> setValue(String key, String value) =>
      _storage.setString(key, value);

  static Future<bool> setIntValue(String key, int value) =>
      _storage.setInt(key, value);

  static Future<bool> setBoolValue(String key, bool value) =>
      _storage.setBool(key, value);

  static Future<bool> deleteValue(String key) => _storage.remove(key);

  static Future<bool> clearAll() => _storage.clear();
}

/// Clés de stockage utilisées par le socle.
///
/// Regroupées ici pour qu'une faute de frappe dans une chaîne littérale ne
/// puisse pas créer silencieusement une seconde entrée.
abstract final class StorageKeys {
  static const String token = 'token';
  static const String tokenExpires = 'token_expires';
  static const String refreshToken = 'refresh_token';
  static const String userProfile = 'user_profile';
  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
}
