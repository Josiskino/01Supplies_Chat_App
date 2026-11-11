import 'package:flutter/cupertino.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/presentation/main/nav_destinations.dart';

/// Garde-fou de la source **unique** des destinations.
///
/// Les trois rendus (Material, Cupertino, desktop) lisent cette liste. Une
/// divergence y est invisible tant qu'on ne change pas de plateforme : un SF
/// Symbol inexistant ne casse rien à la compilation, il donne une case vide dans
/// la barre iOS. D'où ces vérifications au niveau de la déclaration.
void main() {
  test('Android omits search while other platforms keep all nav indices', () {
    expect(
      NavDestinations.forPlatform(AppPlatform.android).map((d) => d.index),
      [0, 1, 2, 3],
    );
    for (final platform in [
      AppPlatform.ios,
      AppPlatform.macos,
      AppPlatform.windows,
    ]) {
      expect(NavDestinations.forPlatform(platform).map((d) => d.index), [
        0,
        1,
        2,
        3,
        4,
      ]);
      expect(NavDestinations.forPlatform(platform).last.isSearch, isTrue);
    }
  });
  late AppLocalizations fr;
  late AppLocalizations en;

  setUpAll(() async {
    fr = await AppLocalizations.delegate.load(const Locale('fr'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('les libellés français sont ceux attendus, dans l’ordre', () {
    expect(NavDestinations.all.map((d) => d.label(fr)).toList(), [
      'Messages',
      'Appels',
      'Contacts',
      'Réglages',
      'Rechercher',
    ]);
  });

  test('les libellés sont bien traduits en anglais', () {
    expect(NavDestinations.all.map((d) => d.label(en)).toList(), [
      'Messages',
      'Calls',
      'Contacts',
      'Settings',
      'Search',
    ]);
  });

  test('chaque destination porte un SF Symbol et son pendant Cupertino', () {
    for (final d in NavDestinations.all) {
      expect(d.sfSymbol, isNotEmpty, reason: '${d.subPath} sans SF Symbol');
      expect(
        d.selectedSfSymbol,
        isNotEmpty,
        reason: '${d.subPath} sans SF Symbol sélectionné',
      );
    }
  });

  test('les icônes Apple correspondent au rôle de chaque onglet', () {
    // Vérifié explicitement : rien dans le typage n'empêche de laisser l'icône
    // d'un onglet renommé — c'est exactement le défaut qu'on veut attraper.
    final byPath = {for (final d in NavDestinations.all) d.subPath: d};

    expect(byPath['calls']!.cupertinoIcon, CupertinoIcons.phone);
    expect(byPath['calls']!.sfSymbol, 'phone');
    expect(byPath['settings']!.cupertinoIcon, CupertinoIcons.settings);
    expect(byPath['settings']!.sfSymbol, 'gearshape');
  });

  test('la recherche est en dernier et seule marquée isSearch', () {
    // iOS 26 la détache du groupe pour lui donner sa propre pastille : elle doit
    // rester en fin de liste, sinon la barre se réordonne toute seule.
    expect(NavDestinations.all.last.isSearch, isTrue);
    expect(NavDestinations.all.where((d) => d.isSearch), hasLength(1));
  });

  test('les index suivent la position dans l’IndexedStack', () {
    for (var i = 0; i < NavDestinations.all.length; i++) {
      expect(NavDestinations.all[i].index, i);
    }
  });
}
