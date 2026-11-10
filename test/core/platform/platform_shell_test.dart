import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/message_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/pinned_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/core/providers/realtime/realtime_provider.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_list_entry.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/conversation_detail_screen.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/impl/cupertino_platform_ui.dart';
import 'package:supplies_chat_app/core/platform/impl/desktop_platform_ui.dart';
import 'package:supplies_chat_app/core/platform/impl/material_platform_ui.dart';
import 'package:supplies_chat_app/core/platform/platform_ui.dart';
import 'package:supplies_chat_app/core/responsive/breakpoints.dart';
import 'package:supplies_chat_app/presentation/desktop/desktop_workspace_shell.dart';
import 'package:supplies_chat_app/presentation/desktop/widgets/contact_profile_panel.dart';
import 'package:supplies_chat_app/presentation/desktop/widgets/conversation_list_panel.dart';
import 'package:supplies_chat_app/presentation/desktop/widgets/workspace_icon_rail.dart';
import 'package:supplies_chat_app/presentation/desktop/widgets/workspace_sidebar.dart';
import 'package:supplies_chat_app/presentation/main/widgets/custom_bottom_nav_bar.dart';
import 'package:supplies_chat_app/presentation/main/widgets/custom_nav_rail.dart';

import '../../helpers/test_environment.dart';

class _ShellQueue extends SupportQueue {
  @override
  Future<List<ConversationListEntry>> build() async => [
    ConversationListEntry(
      conversationId: 'shell-conversation',
      title: 'Compte de test',
      preview: 'Un échange réel',
      date: DateTime.utc(2026, 11, 10),
    ),
  ];
}

class _ShellPins extends PinnedConversations {
  @override
  Set<String> build() => {};
}

class _ShellThread extends Thread {
  @override
  Future<ThreadState> build(String conversationId) async =>
      const ThreadMessages([]);
  @override
  Future<void> markRead() async {}
}

