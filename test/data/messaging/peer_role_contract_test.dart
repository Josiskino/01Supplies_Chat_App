import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/data/models/auth/user_model.dart';
import 'package:supplies_chat_app/data/models/messaging/conversation_model.dart';
import 'package:supplies_chat_app/data/models/messaging/support_ticket_model.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_role.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_list_entry.dart';

void main() {
  test('profile role arrays preserve the first account role', () {
    for (final role in UserRole.values) {
      final user = UserModel.fromJson({
        'id': 'peer',
        'role': [role.wireName],
      }).toEntity();
      expect(user.role, role);
    }
    expect(UserModel.fromJson({'role': <String>[]}).toEntity().role, isNull);
    expect(
      UserModel.fromJson({
        'role': ['auditor', 'admin'],
      }).toEntity().role,
      isNull,
    );
  });

  test('ticket and direct rows display account roles supplied as arrays', () {
    for (final role in ['client', 'delivery', 'vendor']) {
      final profile = {
        'id': 'peer',
        'firstName': 'Peer',
        'role': [role],
      };
      final ticket = SupportTicketModel.fromJson({
        'id': 'ticket',
        'conversationId': 'conversation',
        'user': profile,
      }).toEntity();
      final conversation = ConversationModel.fromJson({
        'id': 'conversation',
        'participants': [
          {'userId': 'peer', 'role': 'member', 'user': profile},
        ],
      }).toEntity();
      expect(
        ConversationListEntry.fromTicket(ticket).peerRole,
        UserRole.fromWire(role),
      );
      expect(
        ConversationListEntry.fromConversation(conversation, me: 'me').peerRole,
        UserRole.fromWire(role),
      );
    }
  });
}
