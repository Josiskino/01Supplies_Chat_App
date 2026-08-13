import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/config/theme/theme.dart';

/// Garde-fou contre le piège `copyWith(textTheme:)`.
///
/// `copyWith` **remplace** intégralement le `TextTheme` du thème de base. Tout
/// style non redéfini se retrouve alors avec une géométrie mais sans couleur, donc
/// peint en blanc — invisible en thème clair. `TAppTheme` fusionne (`merge`) pour
/// l'éviter ; ce test échoue si quelqu'un repasse à un remplacement, ou si le
/// framework ajoute un style que notre `TextTheme` ne couvre pas.
void main() {
  /// Tous les styles d'un `TextTheme`, nommés pour un message d'échec lisible.
  Map<String, TextStyle?> stylesOf(TextTheme t) => {
    'displayLarge': t.displayLarge,
    'displayMedium': t.displayMedium,
    'displaySmall': t.displaySmall,
    'headlineLarge': t.headlineLarge,
    'headlineMedium': t.headlineMedium,
    'headlineSmall': t.headlineSmall,
    'titleLarge': t.titleLarge,
    'titleMedium': t.titleMedium,
    'titleSmall': t.titleSmall,
    'bodyLarge': t.bodyLarge,
    'bodyMedium': t.bodyMedium,
    'bodySmall': t.bodySmall,
    'labelLarge': t.labelLarge,
    'labelMedium': t.labelMedium,
    'labelSmall': t.labelSmall,
  };

  testWidgets('aucun style de texte n\'est sans couleur', (tester) async {
    for (final isDark in [false, true]) {
      late ThemeData theme;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              theme = isDark
                  ? TAppTheme.darkThemeData(context)
                  : TAppTheme.lightThemeData(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      stylesOf(theme.textTheme).forEach((name, style) {
        expect(
          style,
          isNotNull,
          reason: '$name est absent du TextTheme (isDark=$isDark)',
        );
        expect(
          style!.color,
          isNotNull,
          reason: '$name n\'a pas de couleur (isDark=$isDark) — il sera peint '
              'en blanc et deviendra invisible en thème clair',
        );
      });
    }
  });

  testWidgets('les textes du thème clair sont sombres, et inversement', (
    tester,
  ) async {
    late ThemeData light;
    late ThemeData dark;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            light = TAppTheme.lightThemeData(context);
            dark = TAppTheme.darkThemeData(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // Un corps de texte clair sur fond clair est le symptôme exact du bug.
    expect(light.textTheme.bodyMedium!.color!.computeLuminance(), lessThan(0.5));
    expect(
      dark.textTheme.bodyMedium!.color!.computeLuminance(),
      greaterThan(0.5),
    );
  });
}
