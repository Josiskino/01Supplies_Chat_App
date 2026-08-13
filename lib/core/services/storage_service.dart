import 'package:shared_preferences/shared_preferences.dart';

import '../utils/preferences.dart';

/// Préférences d'affichage (thème, langue).
///
/// Séparé de [SharedPreferencesHelper], qui porte les données de session : les
/// préférences d'UI survivent à une déconnexion, les jetons non.
class StorageService {
  StorageService._internal();

  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;

  Future<void> saveThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.themeMode, themeMode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.themeMode);
  }

  Future<void> saveLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.locale, languageCode);
  }

  Future<String?> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.locale);
  }
}
