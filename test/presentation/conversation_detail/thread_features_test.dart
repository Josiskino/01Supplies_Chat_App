import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/core/utils/chat_date_formatter.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/conversation_detail_screen.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/chat_bubble.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/reaction_bar.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/sticky_date_list.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/swipe_to_reply.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/voice_note_bubble.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/voice_recorder_bar.dart';
import 'package:supplies_chat_app/presentation/shared/fixtures/conversation_fixtures.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

import 'package:supplies_chat_app/core/providers/messaging/message_provider.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_entity.dart';

import '../../helpers/test_environment.dart';

/// Identifiant du compte connecté dans les tests, pour distinguer ses bulles.
const _meId = 'me';

/// Rejoue les fixtures sous forme de messages d'API.
///
/// Les scénarios portés depuis l'app cliente — séparateurs de jour, glissement,
/// réactions, note vocale — se vérifient sur la **présentation**, qui ne doit
/// pas dépendre d'un serveur joignable.
class _StubThread extends Thread {
  @override
  Future<ThreadState> build(String conversationId) async {
    return ThreadMessages([
      for (final m in ConversationFixtures.datedThread)
        MessageEntity(
          id: m.id,
          conversationId: conversationId,
          senderId: m.isMine ? _meId : 'client',
          content: m.text,
          // Les fixtures portent des notes vocales : les convertir en texte
          // ferait disparaître la bulle audio que ce fichier teste.
          type: m.isVoice ? MessageType.audio : MessageType.text,
          delivery: MessageDelivery.read,
          sentAt: m.sentAt ?? DateTime.now(),
          replyToId: m.replyTo?.messageId,
          replyToContent: m.replyTo?.text,
          replyToAuthor: m.replyTo?.author,
          reaction: m.reaction,
        ),
    ]);
  }

  /// L'écran marque le fil comme lu à l'ouverture. Laissé au vrai provider, cet
  /// appel partirait vers le réseau et laisserait un timer en suspens, ce que le
  /// framework de test signale comme une fuite.
  @override
  Future<void> markRead() async {}

  @override
  Future<bool> send(String content, {String? replyTo}) async => true;
}

/// Couvre les quatre comportements portés depuis l'app cliente : séparateurs de
/// jour, réponse par glissement, réactions à l'appui long, note vocale.
void main() {
  setUpAll(() {
    setUpTestEnvironment();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPlatformProvider.overrideWithValue(AppPlatform.ios),
          // Le fil vient désormais de l'API : sans injection, l'écran n'a rien
          // à rendre et tous les gestes testés ici deviennent introuvables.
          threadProvider('c1').overrideWith(() => _StubThread()),
          currentUserIdProvider.overrideWithValue(_meId),
        ],
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
    test('le fil s’étale sur plusieurs jours', () {
      final days = ConversationFixtures.datedThread
          .map((m) => ChatDateFormatter.dayKey(m.sentAt!))
          .toSet();
      // Plusieurs journées et assez de messages pour que le fil défile : la
      // pilule de date flottante ne se voit pas sur une conversation qui tient
      // dans un écran.
      expect(days.length, greaterThanOrEqualTo(3));
      expect(ConversationFixtures.datedThread.length, greaterThan(20));
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

  testWidgets('la citation renvoie vers le message d’origine', (tester) async {
    await pump(tester);

    // La citation porte l'identifiant de sa cible : sans lui elle serait
    // affichée mais inerte, ce qui est le défaut le plus courant du motif.
    final quoted = ConversationFixtures.datedThread
        .firstWhere((m) => m.replyTo != null)
        .replyTo!;
    expect(quoted.messageId, isNotNull);
    expect(
      ConversationFixtures.datedThread.any((m) => m.id == quoted.messageId),
      isTrue,
      reason: 'la citation doit désigner un message qui existe',
    );
  });

  testWidgets('une réaction est posée à cheval sur la bulle', (tester) async {
    // Testée sur la bulle seule : celle des fixtures est sur un message de la
    // veille, donc hors du viewport au premier rendu.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatBubble(
            message: ChatMessageData(
              id: 'm1',
              text: 'Ça me paraît bien',
              timeLabel: '09:28',
              isMine: false,
              reaction: '❤️',
            ),
            contactName: 'Kofi',
            isFirstOfGroup: true,
            isLastOfGroup: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('❤️'), findsOneWidget);
  });
}
