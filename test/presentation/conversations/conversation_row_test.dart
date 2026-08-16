import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/presentation/pages/conversations/widgets/conversation_row.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

/// Vérifie que la ligne de conversation adopte bien la présentation de sa
/// plateforme, et que son menu contextuel est celui du système.
void main() {
  const conversation = ConversationListItemData(
    id: 'c1',
    name: 'Kofi Adjei',
    preview: 'Kofi : Parfait, ça me convient.',
    timeLabel: '12:10',
    presence: PresenceStatus.online,
    hasUnread: true,
  );

  const delegates = <LocalizationsDelegate<Object?>>[
    DefaultMaterialLocalizations.delegate,
    DefaultCupertinoLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ];

  Future<void> pumpRow(
    WidgetTester tester, {
    required AppPlatform platform,
  }) async {
    final row = ConversationRow(data: conversation, onTap: () {});
    final isIos = platform == AppPlatform.ios;

    await tester.pumpWidget(
      ProviderScope(
        // C'est ce qui rend les deux rendus testables depuis une seule machine.
        overrides: [appPlatformProvider.overrideWithValue(platform)],
        child: isIos
            ? CupertinoApp(localizationsDelegates: delegates, home: row)
            : MaterialApp(localizationsDelegates: delegates, home: row),
      ),
    );
    await tester.pump();
  }

  group('rendu par plateforme', () {
    testWidgets('iOS affiche le chevron de navigation', (tester) async {
      await pumpRow(tester, platform: AppPlatform.ios);

      expect(find.text('Kofi Adjei'), findsOneWidget);
      // Le chevron est le marqueur visuel d'une ligne de liste iOS ; Material ne
      // l'utilise pas.
      expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget);
    });

    testWidgets('Android n\'affiche pas de chevron', (tester) async {
      await pumpRow(tester, platform: AppPlatform.android);

      expect(find.text('Kofi Adjei'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_right), findsNothing);
    });

    testWidgets('iOS enveloppe la ligne du menu contextuel du système', (
      tester,
    ) async {
      await pumpRow(tester, platform: AppPlatform.ios);

      // Le menu iOS vient du package : appui long, flou d'arrière-plan et aperçu
      // agrandi. On vérifie que le bon chemin de code est pris, pas le rendu
      // natif — impossible à observer hors appareil.
      expect(find.byType(AdaptiveContextMenu), findsOneWidget);
    });

    testWidgets('Android n\'utilise pas le menu iOS', (tester) async {
      await pumpRow(tester, platform: AppPlatform.android);

      expect(find.byType(AdaptiveContextMenu), findsNothing);
      // Le menu Material est ouvert par `showMenu` au long press : il n'existe
      // pas dans l'arbre avant le geste.
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });

  group('contenu', () {
    testWidgets(
      'l\'aperçu et l\'heure sont affichés sur les deux plateformes',
      (tester) async {
        for (final platform in [AppPlatform.ios, AppPlatform.android]) {
          await pumpRow(tester, platform: platform);
          expect(
            find.text('Kofi : Parfait, ça me convient.'),
            findsOneWidget,
            reason: 'plateforme=$platform',
          );
          expect(
            find.text('12:10'),
            findsOneWidget,
            reason: 'plateforme=$platform',
          );
        }
      },
    );
  });

  group('appui long — reproduction du plantage iOS', () {
    testWidgets('le menu contextuel s\'ouvre sans casser la mise en page', (
      tester,
    ) async {
      // La ligne est montée dans une liste, comme en production : c'est en la
      // sortant de ce contexte que `CupertinoContextMenu` lui retire ses
      // contraintes de largeur.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appPlatformProvider.overrideWithValue(AppPlatform.ios)],
          child: CupertinoApp(
            localizationsDelegates: delegates,
            home: ListView(
              children: [ConversationRow(data: conversation, onTap: () {})],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.longPress(find.text('Kofi Adjei'));
      await tester.pumpAndSettle();

      // Aucune exception de rendu ne doit avoir été levée pendant l'ouverture.
      expect(tester.takeException(), isNull);
    });
  });
}
