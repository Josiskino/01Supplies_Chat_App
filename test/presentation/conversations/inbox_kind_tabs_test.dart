import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/data/models/messaging/conversation_model.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_list_entry.dart';
import 'package:supplies_chat_app/presentation/pages/conversations/widgets/inbox_kind_tabs.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

void main() {
  test('roles use populated API users, never conversation kind', () {
    for (final (role, label) in [
      ('client', 'Client'),
      ('delivery', 'Livreur'),
      ('vendor', 'Vendeur'),
      ('admin', null),
      ('unknown', null),
      (null, null),
    ]) {
      final entry = ConversationListEntry.fromConversation(
        ConversationModel.fromJson({
          'id': 'direct',
          'updatedAt': '2026-01-01',
          'participants': [
            {
              'user': {'id': 'me', 'name': 'Agent', 'role': 'admin'},
            },
            {
              'user': {'id': 'peer', 'name': 'Peer', 'role': role},
            },
          ],
        }).toEntity(),
        me: 'me',
      );
      expect(entry.peerRoleLabel, label);
      expect(
        ConversationListItemData.fromEntry(
          entry,
          timeLabel: '',
          showPeerRole: true,
        ).kindLabel,
        label,
      );
      expect(
        ConversationListItemData.fromEntry(entry, timeLabel: '').kindLabel,
        label == null ? 'Direct' : 'Direct · $label',
      );
    }
  });

  testWidgets('unread dots belong to each tab including hidden tab', (
    tester,
  ) async {
    bool? selected;
    Future<void> pump(bool supportUnread, bool directUnread) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InboxKindTabs(
                supportSelected: true,
                supportUnread: supportUnread,
                directUnread: directUnread,
                onChanged: (value) => selected = value,
              ),
            ),
          ),
        );
    await pump(true, false);
    expect(find.byKey(const ValueKey('support-unread')), findsOneWidget);
    expect(find.byKey(const ValueKey('direct-unread')), findsNothing);
    await tester.tap(find.text('Direct'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(selected, false);
    await pump(false, true);
    expect(find.byKey(const ValueKey('support-unread')), findsNothing);
    expect(find.byKey(const ValueKey('direct-unread')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
