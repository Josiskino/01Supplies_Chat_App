import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/locale/locale_provider.dart';
import 'config/router/app_router.dart';
import 'core/providers/realtime/push_provider.dart';
import 'core/providers/realtime/realtime_provider.dart';
import 'presentation/widgets/common/incoming_message_listener.dart';
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
    // Instancié ici pour qu'il existe dès le lancement : le service s'abonne au
    // canal de l'utilisateur dès qu'une session s'ouvre, et rien ne l'observe
    // par ailleurs. Sans cette lecture, aucun événement n'arriverait jamais.
    ref.watch(messageEventsProvider);
    // Enregistre l'appareil auprès du backend dès qu'une session s'ouvre.
    ref.watch(pushRegistrationProvider);

    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

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
      // L'écouteur enveloppe **toutes** les pages : un message peut arriver
      // pendant qu'on consulte les réglages, et c'est là qu'il faut le
      // signaler. Rattaché à un écran, il ne verrait rien le reste du temps.
      builder: (context, child) =>
          MessagingApplicationLayer(child: child ?? const SizedBox.shrink()),
      material: (context, platform) => const MaterialAppData(
        debugShowCheckedModeBanner: false,
        restorationScopeId: '01chat-app',
      ),
      cupertino: (context, platform) => const CupertinoAppData(
        debugShowCheckedModeBanner: false,
        restorationScopeId: '01chat-app',
      ),
    );
  }
}
