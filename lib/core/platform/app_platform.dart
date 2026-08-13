import 'package:flutter/foundation.dart';

/// Les quatre plateformes cibles de l'application.
///
/// Distinct de [TargetPlatform], qui compte aussi Linux, Fuchsia et le web :
/// restreindre l'énumération rend les `switch` exhaustifs sans branche morte, et
/// force à décider explicitement du repli pour une cible non supportée.
enum AppPlatform {
  android,
  ios,
  macos,
  windows;

  /// `true` pour les deux plateformes mobiles.
  bool get isMobile => this == android || this == ios;

  /// `true` pour les deux plateformes de bureau.
  bool get isDesktop => this == macos || this == windows;

  /// `true` si l'utilisateur attend les conventions d'Apple.
  bool get isApple => this == ios || this == macos;

  /// Traduit une [TargetPlatform] de Flutter.
  ///
  /// Les cibles non supportées (Linux, Fuchsia) retombent sur [android], dont le
  /// rendu Material est le plus neutre. Un `throw` serait plus strict, mais
  /// planterait l'app d'un développeur qui lance simplement un test sur Linux.
  static AppPlatform fromTarget(TargetPlatform target) {
    return switch (target) {
      TargetPlatform.android => AppPlatform.android,
      TargetPlatform.iOS => AppPlatform.ios,
      TargetPlatform.macOS => AppPlatform.macos,
      TargetPlatform.windows => AppPlatform.windows,
      TargetPlatform.linux || TargetPlatform.fuchsia => AppPlatform.android,
    };
  }

  /// Plateforme courante d'après Flutter.
  ///
  /// Passe par [defaultTargetPlatform] et non par `dart:io` : la valeur est
  /// surchargeable via `debugDefaultTargetPlatformOverride`, ce qui permet de
  /// tester les trois rendus depuis une seule machine. C'est précisément ce que
  /// `PlatformInfo` du package `adaptive_platform_ui` ne permet pas.
  ///
  /// Un `--dart-define=FORCE_PLATFORM=<android|ios|macos|windows>` prend le pas,
  /// pour inspecter un rendu sans changer d'appareil. La constante étant résolue à
  /// la compilation, ce mécanisme n'a aucun coût quand le drapeau est absent.
  static AppPlatform get current {
    const forced = String.fromEnvironment('FORCE_PLATFORM');
    if (forced.isNotEmpty) {
      final match = AppPlatform.values.where((p) => p.name == forced);
      if (match.isNotEmpty) return match.first;
    }
    return fromTarget(defaultTargetPlatform);
  }
}
