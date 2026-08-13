import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supplies_chat_app/presentation/main/widgets/adaptive_nav_scaffold.dart';
import 'package:supplies_chat_app/presentation/main/widgets/custom_bottom_nav_bar.dart';
import 'package:supplies_chat_app/presentation/main/widgets/custom_bottom_nav_bar_item.dart';
import 'package:supplies_chat_app/presentation/main/widgets/custom_nav_rail.dart';

/// Vérifie la bascule de disposition sur la **largeur**, jamais sur la
/// plateforme : ces tests tournent sur l'hôte, et une fenêtre desktop réduite
/// doit se comporter comme un téléphone.
void main() {
  const items = [
    CustomBottomAppBarItem(
      icon: Iconsax.message,
      selectedIcon: Iconsax.message5,
      text: 'Conversations',
    ),
    CustomBottomAppBarItem(
      icon: Iconsax.receipt_item,
      selectedIcon: Iconsax.receipt_item5,
      text: 'Demandes',
    ),
    CustomBottomAppBarItem(
      icon: Iconsax.people,
      selectedIcon: Iconsax.people5,
      text: 'Contacts',
    ),
    CustomBottomAppBarItem(
      icon: Iconsax.user,
      selectedIcon: Iconsax.user_tag,
      text: 'Profil',
    ),
  ];

  /// Monte la coquille dans une fenêtre de largeur donnée.
  ///
  /// La taille de la **vue** est réglée, pas celle d'un `SizedBox` : la surface
  /// de test par défaut fait 800×600, et un enfant plus large y serait
  /// simplement contraint à 800 — le test croirait alors mesurer 1200 px.
  Future<void> pumpAt(
    WidgetTester tester,
    double width, {
    int selectedIndex = 0,
    ValueChanged<int>? onSelected,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveNavScaffold(
          selectedIndex: selectedIndex,
          items: items,
          onDestinationSelected: onSelected ?? (_) {},
          body: const Center(child: Text('contenu')),
        ),
      ),
    );
  }

  group('bascule de disposition', () {
    testWidgets('sous 600 px : barre du bas, pas de rail', (tester) async {
      await pumpAt(tester, 400);

      expect(find.byType(CustomBottomAppBar), findsOneWidget);
      expect(find.byType(CustomNavRail), findsNothing);
    });

    testWidgets('à 700 px : rail replié, pas de barre du bas', (tester) async {
      await pumpAt(tester, 700);

      expect(find.byType(CustomNavRail), findsOneWidget);
      expect(find.byType(CustomBottomAppBar), findsNothing);
      expect(tester.widget<CustomNavRail>(find.byType(CustomNavRail)).extended,
          isFalse);
    });

    testWidgets('à partir de 900 px : rail étendu', (tester) async {
      await pumpAt(tester, 1200);

      final rail = tester.widget<CustomNavRail>(find.byType(CustomNavRail));
      expect(rail.extended, isTrue);
      expect(find.byType(CustomBottomAppBar), findsNothing);
    });
  });

  group('cohérence entre les deux dispositions', () {
    testWidgets('le contenu et les libellés survivent au redimensionnement', (
      tester,
    ) async {
      await pumpAt(tester, 400);
      expect(find.text('contenu'), findsOneWidget);
      expect(find.text('Conversations'), findsOneWidget);

      // Même arbre, largeur différente : la coquille change, pas le contenu.
      await pumpAt(tester, 1200);
      expect(find.text('contenu'), findsOneWidget);
      expect(find.text('Conversations'), findsOneWidget);
    });

    testWidgets('les 4 destinations sont rendues dans les deux cas', (
      tester,
    ) async {
      for (final width in [400.0, 700.0, 1200.0]) {
        await pumpAt(tester, width);
        for (final item in items) {
          expect(
            find.text(item.text),
            findsOneWidget,
            reason: 'width=$width, destination=${item.text}',
          );
        }
      }
    });
  });

  group('sélection', () {
    testWidgets('un tap sur la barre du bas remonte le bon index', (
      tester,
    ) async {
      final taps = <int>[];
      await pumpAt(tester, 400, onSelected: taps.add);

      await tester.tap(find.text('Contacts'));
      await tester.pumpAndSettle();

      expect(taps, [2]);
    });

    testWidgets('un tap sur le rail remonte le bon index', (tester) async {
      final taps = <int>[];
      await pumpAt(tester, 1200, onSelected: taps.add);

      await tester.tap(find.text('Demandes'));
      await tester.pumpAndSettle();

      expect(taps, [1]);
    });
  });
}
