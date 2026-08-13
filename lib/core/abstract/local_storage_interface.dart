/// Interface abstraite pour le stockage local.
///
/// Découple le code de l'implémentation (SharedPreferences, Hive…) et rend le
/// stockage substituable en test via `SharedPreferencesHelper.setStorage`.
abstract class LocalStorageInterface {
  Future<String> getString(String key);
  Future<int> getInt(String key);
  Future<bool?> getBool(String key);
  Future<bool> setString(String key, String value);
  Future<bool> setInt(String key, int value);
  Future<bool> setBool(String key, bool value);
  Future<bool> remove(String key);
  Future<bool> clear();
}
