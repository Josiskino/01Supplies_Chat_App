import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/chat_bubble.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

/// Couvre l'affichage de l'état d'acheminement.
///
/// La règle iOS est aussi importante que les libellés eux-mêmes : l'état ne
/// paraît que sous le **dernier** message émis, et « Envoyé » ne s'affiche
/// jamais — c'est l'état par défaut d'un message parti, l'annoncer ne répond à
/// aucune question.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required MessageStatus status,
    required bool isMine,
    required bool showStatus,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChatBubble(
          message: ChatMessageData(
            id: 'm1',
            text: 'Bonjour',
            timeLabel: '12:35',
            isMine: isMine,
            status: status,
          ),
          contactName: 'Kofi',
          isFirstOfGroup: true,
          isLastOfGroup: true,
          showStatus: showStatus,
        ),
      ),
    ),
  );

  testWidgets('« Distribué » apparaît sous le dernier message émis', (
    tester,
  ) async {
    await pump(
      tester,
      status: MessageStatus.delivered,
      isMine: true,
      showStatus: true,
    );
    // L'heure accompagne l'état : distribué sans horodatage ne dit pas quand.
    expect(find.text('Distribué 12:35'), findsOneWidget);
  });

  testWidgets('« Lu » porte l’heure', (tester) async {
    await pump(
      tester,
      status: MessageStatus.read,
      isMine: true,
      showStatus: true,
    );
    // L'heure compte plus que le fait de la lecture quand on relit un fil.
    expect(find.text('Lu 12:35'), findsOneWidget);
  });

  testWidgets('« Envoyé » n’est pas nommé, mais son heure reste', (
    tester,
  ) async {
    await pump(
      tester,
      status: MessageStatus.sent,
      isMine: true,
      showStatus: true,
    );
    expect(find.textContaining('Envoy'), findsNothing);
    expect(find.text('12:35'), findsOneWidget);
  });

  testWidgets('les messages plus anciens n’affichent rien', (tester) async {
    await pump(
      tester,
      status: MessageStatus.read,
      isMine: true,
      showStatus: false,
    );
    expect(find.textContaining('Lu'), findsNothing);
  });

  testWidgets('un message reçu n’a pas d’état', (tester) async {
    await pump(
      tester,
      status: MessageStatus.read,
      isMine: false,
      showStatus: true,
    );
    expect(find.textContaining('Lu'), findsNothing);
  });

  testWidgets('un échec s’affiche même sur un message ancien', (tester) async {
    await pump(
      tester,
      status: MessageStatus.failed,
      isMine: true,
      showStatus: false,
    );
    // Seul état qui doit rester visible où qu'il soit dans le fil : il appelle
    // une action de la part de l'utilisateur.
    expect(find.text('Non distribué'), findsOneWidget);
  });
}
