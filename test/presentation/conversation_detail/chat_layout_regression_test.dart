import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/message_composer.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/voice_note_bubble.dart';
import 'package:supplies_chat_app/presentation/pages/conversations/widgets/conversation_row.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

void main() {
  testWidgets('waveform expands to duration and voice control stays compact', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: VoiceNoteBubble(
                voice: VoiceNoteData(
                  duration: Duration(seconds: 12),
                  waveform: [.3, .8],
                ),
                foreground: Colors.black,
                accent: Colors.blue,
              ),
            ),
          ),
        ),
      ),
    );
    final waveform = tester.getRect(
      find.byKey(const ValueKey('voice-waveform')),
    );
    final duration = tester.getRect(find.text('0:12'));
    expect(waveform.width, greaterThan(200));
    expect(duration.left - waveform.right, 8);
    expect(
      tester.getSize(find.byType(VoiceNoteBubble)).height,
      lessThanOrEqualTo(40),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'five-line composer retains rounded-end text clearance at large scale',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 280,
                    child: MessageComposer(
                      initialText: 'First\nSecond\nThird\nFourth\nFifth',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      final container = tester
          .widgetList<Container>(
            find.ancestor(of: field, matching: find.byType(Container)),
          )
          .firstWhere(
            (widget) =>
                widget.decoration is BoxDecoration &&
                (widget.decoration! as BoxDecoration).border != null,
          );
      expect(
        (container.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(19),
      );
      final editable = tester.getRect(find.byType(EditableText));
      final bounds = tester.getRect(find.byWidget(container));
      expect(editable.top - bounds.top, greaterThanOrEqualTo(10));
      expect(bounds.bottom - editable.bottom, greaterThanOrEqualTo(10));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Android role shares preview line and survives narrow large text',
    (tester) async {
      Future<void> pump(double width, double scale) => tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPlatformProvider.overrideWithValue(AppPlatform.android),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: width,
                    child: ConversationRow(
                      data: const ConversationListItemData(
                        id: 'c',
                        name: 'Long conversation name',
                        preview: 'Message preview',
                        timeLabel: '12:10',
                        kindLabel: 'Fournisseur',
                        unreadCount: 3,
                      ),
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await pump(390, 1);
      expect(tester.getSize(find.byType(ConversationRow)).height, lessThan(85));
      final role = tester.getRect(find.text('Fournisseur'));
      final preview = tester.getRect(find.text('Message preview'));
      expect((role.center.dy - preview.center.dy).abs(), lessThan(2));
      await pump(280, 1.6);
      expect(tester.takeException(), isNull);
    },
  );
}
