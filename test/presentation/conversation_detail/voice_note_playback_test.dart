import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/voice_note_bubble.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

/// Vérifie le cycle de lecture d'une note vocale.
///
/// Le point sensible est la **fin naturelle** : rien ne reconstruit le bouton
/// quand l'animation s'achève d'elle-même, et l'icône restait sur « pause »
/// alors que plus rien ne jouait.
void main() {
  const voice = VoiceNoteData(
    duration: Duration(seconds: 2),
    waveform: [0.3, 0.6, 0.9, 0.5, 0.7],
  );

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: VoiceNoteBubble(
            voice: voice,
            foreground: Colors.black,
            accent: Colors.blue,
          ),
        ),
      ),
    ),
  );

  testWidgets('au repos, le bouton propose la lecture', (tester) async {
    await pump(tester);
    expect(find.byIcon(CupertinoIcons.play_fill), findsOneWidget);
    expect(find.text('0:02'), findsOneWidget);
  });

  testWidgets('en lecture, le bouton propose la pause', (tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(CupertinoIcons.play_fill));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byIcon(CupertinoIcons.pause_fill), findsOneWidget);
  });

  testWidgets(
    'à la fin, le bouton redevient lecture et le compteur est plein',
    (tester) async {
      await pump(tester);
      await tester.tap(find.byIcon(CupertinoIcons.play_fill));
      await tester.pump();

      // Laisser l'animation aller jusqu'au bout.
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(
        find.byIcon(CupertinoIcons.play_fill),
        findsOneWidget,
        reason: 'la lecture terminée doit rendre le bouton à son état initial',
      );
      expect(
        find.text('0:02'),
        findsOneWidget,
        reason: 'le compteur doit retomber sur la durée annoncée',
      );
    },
  );

  testWidgets('la forme d’onde se vide en fin de lecture', (tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(CupertinoIcons.play_fill));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // La tête de lecture est remise à zéro : laissée pleine, la forme d'onde
    // donnait un message définitivement barré.
    final state = tester.state(find.byType(VoiceNoteBubble));
    // ignore: avoid_dynamic_calls
    expect((state as dynamic).playbackProgress, 0);
  });

  testWidgets('relancer après la fin repart du début', (tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(CupertinoIcons.play_fill));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(CupertinoIcons.play_fill));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Rejoue : sans remise à zéro, la note resterait bloquée sur sa fin.
    expect(find.byIcon(CupertinoIcons.pause_fill), findsOneWidget);
  });
}
