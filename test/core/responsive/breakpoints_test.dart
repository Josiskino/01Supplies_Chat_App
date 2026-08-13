import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/responsive/breakpoints.dart';

void main() {
  group('Breakpoints.formFactorOf', () {
    test('classe les largeurs dans le bon format', () {
      expect(Breakpoints.formFactorOf(320), FormFactor.compact);
      expect(Breakpoints.formFactorOf(599.9), FormFactor.compact);
      expect(Breakpoints.formFactorOf(600), FormFactor.medium);
      expect(Breakpoints.formFactorOf(899.9), FormFactor.medium);
      expect(Breakpoints.formFactorOf(900), FormFactor.expanded);
      expect(Breakpoints.formFactorOf(2560), FormFactor.expanded);
    });
  });

  group('usesLateralNavigation', () {
    test('barre du bas en compact, rail au-delà', () {
      expect(Breakpoints.usesLateralNavigation(400), isFalse);
      expect(Breakpoints.usesLateralNavigation(599), isFalse);
      expect(Breakpoints.usesLateralNavigation(600), isTrue);
      expect(Breakpoints.usesLateralNavigation(1440), isTrue);
    });
  });

  group('usesExtendedRail', () {
    test('le rail ne se déplie qu\'en format expanded', () {
      expect(Breakpoints.usesExtendedRail(400), isFalse);
      // En medium le rail existe mais reste replié : déplier ici mangerait la
      // largeur utile du contenu.
      expect(Breakpoints.usesExtendedRail(700), isFalse);
      expect(Breakpoints.usesExtendedRail(900), isTrue);
    });
  });
}
