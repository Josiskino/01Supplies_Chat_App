import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/message_composer.dart';

void main() {
  testWidgets('failed submission retains draft and prevents duplicate sends', (
    tester,
  ) async {
    final result = Completer<bool>();
    var calls = 0;
    Future<bool> send(String _) {
      calls++;
      return result.future;
    }

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: MessageComposer(onSend: send)),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Keep this draft');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pump();
    await tester.tap(find.byTooltip('Envoyer'));
    expect(calls, 1);
    result.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('Keep this draft'), findsOneWidget);
  });
  testWidgets('successful submission clears only the submitted draft', (
    tester,
  ) async {
    final result = Completer<bool>();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: MessageComposer(onSend: (_) => result.future)),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'First');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Next draft');
    result.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Next draft'), findsOneWidget);
  });
  testWidgets('recreated composer restores a conversation draft', (tester) async {
    var saved = 'Restored draft';
    Future<void> render() => tester.pumpWidget(ProviderScope(child: MaterialApp(home: Scaffold(body:
      MessageComposer(initialText: saved, onDraftChanged: (value) => saved = value),
    ))));
    await render();
    expect(find.text('Restored draft'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Edited draft');
    expect(saved, 'Edited draft');
    await tester.pumpWidget(const SizedBox());
    await render();
    expect(find.text('Edited draft'), findsOneWidget);
  });
  testWidgets('external draft update changes text without echoing a draft write', (tester) async {
    final writes = <String>[];
    Future<void> render(String draft) => tester.pumpWidget(ProviderScope(child: MaterialApp(home: Scaffold(body:
      MessageComposer(initialText: draft, onDraftChanged: writes.add),
    ))));
    await render('First conversation');
    await render('Restored conversation');
    expect(find.text('Restored conversation'), findsOneWidget);
    expect(writes, isEmpty);
  });

}
