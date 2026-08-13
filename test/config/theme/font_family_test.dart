import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/config/theme/theme.dart';
import 'package:supplies_chat_app/config/theme/widgets/text_theme.dart';

/// Verrouille l'alignement typographique sur l'app cliente.
///
/// Deux familles, et deux raisons de les fixer ici : `SF Pro` pour le corps,
/// `Bricolage Grotesque` pour les titres. Un `TextStyle` écrit à la main dans un
/// écran passe inaperçu s'il retombe sur la police par défaut — le défaut ne se
/// voit qu'à l'œil, sur un écran en particulier, et jamais à la compilation.
void main() {
  testWidgets('le thème porte la police du corps de texte', (tester) async {
    late ThemeData light;
    late ThemeData dark;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            light = TAppTheme.lightThemeData(context);
            dark = TAppTheme.darkThemeData(context);
            return const SizedBox();
          },
        ),
      ),
    );

    for (final theme in [light, dark]) {
      // Posée sur le ThemeData lui-même : c'est ce qui la fait hériter par les
      // styles écrits à la main, hors TextTheme.
      expect(theme.textTheme.bodyMedium?.fontFamily, TFonts.sfPro.value);
      expect(
        theme.textTheme.bodyLarge?.fontFamilyFallback,
        contains('Segoe UI'),
        reason: 'sans repli, Windows perd la police',
      );
    }
  });

  test('les titres restent en Bricolage Grotesque, comme chez le client', () {
    final title = TTextTheme.lightTextTheme.headlineMedium;
    // `GoogleFonts` préfixe la famille du nom du package.
    expect(title?.fontFamily, contains('Bricolage'));
  });
}
