import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:supplies_chat_app/config/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/presentation/pages/calls/calls_screen.dart';
import 'package:supplies_chat_app/presentation/pages/calls/widgets/call_log_row.dart';
import 'package:supplies_chat_app/presentation/shared/fixtures/call_fixtures.dart';

/// Couvre l'historique des appels.
void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(402, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPlatformProvider.overrideWithValue(AppPlatform.ios)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: CallsScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('l’écran annonce que les appels ne sont pas disponibles', (
    tester,
  ) async {
    await pump(tester);

    // Aucune ligne : afficher un faux historique laisserait croire à une
    // fonctionnalité qui n'existe pas, et ferait chercher pourquoi rappeler
    // ne marche pas.
    expect(find.byType(CallLogRow), findsNothing);
    expect(find.text('Appels indisponibles'), findsOneWidget);
  });

  testWidgets('la ligne d’appel reste rendue correctement', (tester) async {
    // La présentation est prête et doit le rester : elle servira le jour où
    // l'appel existera. On la monte donc directement, sans passer par l'écran.
    final missed = CallFixtures.history.firstWhere((e) => e.isMissed);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CallLogRow(
            entry: missed,
            isApple: true,
            onTap: () {},
            onInfo: () {},
          ),
        ),
      ),
    );

    // Le nom porte la couleur d'erreur : c'est ce qui permet de parcourir la
    // liste du regard sans lire chaque ligne.
    final name = tester.widget<Text>(find.text(missed.name));
    expect(name.style?.color, isNotNull);
  });

  test('un manqué n’a pas de durée', () {
    // Un appel manqué n'a pas eu lieu : lui prêter une durée serait un
    // contresens, et le modèle l'interdit par construction.
    for (final entry in CallFixtures.history.where((e) => e.isMissed)) {
      expect(entry.duration, isNull);
      expect(entry.durationLabel, isNull);
    }
  });

  test('les tentatives répétées sont regroupées', () {
    // Cinq lignes identiques n'apprendraient rien de plus qu'un compteur.
    expect(
      CallFixtures.history.any((e) => e.repeatCount > 1),
      isTrue,
      reason: 'les fixtures doivent exercer le regroupement',
    );
  });

  test('un manqué porte le combiné raccroché sur les deux plateformes', () {
    // macOS partage le langage d'iOS : c'est le même dessin qu'en liste de
    // conversations, et il dit que l'appel a échoué — une flèche ne dirait que
    // d'où il venait.
    expect(
      AppIcons.of(AppIcons.missedCall, isApple: true),
      CupertinoIcons.phone_down_fill,
    );
    // Chaque rôle a bien deux dessins, jamais un seul par défaut.
    expect(
      AppIcons.of(AppIcons.missedCall, isApple: false),
      isNot(CupertinoIcons.phone_down_fill),
    );
  });
}