/// Vérifie que chaque plateforme rend bien *sa* navigation, et que les deux axes
/// (plateforme et largeur) sont respectés simultanément.
///
/// Tout tourne sur la machine de développement : c'est possible parce que
/// l'implémentation est choisie explicitement, sans lire `dart:io`. C'est
/// exactement ce que `PlatformInfo` du package ne permettrait pas.
void main() {
  // La barre latérale affiche le nom de l'app, tiré du flavor. Sans cette
  // initialisation, `FlavorConfig.flavor` étant `late final`, le rendu échoue —
  // c'est `bootstrap()` qui s'en charge dans l'app.
  setUpAll(setUpTestEnvironment);

  const destinations = [
    PlatformDestination(
      icon: Iconsax.message,
      selectedIcon: Iconsax.message5,
      sfSymbol: 'message',
      selectedSfSymbol: 'message.fill',
      label: 'Conversations',
    ),
    PlatformDestination(
      icon: Iconsax.receipt_item,
      selectedIcon: Iconsax.receipt_item5,
      sfSymbol: 'shippingbox',
      label: 'Demandes',
    ),
    PlatformDestination(
      icon: Iconsax.user,
      selectedIcon: Iconsax.user_tag,
      sfSymbol: 'person.crop.circle',
      label: 'Profil',
    ),
  ];

  /// Monte la coquille d'une implémentation à une largeur donnée.
  Future<void> pumpShell(
    WidgetTester tester, {
    required PlatformUi ui,
    required double width,
    int selectedIndex = 0,
    ValueChanged<int>? onSelected,
    bool selectConversation = false,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final layout = PlatformLayout.of(platform: ui.platform, width: width);

    final child = Builder(
      builder: (context) => ui.shell.buildShell(
        layout: layout,
        body: const Center(child: Text('contenu')),
        destinations: destinations,
        selectedIndex: selectedIndex,
        onSelected: onSelected ?? (_) {},
      ),
    );

    // Les deux jeux de traductions sont fournis, y compris à l'hôte Cupertino.
    //
    // Ce n'est pas de la précaution : `adaptive_platform_ui` choisit son rendu sur
    // `dart:io`, pas sur notre abstraction. Un test qui tourne sur macOS voit donc
    // `PlatformInfo.isIOS == false`, et sa coquille rend des widgets **Material**
    // — lesquels exigent `MaterialLocalizations`. C'est aussi ce que le README du
    // package demande de brancher en production.
    const delegates = AppLocalizations.localizationsDelegates;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPlatformProvider.overrideWithValue(ui.platform),
          supportQueueProvider.overrideWith(_ShellQueue.new),
          pinnedConversationsProvider.overrideWith(_ShellPins.new),
          threadProvider('shell-conversation').overrideWith(_ShellThread.new),
          typingUsersProvider(
            'shell-conversation',
          ).overrideWith((ref) => Stream.value({})),
          conversationPresenceProvider(
            'shell-conversation',
          ).overrideWith((ref) => Stream.value({})),
        ],
        child: ui.platform == AppPlatform.ios
            ? CupertinoApp(
                localizationsDelegates: delegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('fr'),
                home: child,
              )
            : MaterialApp(
                localizationsDelegates: delegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('fr'),
                home: child,
              ),
      ),
    );
    await tester.pump();
    await tester.pump();
    if (selectConversation) {
      // Desktop opens a thread only after intentional selection, so layout
      // assertions exercise the same path as an agent using the real inbox.
      expect(find.byType(ConversationDetailScreen), findsNothing);
      await tester.tap(find.text('Compte de test'));
      await tester.pump();
      await tester.pump();
      expect(
        tester
            .widget<ConversationDetailScreen>(
              find.byType(ConversationDetailScreen),
            )
            .conversationId,
        'shell-conversation',
      );
    }
  }

  group('Android — Material', () {
    const ui = MaterialPlatformUi();

    testWidgets('barre du bas en format compact', (tester) async {
      await pumpShell(tester, ui: ui, width: 400);

      expect(find.byType(CustomBottomAppBar), findsOneWidget);
      expect(find.byType(CustomNavRail), findsNothing);
      // Jamais de widget iOS sur Android.
      expect(find.byType(AdaptiveScaffold), findsNothing);
    });

    testWidgets('rail au-delà de 900 px, et il est étendu', (tester) async {
      await pumpShell(tester, ui: ui, width: 1200);

      expect(find.byType(CustomNavRail), findsOneWidget);
      expect(find.byType(CustomBottomAppBar), findsNothing);
      expect(
        tester.widget<CustomNavRail>(find.byType(CustomNavRail)).extended,
        isTrue,
      );
    });
  });

  group('iOS — Cupertino', () {
    const ui = CupertinoPlatformUi();

    testWidgets('tab bar du package en format compact', (tester) async {
      await pumpShell(tester, ui: ui, width: 400);

      // La coquille du package est montée : c'est elle qui délègue à UIKit sur
      // iOS 26+. On ne teste pas le rendu natif (impossible hors appareil), mais
      // bien que le bon chemin de code soit pris.
      expect(find.byType(AdaptiveScaffold), findsOneWidget);
      // Surtout : aucune barre Material ne doit apparaître sur iOS.
      expect(find.byType(CustomBottomAppBar), findsNothing);
    });

    testWidgets('rail sur iPad large, pas une tab bar étirée', (tester) async {
      await pumpShell(tester, ui: ui, width: 1100);

      // Une tab bar d'iPhone étirée sur 1 100 px est un défaut d'interface :
      // au-delà du format compact, iPadOS attend un rail.
      expect(find.byType(CustomNavRail), findsOneWidget);
      expect(find.byType(AdaptiveScaffold), findsNothing);
    });
  });

  group('Desktop — espace de travail à colonnes', () {
    const ui = DesktopPlatformUi(AppPlatform.macos);

    testWidgets('rend l\'espace de travail, pas la coquille à onglets', (
      tester,
    ) async {
      await pumpShell(tester, ui: ui, width: 1400);

      // Le desktop a sa propre disposition : liste et conversation visibles
      // ensemble. Ni tab bar iOS, ni barre du bas Material.
      expect(find.byType(DesktopWorkspaceShell), findsOneWidget);
      expect(find.byType(AdaptiveScaffold), findsNothing);
      expect(find.byType(CustomBottomAppBar), findsNothing);
    });

    testWidgets('les cinq colonnes sont présentes sur un grand écran', (
      tester,
    ) async {
      await pumpShell(tester, ui: ui, width: 1600, selectConversation: true);

      expect(find.byType(WorkspaceIconRail), findsOneWidget);
      expect(find.byType(WorkspaceSidebar), findsOneWidget);
      expect(find.byType(ConversationListPanel), findsOneWidget);
      expect(find.byType(ConversationDetailScreen), findsOneWidget);
      expect(find.byType(ContactProfilePanel), findsOneWidget);
    });

    testWidgets('le repli retire le profil avant la liste', (tester) async {
      // 1200 px : sous le seuil du profil (1360) mais au-dessus de celui de la
      // barre latérale (1080). C'est la consultation qui cède, pas le travail.
      await pumpShell(tester, ui: ui, width: 1200, selectConversation: true);

      expect(find.byType(ContactProfilePanel), findsNothing);
      expect(find.byType(ConversationListPanel), findsOneWidget);
      expect(find.byType(ConversationDetailScreen), findsOneWidget);
    });

    testWidgets('à 1000 px, la barre latérale cède mais liste et fil restent', (
      tester,
    ) async {
      await pumpShell(tester, ui: ui, width: 1000, selectConversation: true);

      expect(find.byType(WorkspaceSidebar), findsNothing);
      expect(find.byType(ConversationListPanel), findsOneWidget);
      expect(find.byType(ConversationDetailScreen), findsOneWidget);
      // Le rail d'icônes ne disparaît jamais : c'est la navigation de premier
      // niveau.
      expect(find.byType(WorkspaceIconRail), findsOneWidget);
    });

    testWidgets('fenêtre rétrécie sous 600 px : retour à la barre du bas', (
      tester,
    ) async {
      // Une fenêtre desktop étroite doit se comporter comme un mobile — c'est
      // pour cela que la bascule lit la largeur et non la plateforme.
      await pumpShell(tester, ui: ui, width: 480);

      expect(find.byType(CustomBottomAppBar), findsOneWidget);
      expect(find.byType(CustomNavRail), findsNothing);
    });

    testWidgets('hérite du rendu Material sans être iOS', (tester) async {
      expect(ui.platform, AppPlatform.macos);
      expect(ui.platform.isDesktop, isTrue);
      expect(ui.shell, isA<MaterialShell>());
    });
  });

  group('les trois plateformes divergent réellement', () {
    testWidgets('à largeur égale, les coquilles ne sont pas identiques', (
      tester,
    ) async {
      // Le test qui protège de la régression la plus probable : une abstraction
      // qui compile mais qui rendrait la même chose partout.
      await pumpShell(tester, ui: const MaterialPlatformUi(), width: 400);
      expect(find.byType(CustomBottomAppBar), findsOneWidget);

      await pumpShell(tester, ui: const CupertinoPlatformUi(), width: 400);
      expect(find.byType(CustomBottomAppBar), findsNothing);
      expect(find.byType(AdaptiveScaffold), findsOneWidget);
    });
  });

  group('PlatformLayout', () {
    test('croise les deux axes', () {
      const iphone = PlatformLayout(
        platform: AppPlatform.ios,
        formFactor: FormFactor.compact,
      );
      const ipad = PlatformLayout(
        platform: AppPlatform.ios,
        formFactor: FormFactor.expanded,
      );

      // Même plateforme, décisions opposées : c'est tout l'intérêt de porter les
      // deux axes ensemble.
      expect(iphone.usesLateralNavigation, isFalse);
      expect(ipad.usesLateralNavigation, isTrue);
    });

    test('se construit depuis une largeur', () {
      final layout = PlatformLayout.of(
        platform: AppPlatform.windows,
        width: 1000,
      );
      expect(layout.formFactor, FormFactor.expanded);
      expect(layout.isExpanded, isTrue);
    });
  });
}
