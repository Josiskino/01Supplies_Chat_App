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
  const images = [
    'assets/images/demo/photo_1.jpg',
    'assets/images/demo/photo_2.jpg',
    'assets/images/demo/photo_3.jpg',
    'assets/images/demo/photo_4.jpg',
    'assets/images/demo/photo_5.jpg',
  ];

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
    await pump(tester, images);

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
              child: PhotoStack(images: images, onTap: () => taps++),
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
