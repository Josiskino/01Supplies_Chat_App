import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/chat_bubble.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

void main() {
  for (final mine in [true, false]) {
    testWidgets(
      'author remains visible on every ${mine ? "outgoing" : "incoming"} support bubble',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatBubble(
                message: ChatMessageData(
                  id: '1',
                  text: 'Reply',
                  timeLabel: '10:30',
                  isMine: mine,
                  senderName: 'Agent Alice',
                ),
                isFirstOfGroup: false,
                isLastOfGroup: false,
                showAuthorAlways: true,
              ),
            ),
          ),
        );
        expect(find.text('Agent Alice'), findsOneWidget);
      },
    );
  }
}
