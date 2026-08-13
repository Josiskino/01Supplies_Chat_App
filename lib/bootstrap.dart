import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/providers/auth/auth_status_provider.dart';
import 'core/utils/app_logger.dart';
import 'flavors.dart';

/// `true` sur les deux cibles desktop de l'application.
bool get _isDesktop =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

/// `true` sur les cibles mobiles.
bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

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
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      // La coquille bascule sur la barre du bas sous 600 px : la borne minimale
      // laisse volontairement atteindre cette disposition, sans descendre en
      // dessous du seuil où le rail et le contenu ne coexistent plus.
      minimumSize: Size(480, 600),
      center: true,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setTitle(FlavorConfig.appName);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Garde en mémoire davantage d'images décodées : revenir sur une conversation
  // touche le cache au lieu de redécoder depuis le disque.
  // (défauts : 1000 entrées / 100 Mio)
  PaintingBinding.instance.imageCache.maximumSize = 2000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 250 << 20; // 250 Mio

  await dotenv.load(fileName: FlavorConfig.envFile);

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

  runApp(
    UncontrolledProviderScope(container: container, child: const MyApp()),
  );
}
