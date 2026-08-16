import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/presentation/pages/conversations/widgets/pinned_strip_header.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

/// Vérifie le repli de la bande d'épinglés.
///
/// Le comportement est piloté par la position de défilement, donc entièrement
/// déterministe : il se mesure au lieu de se regarder. Ce qui compte est qu'aux
/// deux extrémités la bande atteigne bien ses hauteurs cibles, qu'elle reste
/// collée en haut entre les deux, et surtout qu'elle **revienne** — un en-tête
/// qui ne se redéploie pas est le défaut classique de ce motif.
void main() {
  const favorites = [
    WorkspaceFavoriteData(name: 'Awa Traoré', badgeCount: 23),
    WorkspaceFavoriteData(name: 'Kwame Mensah'),
    WorkspaceFavoriteData(name: 'Fatou Diallo', badgeCount: 4),
    WorkspaceFavoriteData(name: 'Yao Kouassi'),
  ];

  late ScrollController controller;

  Future<void> pump(WidgetTester tester) async {
    controller = ScrollController();
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            controller: controller,
            slivers: [
              const SliverPersistentHeader(
                pinned: true,
                delegate: PinnedStripHeader(
                  favorites: favorites,
                  background: Colors.black,
                  borderColor: Colors.white24,
                ),
              ),
              SliverList.builder(
                itemCount: 40,
                itemBuilder: (context, i) => SizedBox(height: 78, child: Text('$i')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  const delegate = PinnedStripHeader(
    favorites: favorites,
    background: Colors.black,
    borderColor: Colors.white24,
  );

  testWidgets('déployée au repos, repliée une fois défilée', (tester) async {
    await pump(tester);

    final expanded = tester.getRect(find.byType(DecoratedBox).first);
    expect(
      expanded.height,
      moreOrLessEquals(delegate.maxExtent, epsilon: 0.5),
      reason: 'la bande doit partir déployée',
    );

    // Au-delà de la course de repli : la bande doit être au plus compact.
    controller.jumpTo(delegate.maxExtent - delegate.minExtent + 120);
    await tester.pump();

    final collapsed = tester.getRect(find.byType(DecoratedBox).first);
    expect(
      collapsed.height,
      moreOrLessEquals(delegate.minExtent, epsilon: 0.5),
      reason: 'la bande doit se replier, pas disparaître',
    );
    expect(
      collapsed.top,
      moreOrLessEquals(0, epsilon: 0.5),
      reason: 'elle reste accrochée en haut de l’écran',
    );
  });

  testWidgets('le retour vers le haut la redéploie', (tester) async {
    await pump(tester);

    controller.jumpTo(400);
    await tester.pump();
    controller.jumpTo(0);
    await tester.pump();

    expect(
      tester.getRect(find.byType(DecoratedBox).first).height,
      moreOrLessEquals(delegate.maxExtent, epsilon: 0.5),
    );
  });

  test('la course de repli reste perceptible', () {
    // Un écart trop faible entre les deux hauteurs rend l'effet invisible ;
    // trop fort, la liste sursaute sous le doigt.
    final travel = delegate.maxExtent - delegate.minExtent;
    expect(travel, greaterThan(40));
    expect(delegate.minExtent, greaterThan(40));
  });
}
