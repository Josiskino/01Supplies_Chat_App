import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/storage_service.dart';

part 'locale_provider.g.dart';

/// Langue de l'application. Persistée en SharedPreferences.
///
/// Le français est la langue par défaut : les équipes logistique 01Supplies
/// sont francophones.
///
/// `keepAlive` pour la même raison que le thème : préférence globale chargée de
/// façon asynchrone.
@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  static const Locale fallbackLocale = Locale('fr');

  static const List<Locale> supportedLocales = [Locale('fr'), Locale('en')];

  @override
  Locale build() {
    _loadLocale();
    return fallbackLocale;
  }

  Future<void> _loadLocale() async {
    final saved = await StorageService.instance.getLocale();
    if (!ref.mounted) return;
    if (saved != null && supportedLocales.any((l) => l.languageCode == saved)) {
      state = Locale(saved);
    }
  }

  void setLocale(Locale locale) {
    if (!supportedLocales.any((l) => l.languageCode == locale.languageCode)) {
      return;
    }
    state = locale;
    StorageService.instance.saveLocale(locale.languageCode);
  }
}
