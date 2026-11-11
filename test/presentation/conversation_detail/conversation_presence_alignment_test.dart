import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/conversation_online_status.dart';
import 'package:supplies_chat_app/presentation/pages/conversations/widgets/conversation_row.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

void main() {
  test('only the actual support peer can appear online', () {
    bool present(Map<String, Map<String, dynamic>> members) =>
        isConversationPeerPresent(
          peerId: 'client',
          currentUserId: 'me',
          isSupport: true,
          members: members,
        );
    expect(present({'me': {}, 'other-admin': {}}), isFalse);
    expect(present({'me': {}, 'client': {}}), isTrue);
    expect(present({}), isFalse);
    expect(
      isConversationPeerPresent(
        peerId: null,
        currentUserId: 'me',
        isSupport: true,
        members: {'other-admin': {}},
      ),
      isFalse,
    );
  });

  testWidgets('green dot and online label disappear when the peer leaves', (
    tester,
  ) async {
    Future<void> pump(bool online) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ConversationOnlineStatus(online: online)),
      ),
    );
    await pump(true);
    expect(find.text('En ligne'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('conversation-online-dot')),
      findsOneWidget,
    );
    await pump(false);
    expect(find.text('En ligne'), findsNothing);
    expect(find.byKey(const ValueKey('conversation-online-dot')), findsNothing);
  });

  testWidgets(
    'Android badges and stars align at the right despite role widths',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPlatformProvider.overrideWithValue(AppPlatform.android),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 390,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (role, count) in [
                        ('Client', 1),
                        ('Livreur', 12),
                      ])
                        ConversationRow(
                          data: ConversationListItemData(
                            id: role,
                            name: 'Name $role',
                            preview: 'Short',
                            timeLabel: '12:30',
                            kindLabel: role,
                            unreadCount: count,
                            isStarred: true,
                          ),
                          onTap: () {},
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final first = tester.getRect(
        find
            .ancestor(of: find.text('1'), matching: find.byType(Container))
            .first,
      );
      final second = tester.getRect(
        find
            .ancestor(of: find.text('12'), matching: find.byType(Container))
            .first,
      );
      expect(first.right, closeTo(second.right, .1));
      final stars = find.byIcon(Iconsax.star1);
      expect(
        tester.getRect(stars.at(0)).right,
        closeTo(tester.getRect(stars.at(1)).right, .1),
      );
      final row = tester.getRect(find.byType(ConversationRow).first);
      expect(first.right, greaterThan(row.right - 30));
      expect(tester.takeException(), isNull);
    },
  );
}
