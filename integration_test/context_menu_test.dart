import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supplies_chat_app/core/platform/platform_ui.dart';
import 'package:supplies_chat_app/core/utils/localization_helper.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/presentation/main/nav_destinations.dart';
import 'package:supplies_chat_app/presentation/pages/conversations/conversations_screen.dart';
import 'package:supplies_chat_app/presentation/pages/conversations/widgets/conversation_row.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

/// Reproduit l'appui long sur une conversation, **sur l'appareil**.
///
/// Un test unitaire ne peut pas couvrir ce cas : `adaptive_platform_ui` choisit
/// son rendu avec `dart:io`, donc sur une machine de développement il emprunte
/// toujours le chemin Android. Seul un test d'intégration exécuté sur iOS fait
/// passer le code par `CupertinoContextMenu`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Les écrans lisent la configuration au build.
    await dotenv.load(fileName: '.env.development');
  });

  const conversation = ConversationListItemData(
    id: 'c1',
    name: 'Kofi Adjei',
    preview: 'Kofi : Parfait, ça me convient. Il me faudrait…',
    timeLabel: '12:10',
    presence: PresenceStatus.online,
    hasUnread: true,
  );

  // Les delegates générés de l'app **plus** ceux de Material : les écrans lisent
  // `AppLocalizations`, et la coquille du package rend des widgets Material.
  final delegates = <LocalizationsDelegate<Object?>>[
    ...AppLocalizations.localizationsDelegates,
    DefaultMaterialLocalizations.delegate,
    DefaultCupertinoLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ];

  testWidgets('appui long dans une liste simple', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: CupertinoApp(
          localizationsDelegates: delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CupertinoPageScaffold(child: SizedBox.shrink()),
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: CupertinoApp(
          localizationsDelegates: delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CupertinoPageScaffold(
            child: ListView(
              children: [
                ConversationRow(data: conversation, onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Kofi Adjei'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'appui long dans la structure réelle : coquille + page imbriquées',
    (tester) async {
      // C'est la structure de production : `AdaptiveScaffold` de la coquille,
      // contenant un `IndexedStack`, contenant un écran qui monte lui-même un
      // second `AdaptiveScaffold` via `PlatformPage`. Le menu contextuel ouvre une
      // route sur le Navigator racine depuis ce double emboîtement.
      late final PlatformUi platformUi;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              platformUi = ref.watch(platformUiProvider);
              return CupertinoApp(
                localizationsDelegates: delegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('fr'),
                home: Builder(
                  builder: (context) => platformUi.shell.buildShell(
                    layout: PlatformLayout.of(
                      platform: platformUi.platform,
                      width: MediaQuery.sizeOf(context).width,
                    ),
                    body: const ConversationsScreen(),
                    destinations: [
                      for (final spec in NavDestinations.all)
                        PlatformDestination(
                          icon: spec.icon,
                          selectedIcon: spec.selectedIcon,
                          cupertinoIcon: spec.cupertinoIcon,
                          cupertinoSelectedIcon: spec.cupertinoSelectedIcon,
                          sfSymbol: spec.sfSymbol,
                          selectedSfSymbol: spec.selectedSfSymbol,
                          label: spec.subPath,
                        ),
                    ],
                    selectedIndex: 0,
                    onSelected: (_) {},
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Première conversation des fixtures.
      final target = find.text('Kofi Adjei');
      expect(target, findsWidgets, reason: 'la liste doit être rendue');

      await tester.longPress(target.first);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
