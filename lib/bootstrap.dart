import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/push_background_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/platform/window_glass.dart';
import 'core/services/storage_service.dart';
import 'core/providers/auth/auth_status_provider.dart';
import 'core/utils/app_logger.dart';
import 'flavors.dart';

/// `true` sur les deux cibles desktop de l'application.
bool get _isDesktop =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

/// `true` sur les cibles mobiles.
bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Résout le thème effectif avant l'affichage de la fenêtre.
///
/// Reprend la même logique que `ThemeNotifier` : préférence enregistrée, sinon
/// réglage du système. Dupliquer cette poignée de lignes est le prix à payer pour
/// connaître le thème *avant* de construire l'arbre de widgets — le provider,
/// lui, n'existe pas encore à ce stade.
Future<bool> _resolveIsDarkTheme() async {
  final saved = await StorageService.instance.getThemeMode();
  return switch (saved) {
    'dark' => true,
    'light' => false,
    // 'system' ou aucune préférence : on suit la plateforme.
    _ => PlatformDispatcher.instance.platformBrightness == Brightness.dark,
  };
}

/// Initialisation commune à tous les flavors.
Future<void> bootstrap(Flavor flavor) async {
  FlavorConfig.flavor = flavor;

  WidgetsFlutterBinding.ensureInitialized();

  AppLogger().init();

  // ── Orientation : mobile uniquement ─────────────────────────────────────
  // Verrouiller le portrait sur desktop empêcherait simplement l'app de
  // s'afficher correctement dans une fenêtre redimensionnée.
  if (_isMobile) {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // ── Fenêtre desktop ─────────────────────────────────────────────────────
  if (_isDesktop) {
    // La translucidité doit être posée avant l'affichage : appliquer le matériau
    // sur une fenêtre déjà visible produit un clignotement opaque.
    //
    // La préférence de thème est lue **ici**, avant d'appliquer le matériau. Une
    // valeur devinée poserait le verre sombre derrière une interface claire (ou
    // l'inverse) jusqu'au premier changement de thème — et les deux matériaux ne
    // se ressemblent pas du tout.
    await WindowGlass.initialize(isDark: await _resolveIsDarkTheme());

    await windowManager.ensureInitialized();

    final windowOptions = WindowOptions(
      size: const Size(1200, 800),
      // La coquille bascule sur la barre du bas sous 600 px : la borne minimale
      // laisse volontairement atteindre cette disposition, sans descendre en
      // dessous du seuil où le rail et le contenu ne coexistent plus.
      minimumSize: const Size(480, 600),
      center: true,
      // Fenêtre au fond transparent : sans cela, le matériau translucide serait
      // masqué par la couleur de fond opaque de la fenêtre, et l'effet de verre
      // n'apparaîtrait nulle part.
      backgroundColor: WindowGlass.isEnabled ? Colors.transparent : null,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setTitle(FlavorConfig.appName);
      await windowManager.show();
      await windowManager.focus();

      // La barre de titre est configurée **ici**, dans le callback et après
      // `show()`.
      //
      // Deux raisons : `window_manager` reconfigure la fenêtre à son
      // initialisation et annulerait des réglages posés avant lui ; et une trace
      // d'exécution en release a montré que `waitUntilReadyToShow` rend la main
      // *avant* d'exécuter ce callback. Placer l'appel après la boucle laissait
      // donc l'ordre au hasard du planificateur.
      await WindowGlass.applyTransparentTitleBar();
    });
  }

  // Garde en mémoire davantage d'images décodées : revenir sur une conversation
  // touche le cache au lieu de redécoder depuis le disque.
  // (défauts : 1000 entrées / 100 Mio)
  PaintingBinding.instance.imageCache.maximumSize = 2000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 250 << 20; // 250 Mio

  await dotenv.load(fileName: FlavorConfig.envFile);

  // Firebase avant tout usage de la messagerie : `FirebaseMessaging.instance`
  // lève si l'application n'est pas initialisée. Un échec n'est pas fatal — les
  // notifications système manqueront, le reste fonctionnera.
  //
  // Android et iOS seulement : le desktop n'a pas de fichier de configuration,
  // et l'initialisation y échouerait à chaque lancement.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      AppLogger().error('Firebase non initialisé', feature: 'Push', error: e);
    }
  }

  // Charge les symboles fr_FR pour `DateFormat(..., 'fr_FR')`. Sans cet appel,
  // le premier formatage lève `LocaleDataException`.
  await initializeDateFormatting('fr_FR');

  AppLogger().info(
    'Démarrage ${FlavorConfig.appName}',
    feature: 'Bootstrap',
    data: {'flavor': flavor.name, 'baseUrl': dotenv.env['BASE_URL']},
  );

  // Préconstruit les providers avant le widget tree.
  //
  // En Riverpod 3, un `ref.listen` dans un constructeur peut déclencher
  // l'initialisation d'un provider alors qu'un autre est déjà en cours de build,
  // ce qui casse une assertion du framework. Précharger ici évite ce piège — et
  // permet au routeur de connaître l'état d'auth dès le premier frame.
  final container = ProviderContainer();
  container.read(authStatusProvider);

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}
