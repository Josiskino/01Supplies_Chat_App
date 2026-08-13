import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/locale/locale_provider.dart';
import 'config/router/app_router.dart';
import 'config/theme/cupertino_theme.dart';
import 'config/theme/theme.dart';
import 'core/utils/localization_helper.dart';
import 'flavors.dart';

/// Racine de l'application.
///
/// `AdaptiveApp.router` remplace `MaterialApp.router` : il monte un `MaterialApp`
/// sur Android et desktop, un `CupertinoApp` sur iOS. Les deux jeux de thèmes sont
/// fournis en parallèle — c'est ce qui permet un vrai rendu iOS sans dupliquer
/// l'arbre de widgets.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    // C'est ici que viendront s'ancrer les services à durée de vie applicative
    // de la messagerie (canal temps réel, notifications). Ils doivent être
    // observés à la racine, toujours montée : les rattacher à un écran les
    // rendrait dépendants de son affichage — l'app cliente a déjà payé ce bug
    // avec une connexion temps réel qui ne s'ouvrait qu'une fois l'accueil visité.

    return AdaptiveApp.router(
      title: FlavorConfig.appName,
      routerConfig: router,
      themeMode: themeMode,
      materialLightTheme: TAppTheme.lightThemeData(context),
      materialDarkTheme: TAppTheme.darkThemeData(context),
      cupertinoLightTheme: TCupertinoTheme.lightTheme,
      cupertinoDarkTheme: TCupertinoTheme.darkTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // `AdaptiveApp` n'expose pas `debugShowCheckedModeBanner` : on le retire
      // via la configuration Material sous-jacente.
      material: (context, platform) =>
          const MaterialAppData(debugShowCheckedModeBanner: false),
      cupertino: (context, platform) =>
          const CupertinoAppData(debugShowCheckedModeBanner: false),
    );
  }
}
