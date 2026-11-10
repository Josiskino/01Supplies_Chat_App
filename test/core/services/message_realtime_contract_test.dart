import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/services/message_events_service.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_list_entry.dart';

void main() {
  ConversationListEntry entry(String? assignee) => ConversationListEntry(
    conversationId: 'c',
    title: 'x',
    preview: '',
    date: DateTime(2026),
    ticketId: 'ticket',
    assigneeId: assignee,
  );
  test('support subscriptions require this account to be assigned', () {
    expect(MessageEventsService.canWatch(entry('other'), 'me'), false);
    expect(MessageEventsService.canWatch(entry(null), 'me'), false);
    expect(MessageEventsService.canWatch(entry('me'), 'me'), true);
  });
  test('normalizes nested message envelopes without losing message ID', () {
    final normalized = ConversationRealtimeEvent('c', 'message.new', {
      'data': {
        'message': {'messageId': 'm', 'senderId': 's'},
      },
    });
    expect(normalized.data['messageId'], 'm');
  });
}
