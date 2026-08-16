import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/config/theme/apple_type.dart';
import 'package:supplies_chat_app/config/theme/theme.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/presentation/pages/conversations/widgets/conversation_row.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

/// Garde-fou de la densité de la liste de conversations.
///
/// Une hauteur de cellule ne se juge pas à l'œil sur une capture : l'écart qui
/// se voit est de l'ordre de 10 %, et il vient plus souvent des interlignes que
/// des corps de texte. Ici il est mesuré.
void main() {
  const data = ConversationListItemData(
    id: 'c1',
    name: 'Kofi Adjei',
    preview: 'Kofi : Parfait, ça me convient. Il me faudrait juste une '
        'confirmation avant ce soir',
    timeLabel: '12:10',
    presence: PresenceStatus.online,
    hasUnread: true,
  );

  Future<double> rowHeight(WidgetTester tester) async {
    // Gabarit d'un iPhone récent, en points logiques.
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPlatformProvider.overrideWithValue(AppPlatform.ios)],
        child: Builder(
          builder: (context) => CupertinoApp(
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultCupertinoLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            home: Theme(
              data: TAppTheme.lightThemeData(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [ConversationRow(data: data, onTap: () {})],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.getRect(find.byType(ConversationRow)).height;
  }

  testWidgets('la cellule tient dans le gabarit de Messages', (tester) async {
    final height = await rowHeight(tester);

    // Messages fait ~76 pt avec deux lignes d'aperçu. On accepte l'intervalle
    // 74–80 : la hauteur dépend de la police résolue, qui n'est pas la même sur
    // la machine de test que sur un iPhone.
    expect(
      height,
      inInclusiveRange(74, 80),
      reason: 'cellule à ${height.toStringAsFixed(1)} pt — hors du gabarit iOS',
    );
  });

  test('la grille reprend les valeurs des HIG', () {
    // Vérifiées contre `CupertinoTextThemeData` du SDK, qui applique les mêmes
    // corps et la même approche pour 17 et 15 pt.
    expect(AppleType.body.fontSize, 17);
    expect(AppleType.body.letterSpacing, closeTo(-0.41, 0.01));
    expect(AppleType.headline.fontSize, 17);
    expect(
      AppleType.headline.fontWeight,
      FontWeight.w600,
      reason: 'sur iOS un intitulé se détache par la graisse, pas par la taille',
    );
    expect(AppleType.subheadline.fontSize, 15);
    expect(AppleType.footnote.fontSize, 13);
    expect(AppleType.caption2.fontSize, 11);

    // L'interligne est le paramètre qui décide de la densité perçue : sans lui,
    // la police impose sa propre métrique, plus généreuse.
    expect(AppleType.body.height, closeTo(22 / 17, 0.001));
    expect(AppleType.subheadline.height, closeTo(20 / 15, 0.001));
  });
}
