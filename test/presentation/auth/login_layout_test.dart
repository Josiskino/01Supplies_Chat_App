import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/presentation/pages/auth/login_screen.dart';
import 'package:supplies_chat_app/presentation/pages/auth/widgets/auth_glass_card.dart';
import 'package:supplies_chat_app/flavors.dart';

import '../../helpers/test_environment.dart';

/// Vérifie que l'écran de connexion bascule sur la **largeur disponible**, et
/// non sur la plateforme.
///
/// C'est le point le plus facile à casser du jour où quelqu'un ajoutera un
/// `Platform.isMacOS` ici : le test tourne sur une seule machine et couvre
/// pourtant les deux dispositions.
void main() {
  setUpAll(() {
    setUpTestEnvironment();
  });

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('au-dessus de 900 px, la marque apparaît en colonne de gauche', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1280, 900));

    expect(find.text('Messagerie interne logistique'), findsOneWidget);
    // Le nom de l'app est porté par le panneau de marque, pas répété en pied de
    // formulaire.
    expect(find.text(FlavorConfig.appName), findsOneWidget);
  });

  testWidgets('en dessous de 900 px, la disposition retombe sur une colonne', (
    tester,
  ) async {
    await pumpAt(tester, const Size(390, 844));

    // Pas de panneau de marque : la carte n'a pas la largeur pour deux colonnes.
    expect(find.text('Messagerie interne logistique'), findsNothing);
    // Le flavor reprend sa place en pied de formulaire.
    expect(find.text(FlavorConfig.appName), findsOneWidget);
  });

  testWidgets('le formulaire est présent dans les deux dispositions', (
    tester,
  ) async {
    for (final size in [const Size(1280, 900), const Size(390, 844)]) {
      await pumpAt(tester, size);
      expect(find.text('SE CONNECTER'), findsOneWidget, reason: '$size');
      expect(find.text('Rester connecté'), findsOneWidget, reason: '$size');
      expect(find.byType(TextField), findsNWidgets(2), reason: '$size');
    }
  });

  testWidgets('la carte est centrée dans la fenêtre, aux deux dispositions', (
    tester,
  ) async {
    // Vérifié par la mesure et non à l'œil : le padding vertical du défilement
    // ajoute `WindowGlass.titleBarInset` sur macOS, et une asymétrie s'y
    // glisserait sans se voir sur une capture.
    for (final size in [const Size(1280, 900), const Size(390, 844)]) {
      await pumpAt(tester, size);

      final card = tester.getRect(find.byType(AuthGlassCard));
      final screen = tester.getRect(find.byType(Scaffold));

      expect(
        card.center.dx,
        moreOrLessEquals(screen.center.dx, epsilon: 0.5),
        reason: 'décentrage horizontal à $size',
      );
      expect(
        card.center.dy,
        moreOrLessEquals(screen.center.dy, epsilon: 0.5),
        reason: 'décentrage vertical à $size',
      );
    }
  });
}
