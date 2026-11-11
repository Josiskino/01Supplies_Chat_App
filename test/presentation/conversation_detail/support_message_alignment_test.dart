import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_entity.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_role.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_entity.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/chat_bubble.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

MessageEntity message(UserRole? role, {String senderId = 'other'}) =>
    MessageEntity(
      id: 'message',
      conversationId: 'support',
      senderId: senderId,
      content: 'Answer',
      type: MessageType.text,
      delivery: MessageDelivery.read,
      sentAt: DateTime(2026),
      sender: UserEntity(
        id: senderId,
        email: '',
        firstName: 'Alice',
        lastName: 'Agent',
        role: role,
      ),
    );

void main() {
  for (final role in [UserRole.admin, UserRole.support, UserRole.superAdmin]) {
    testWidgets('$role aligns right without granting ownership', (
      tester,
    ) async {
      final view = ChatMessageData.fromMessage(
        message(role),
        currentUserId: 'me',
        isSupport: true,
      );
      expect(view.isMine, isFalse);
      expect(view.isOutgoing, isTrue);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: view,
              isFirstOfGroup: true,
              isLastOfGroup: true,
              showAuthorAlways: true,
            ),
          ),
        ),
      );
      expect(find.text('Alice Agent'), findsOneWidget);
      final row = tester.widget<Row>(
        find
            .descendant(of: find.byType(ChatBubble), matching: find.byType(Row))
            .first,
      );
      expect(row.mainAxisAlignment, MainAxisAlignment.end);
    });
  }
  for (final role in [
    UserRole.client,
    UserRole.delivery,
    UserRole.vendor,
    null,
  ]) {
    test('$role remains incoming', () {
      final view = ChatMessageData.fromMessage(
        message(role),
        currentUserId: 'me',
        isSupport: true,
      );
      expect(view.isOutgoing, isFalse);
      expect(view.isMine, isFalse);
    });
  }
  test('direct threads retain sender ownership alignment', () {
    final view = ChatMessageData.fromMessage(
      message(UserRole.admin),
      currentUserId: 'me',
    );
    expect(view.isOutgoing, isFalse);
    final own = ChatMessageData.fromMessage(
      message(UserRole.support, senderId: 'me'),
      currentUserId: 'me',
      isSupport: true,
    );
    expect(own.isMine, isTrue);
    expect(own.isOutgoing, isTrue);
  });
}
