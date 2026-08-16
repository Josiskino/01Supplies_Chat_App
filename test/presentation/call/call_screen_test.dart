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

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
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
}
