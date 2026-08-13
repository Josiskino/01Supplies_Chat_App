import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/locale/locale_provider.dart';
import 'config/router/app_router.dart';
import 'config/theme/theme.dart';
import 'core/utils/localization_helper.dart';
import 'flavors.dart';

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

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: FlavorConfig.appName,
      theme: TAppTheme.lightThemeData(context),
      darkTheme: TAppTheme.darkThemeData(context),
      themeMode: themeMode,
      locale: locale,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
