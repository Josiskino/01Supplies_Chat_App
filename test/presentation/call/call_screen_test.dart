import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/presentation/pages/call/call_screen.dart';
import 'package:supplies_chat_app/presentation/pages/call/widgets/call_backdrop.dart';
import 'package:supplies_chat_app/presentation/pages/call/widgets/call_controls_bar.dart';
import 'package:supplies_chat_app/presentation/pages/call/widgets/call_participant_tile.dart';
import 'package:supplies_chat_app/presentation/shared/fixtures/call_fixtures.dart';

/// Couvre l'écran d'appel de groupe.
void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: CallScreen(title: 'Tournée du matin')),
      ),
    );
    await tester.pump();

    // Démontage explicite en fin de test : le halo de parole et le minuteur
    // tournent en boucle, et un arbre laissé monté fait échouer le test sur des
    // rappels et des minuteurs encore en vol.
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
  }

  testWidgets('le sujet de l’appel vient de l’appelant', (tester) async {
    await pump(tester);
    expect(find.text('Tournée du matin'), findsOneWidget);
  });

  testWidgets('chaque participant a sa pastille', (tester) async {
    await pump(tester);

    final session = CallFixtures.session();
    expect(
      find.byType(CallParticipantTile),
      findsNWidgets(session.participants.length),
    );
    // L'utilisateur courant est nommé « Vous », pas par son identifiant.
    expect(find.text('Vous'), findsOneWidget);
    expect(find.text('@awa'), findsOneWidget);
  });

  testWidgets('les places libres invitent', (tester) async {
    await pump(tester);
    expect(
      find.byType(CallInviteSlot),
      findsNWidgets(CallFixtures.session().freeSlots),
    );
  });

  testWidgets('couper le micro change le libellé du contrôle', (tester) async {
    await pump(tester);

    expect(find.text('Couper'), findsOneWidget);
    await tester.tap(find.text('Couper'));
    await tester.pump();

    // Un contrôle doit annoncer ce qu'il fera, pas l'état où il se trouve.
    expect(find.text('Activer'), findsOneWidget);
  });

  testWidgets('une réaction traverse l’écran puis disparaît', (tester) async {
    await pump(tester);

    await tester.tap(find.text('🔥'));
    await tester.pump();
    // Deux exemplaires : celui de la barre et celui qui s'envole.
    expect(find.text('🔥'), findsNWidgets(2));

    // Pas de `pumpAndSettle` : le halo de parole ne s'arrête jamais, et
    // l'attente ne rendrait pas la main.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.text('🔥'),
      findsOneWidget,
      reason: 'la réaction est un événement, elle ne doit pas rester affichée',
    );
  });

  testWidgets('le raccroché est distinct des autres contrôles', (tester) async {
    await pump(tester);
    // Seule action irréversible de l'écran : elle a son propre libellé et son
    // propre traitement visuel.
    expect(find.text('Raccrocher'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.phone_down_fill), findsOneWidget);
    expect(find.byType(CallControlsBar), findsOneWidget);
  });

  testWidgets('le fond ne se retire pas la palette à chaque seconde', (
    tester,
  ) async {
    await pump(tester);

    CallBackdrop backdrop() =>
        tester.widget<CallBackdrop>(find.byType(CallBackdrop));
    final first = backdrop().seed;

    // Le minuteur reconstruit l'écran chaque seconde : si la graine était
    // calculée dans `build`, le fond changerait de couleur en continu.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(backdrop().seed, first);
  });

  test('chaque palette tient quatre teintes', () {
    // Moins de quatre laisse des coins noirs ; l'aléa ne porte que sur les
    // positions, jamais sur les couleurs elles-mêmes.
    for (final palette in CallBackdrop.debugPalettes) {
      expect(palette, hasLength(4));
    }
  });

  testWidgets('la parole tourne d’un participant à l’autre', (tester) async {
    await pump(tester);

    List<String> speakers() => tester
        .widgetList<CallParticipantTile>(find.byType(CallParticipantTile))
        .where((t) => t.participant.isSpeaking)
        .map((t) => t.participant.id)
        .toList();

    final first = speakers();
    expect(first, hasLength(1), reason: 'une seule voix à la fois');

    await tester.pump(const Duration(milliseconds: 3700));
    expect(
      speakers(),
      isNot(first),
      reason: 'sans rotation, le halo resterait figé sur le même avatar',
    );
  });

  testWidgets('un micro coupé ne prend jamais la parole', (tester) async {
    await pump(tester);

    // Quatre tours suffisent à passer tout le monde.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 3700));
      final speaking = tester
          .widgetList<CallParticipantTile>(find.byType(CallParticipantTile))
          .where((t) => t.participant.isSpeaking);
      for (final tile in speaking) {
        expect(
          tile.participant.isMuted,
          isFalse,
          reason: 'un participant muet qui parle est un contresens',
        );
      }
    }
  });

  testWidgets('l’appui long arme le retrait', (tester) async {
    await pump(tester);

    bool editing() => tester
        .widgetList<CallParticipantTile>(find.byType(CallParticipantTile))
        .any((t) => t.isEditing);

    expect(editing(), isFalse);
    await tester.longPress(find.text('@awa'));
    await tester.pump();
    expect(editing(), isTrue);
  });

  testWidgets('la caméra fait apparaître la vignette', (tester) async {
    await pump(tester);

    expect(find.byIcon(CupertinoIcons.arrow_2_squarepath), findsNothing);
    await tester.tap(find.text('Caméra'));
    await tester.pump();

    // Le repère d'échange de plans signale que la vignette est cliquable.
    expect(find.byIcon(CupertinoIcons.arrow_2_squarepath), findsOneWidget);
  });
}
