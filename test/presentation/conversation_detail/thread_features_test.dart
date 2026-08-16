import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/core/utils/chat_date_formatter.dart';
import 'package:supplies_chat_app/flavors.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/conversation_detail_screen.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/reaction_bar.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/sticky_date_list.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/swipe_to_reply.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/voice_note_bubble.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/voice_recorder_bar.dart';
import 'package:supplies_chat_app/presentation/shared/fixtures/conversation_fixtures.dart';

/// Couvre les quatre comportements portés depuis l'app cliente : séparateurs de
/// jour, réponse par glissement, réactions à l'appui long, note vocale.
void main() {
  setUpAll(() {
    FlavorConfig.flavor = Flavor.development;
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPlatformProvider.overrideWithValue(AppPlatform.ios)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: ConversationDetailScreen(conversationId: 'c1'),
        ),
      ),
    );
    await tester.pump();
  }

  group('séparateurs de jour', () {
    test('les fixtures couvrent deux jours', () {
      final days = ConversationFixtures.datedThread
          .map((m) => ChatDateFormatter.dayKey(m.sentAt!))
          .toSet();
      expect(
        days,
        hasLength(2),
        reason: 'sans deux jours, aucun séparateur ne se voit',
      );
    });

    test('les horodatages sont relatifs à maintenant', () {
      // Des dates figées finiraient par afficher une date pleine au lieu
      // d'« Aujourd'hui », et l'écran perdrait ce qu'il est censé montrer.
      final labels = ConversationFixtures.datedThread
          .map((m) => ChatDateFormatter.dayLabel(m.sentAt!))
          .toSet();
      expect(labels, contains("Aujourd'hui"));
      expect(labels, contains('Hier'));
    });

    testWidgets('le fil affiche ses pilules de date', (tester) async {
      await pump(tester);
      expect(find.byType(StickyDateList), findsOneWidget);
      // Une seule pilule est montée au repos : la liste ne construit que son
      // viewport, et le séparateur du jour précédent est hors écran.
      expect(find.byType(DatePill), findsAtLeastNWidgets(1));
    });
  });

  testWidgets('chaque bulle porte le glisser-pour-répondre', (tester) async {
    await pump(tester);
    expect(find.byType(SwipeToReply), findsAtLeast(3));
  });

  testWidgets('une note vocale est rendue avec sa forme d’onde', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byType(VoiceNoteBubble), findsOneWidget);
  });

  testWidgets('le micro bascule le composer en enregistrement', (tester) async {
    await pump(tester);

    expect(find.byType(VoiceRecorderBar), findsNothing);
    await tester.tap(find.byIcon(CupertinoIcons.mic));
    await tester.pump();

    expect(
      find.byType(VoiceRecorderBar),
      findsOneWidget,
      reason: 'le composer doit céder la place à la barre d’enregistrement',
    );
  });

  testWidgets('l’appui long ouvre réactions et actions dans un seul panneau', (
    tester,
  ) async {
    await pump(tester);

    await tester.longPress(find.byType(VoiceNoteBubble));
    await tester.pumpAndSettle();

    // Les deux dans le même panneau : c'est le point de la correction. Deux
    // gestes d'appui long concurrents sur la même bulle laissaient le menu
    // natif l'emporter, et les réactions restaient inatteignables.
    expect(find.byType(ReactionBar), findsOneWidget);
    expect(find.text('Répondre'), findsOneWidget);
    expect(find.text('Copier'), findsOneWidget);
  });
}
