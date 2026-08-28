import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/impl/cupertino_platform_ui.dart';
import 'package:supplies_chat_app/core/platform/impl/desktop_platform_ui.dart';
import 'package:supplies_chat_app/core/platform/impl/material_platform_ui.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';

void main() {
  group('AppPlatform.fromTarget', () {
    test('traduit les quatre cibles supportées', () {
      expect(
        AppPlatform.fromTarget(TargetPlatform.android),
        AppPlatform.android,
      );
      expect(AppPlatform.fromTarget(TargetPlatform.iOS), AppPlatform.ios);
      expect(AppPlatform.fromTarget(TargetPlatform.macOS), AppPlatform.macos);
      expect(
        AppPlatform.fromTarget(TargetPlatform.windows),
        AppPlatform.windows,
      );
    });

    test(
      'replie les cibles non supportées sur Material plutôt que de lever',
      () {
        // Un `throw` planterait un développeur qui lance simplement un test sous
        // Linux, sans rien apporter.
        expect(
          AppPlatform.fromTarget(TargetPlatform.linux),
          AppPlatform.android,
        );
        expect(
          AppPlatform.fromTarget(TargetPlatform.fuchsia),
          AppPlatform.android,
        );
      },
    );
  });

  group('catégories', () {
    test('mobile / desktop / apple', () {
      expect(AppPlatform.android.isMobile, isTrue);
      expect(AppPlatform.ios.isMobile, isTrue);
      expect(AppPlatform.macos.isDesktop, isTrue);
      expect(AppPlatform.windows.isDesktop, isTrue);

      expect(AppPlatform.ios.isApple, isTrue);
      expect(AppPlatform.macos.isApple, isTrue);
      expect(AppPlatform.android.isApple, isFalse);
      expect(AppPlatform.windows.isApple, isFalse);
    });
  });

  group('platformUiProvider', () {
    /// Résout l'implémentation pour une plateforme forcée.
    ///
    /// C'est le mécanisme qui rend les trois rendus testables depuis une seule
    /// machine — impossible avec une détection statique via `dart:io`.
    T uiFor<T>(AppPlatform platform) {
      final container = ProviderContainer(
        overrides: [appPlatformProvider.overrideWithValue(platform)],
      );
      addTearDown(container.dispose);
      return container.read(platformUiProvider) as T;
    }

    test('Android → Material', () {
      expect(uiFor(AppPlatform.android), isA<MaterialPlatformUi>());
    });

    test('iOS → Cupertino', () {
      expect(uiFor(AppPlatform.ios), isA<CupertinoPlatformUi>());
    });

    test('macOS et Windows → desktop, en conservant leur identité', () {
      final macos = uiFor<DesktopPlatformUi>(AppPlatform.macos);
      final windows = uiFor<DesktopPlatformUi>(AppPlatform.windows);

      expect(macos, isA<DesktopPlatformUi>());
      expect(windows, isA<DesktopPlatformUi>());
      // La distinction doit survivre : elle sera nécessaire dès qu'un raccourci
      // clavier ou une barre de titre divergera entre les deux.
      expect(macos.platform, AppPlatform.macos);
      expect(windows.platform, AppPlatform.windows);
    });

    test('le desktop hérite de Material mais pas de son identité', () {
      final desktop = uiFor<DesktopPlatformUi>(AppPlatform.macos);
      expect(desktop, isA<MaterialPlatformUi>());
      expect(desktop.platform, isNot(AppPlatform.android));
    });

    test('les transitions divergent par plateforme', () {
      final android = uiFor(AppPlatform.android).motion;
      final ios = uiFor(AppPlatform.ios).motion;
      final desktop = uiFor(AppPlatform.macos).motion;

      // Le desktop est le plus rapide : une navigation au clic n'a pas à jouer
      // l'animation d'un geste tactile.
      expect(
        desktop.pageTransitionDuration.inMilliseconds,
        lessThan(android.pageTransitionDuration.inMilliseconds),
      );
      expect(ios.pageTransitionDuration, isNot(android.pageTransitionDuration));
    });
  });
}
