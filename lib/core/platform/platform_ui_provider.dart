import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_platform.dart';
import 'impl/cupertino_platform_ui.dart';
import 'impl/desktop_platform_ui.dart';
import 'impl/material_platform_ui.dart';
import 'platform_ui.dart';

part 'platform_ui_provider.g.dart';

/// Plateforme courante.
///
/// Exposée comme provider — et non lue directement depuis `dart:io` — pour être
/// surchargeable :
///
/// ```dart
/// ProviderScope(
///   overrides: [appPlatformProvider.overrideWithValue(AppPlatform.ios)],
///   child: ...,
/// )
/// ```
///
/// C'est ce qui permet de vérifier les trois rendus depuis une seule machine.
/// `PlatformInfo` du package `adaptive_platform_ui` ne l'autorise pas : il lit
/// `Platform.isIOS` en statique.
@Riverpod(keepAlive: true)
AppPlatform appPlatform(Ref ref) => AppPlatform.current;

/// Implémentation d'interface correspondant à la plateforme courante.
///
/// Point d'entrée unique : aucun écran ne doit tester la plateforme lui-même.
/// Un `if (Platform.isIOS)` dans un widget est le début de la divergence
/// incontrôlée — quatre interfaces dont trois jamais testées.
@Riverpod(keepAlive: true)
PlatformUi platformUi(Ref ref) {
  final platform = ref.watch(appPlatformProvider);

  return switch (platform) {
    AppPlatform.android => const MaterialPlatformUi(),
    AppPlatform.ios => const CupertinoPlatformUi(),
    AppPlatform.macos => const DesktopPlatformUi(AppPlatform.macos),
    AppPlatform.windows => const DesktopPlatformUi(AppPlatform.windows),
  };
}
