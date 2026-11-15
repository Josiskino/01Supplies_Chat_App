import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/providers/messaging/inbox_snapshot_store.dart';
import 'package:supplies_chat_app/data/models/messaging/order_reference_parser.dart';
import 'package:supplies_chat_app/data/models/messaging/support_ticket_model.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_list_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supplies_chat_app/core/services/local_storage/shared_preferences_storage.dart';

void main() {
  const mongoId = '64a1b2c3d4e5f6a7b8c9d0e1';

  Map<String, dynamic> ticket(Map<String, dynamic> extra) => {
    'id': 't1',
    'conversationId': 'c1',
    'subject': 'Commande non reçue',
    'status': 'open',
    ...extra,
  };

  group('OrderReferenceParser', () {
    test('a bare Mongo orderId is never presented as a number', () {
      final json = ticket({'orderId': mongoId});
      expect(OrderReferenceParser.orderNumber(json), isNull);
      expect(OrderReferenceParser.orderId(json), mongoId);
    });

    test('accepts every likely projection of the human number', () {
      for (final json in [
        ticket({'orderNumber': '01-ORD 1731'}),
        ticket({'orderReference': '01-ORD 1731'}),
        ticket({
          'order': {'id': mongoId, 'orderNumber': '01-ORD 1731'},
        }),
        ticket({
          'order': {'number': '01-ORD 1731'},
        }),
        ticket({
          'metadata': {'orderNumber': ' 01-ORD 1731 '},
        }),
      ]) {
        expect(OrderReferenceParser.orderNumber(json), '01-ORD 1731');
      }
    });

    test('ignores blanks, ids and non-scalar values', () {
      expect(
        OrderReferenceParser.orderNumber(
          ticket({
            'orderNumber': '  ',
            'orderReference': mongoId,
            'order': {'orderNumber': <String, dynamic>{}},
          }),
        ),
        isNull,
      );
      expect(
        OrderReferenceParser.orderId(
          ticket({
            'order': {'_id': mongoId},
          }),
        ),
        mongoId,
      );
    });
  });

  test('the ticket carries the order number to the inbox entry', () {
    final entity = SupportTicketModel.fromJson(
      ticket({'orderId': mongoId, 'orderNumber': '01-ORD 1731'}),
    ).toEntity();
    expect(entity.orderId, mongoId);
    expect(entity.orderNumber, '01-ORD 1731');
    expect(
      entity.withConversation(lastMessage: 'x').orderNumber,
      '01-ORD 1731',
      reason: 'enriching a ticket must not drop its order',
    );
    expect(ConversationListEntry.fromTicket(entity).orderNumber, '01-ORD 1731');
  });

  test('the inbox snapshot keeps the order number', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PreferencesInboxSnapshotStore(SharedPreferencesStorage());
    await store.save('me', [
      ConversationListEntry(
        conversationId: 'c1',
        title: 'Aline',
        preview: 'Bonjour',
        date: DateTime.utc(2026, 11, 14),
        isSupport: true,
        orderNumber: '01-ORD 1731',
      ),
    ]);
    final loaded = await store.load('me');
    expect(loaded.single.orderNumber, '01-ORD 1731');
  });
}
