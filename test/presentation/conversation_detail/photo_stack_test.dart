import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supplies_chat_app/presentation/widgets/photo/image_source.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/photo_stack.dart';

/// Inclinaison de la carte [index], lue sur le `Transform` qui l'enveloppe.
///
/// Remonte depuis l'image plutôt que d'énumérer les `Transform` de l'arbre :
/// Material en pose d'autres pour son compte, et le premier rencontré n'est pas
/// forcément celui d'une carte.
double _tiltOf(WidgetTester tester, int index) {
  final transform = tester.widget<Transform>(
    find
        .ancestor(
          of: find.byType(Image).at(index),
          matching: find.byType(Transform),
        )
        .first,
  );
  return transform.transform.getRotation().row1.x;
}

/// Ce que la pile promet, et qui n'est pas visible sur une capture.
void main() {
  final images = [
    for (var i = 1; i <= 12; i++) 'assets/images/demo/photo_$i.jpg',
  ];

  /// Cinq images : le dernier compte qui reste en escalier.
  final smallBatch = images.take(5).toList();

  Future<void> pump(WidgetTester tester, List<String> paths) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: PhotoStack(images: paths, onTap: () {}),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('le compteur annonce le total, pas les cartes dessinées', (
    tester,
  ) async {
    await pump(tester, smallBatch);

    // Cinq images, trois cartes : c'est le total qui doit s'afficher, sinon le
    // lot paraît amputé de ce qu'on ne voit pas.
    expect(find.text('5 photos'), findsOneWidget);
    expect(tester.widgetList(find.byType(Image)).length, 3);
  });

  testWidgets('une photo seule ne porte ni compteur ni inclinaison', (
    tester,
  ) async {
    await pump(tester, images.take(1).toList());

    expect(find.textContaining('photos'), findsNothing);

    // Une seule photo n'est pas un empilement : la pencher n'annoncerait rien et
    // donnerait un cadre de travers.
    expect(_tiltOf(tester, 0), 0);
  });

  testWidgets('les cartes sont inclinées en sens opposés', (tester) async {
    await pump(tester, images.take(2).toList());

    // Deux cartes penchées du même côté se liraient comme une image mal cadrée
    // plutôt que comme une pile.
    expect(_tiltOf(tester, 0) * _tiltOf(tester, 1), lessThan(0));
  });

  testWidgets('la pile entière est cliquable', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: PhotoStack(images: smallBatch, onTap: () => taps++),
            ),
          ),
        ),
      ),
    );

    // Un tap sur le compteur, au centre : c'est la cible la plus probable, et
    // elle est peinte par-dessus les cartes.
    await tester.tap(find.text('5 photos'));
    expect(taps, 1);
  });

  group('au-delà de cinq images, la pile prend la forme d’un paquet', () {
    testWidgets('deux tirages de front et deux bords entrevus', (tester) async {
      await pump(tester, images);

      // Quatre cartes : au-delà, on n'ajoute que des liserés illisibles ; en
      // dessous, le paquet n'a plus de fond et redevient une paire de photos.
      expect(tester.widgetList(find.byType(Image)).length, 4);
      expect(find.text('12 photos'), findsOneWidget);
    });

    testWidgets('les deux tirages de front penchent en sens contraires', (
      tester,
    ) async {
      await pump(tester, images);

      // Les deux dernières cartes rendues sont celles de front : `_layout` va du
      // fond vers l'avant.
      expect(_tiltOf(tester, 2) * _tiltOf(tester, 3), lessThan(0));

      // Les bords entrevus restent d'aplomb : inclinés, ils se liraient comme
      // des photos de travers plutôt que comme la tranche d'un paquet.
      expect(_tiltOf(tester, 0), 0);
      expect(_tiltOf(tester, 1), 0);
    });

    testWidgets('les tirages sont en portrait et se juxtaposent', (
      tester,
    ) async {
      await pump(tester, images);

      // La taille locale, non affectée par la rotation.
      final card = tester.getSize(find.byType(Image).at(2));
      // Des tirages en paysage donnaient un bandeau large et bas, très loin de la
      // paire de portraits posés l'un contre l'autre.
      expect(card.width, lessThan(card.height));

      // Les centres sont invariants sous rotation, contrairement aux coins.
      final left = tester.getCenter(find.byType(Image).at(3));
      final right = tester.getCenter(find.byType(Image).at(2));
      final overlap = card.width - (right.dx - left.dx);
      // Un franc recouvrement fait manger le tirage de droite par celui de
      // gauche : le paquet se lit alors comme une photo unique bordée d'un liseré.
      expect(overlap, greaterThan(0));
      expect(overlap, lessThan(card.width * 0.25));
    });

    testWidgets('aucune carte ne sort de la boîte allouée', (tester) async {
      await pump(tester, images);

      final box = tester.getRect(find.byType(PhotoStack));
      for (var i = 0; i < 4; i++) {
        final card = tester.getRect(find.byType(Image).at(i));
        // Une carte qui dépasse se fait couper par le bord de l'écran, ombre
        // comprise — le défaut que la marge de rotation existe pour éviter.
        expect(card.left, greaterThanOrEqualTo(box.left - 0.5));
        expect(card.right, lessThanOrEqualTo(box.right + 0.5));
        expect(card.top, greaterThanOrEqualTo(box.top - 0.5));
        expect(card.bottom, lessThanOrEqualTo(box.bottom + 0.5));
      }
    });
  });

  testWidgets('l’heure reste sur le tirage de front, pas dans la tranche', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: PhotoStack(
                images: images,
                onTap: () {},
                timeLabel: '10:11',
              ),
            ),
          ),
        ),
      ),
    );

    // Les bords entrevus rognent la hauteur des tirages : une heure calée sur le
    // bas de la boîte tombait sous la photo, dans la tranche du paquet.
    final time = tester.getRect(find.text('10:11'));
    final frontCard = tester.getRect(find.byType(Image).at(2));
    expect(time.bottom, lessThanOrEqualTo(frontCard.bottom));
    expect(time.right, lessThanOrEqualTo(frontCard.right));
  });

  group('imageProviderFor', () {
    test('reconnaît les trois origines d’une pièce jointe', () {
      // L'asset est le cas qui manquait : la visionneuse le confiait à `File`,
      // qui ne trouve évidemment rien à ce chemin relatif.
      expect(
        imageProviderFor('assets/images/demo/photo_1.jpg'),
        isA<AssetImage>(),
      );
      expect(
        imageProviderFor('https://example.com/a.jpg'),
        isNot(isA<AssetImage>()),
      );
      expect(imageProviderFor('/var/mobile/tmp/a.jpg'), isA<FileImage>());
    });
  });
}
