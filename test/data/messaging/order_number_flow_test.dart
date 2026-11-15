import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/abstract/failure.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/core/providers/auth/auth_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/inbox_snapshot_store.dart';
import 'package:supplies_chat_app/core/providers/messaging/message_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/pinned_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/core/providers/realtime/realtime_provider.dart';
import 'package:supplies_chat_app/data/models/messaging/order_reference_parser.dart';
import 'package:supplies_chat_app/data/models/messaging/support_ticket_model.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_entity.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_entity.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_list_entry.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_entity.dart';
import 'package:supplies_chat_app/domain/entity/messaging/support_ticket_entity.dart';
import 'package:supplies_chat_app/presentation/desktop/desktop_workspace_shell.dart';
import 'package:supplies_chat_app/presentation/desktop/widgets/conversation_list_panel.dart';
import 'package:supplies_chat_app/presentation/pages/conversations/conversations_screen.dart';
import 'package:supplies_chat_app/presentation/widgets/inbox/conversation_title.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

import '../../helpers/test_environment.dart';
import 'inbox_data_test.dart' as fixtures;
import 'shared_read_state_test.dart' show MapStorage;

const _mongoId = '64a1b2c3d4e5f6a7b8c9d0e1';
const _order = '01-ORD 1731600000000AB12CD';

const _agent = UserEntity(
  id: 'admin',
  email: '',
  firstName: '',
  lastName: '',
  role: null,
);

SupportTicketEntity _ticket({String? orderNumber}) => SupportTicketEntity(
  id: 't',
  conversationId: 'c',
  subject: '',
  description: '',
  status: TicketStatus.open,
  priority: TicketPriority.medium,
  category: 'general',
  updatedAt: DateTime.utc(2026, 11, 13),
  lastMessage: 'Bonjour',
  lastMessageType: 'text',
  orderId: _mongoId,
  orderNumber: orderNumber,
);

void main() {
  setUpAll(setUpTestEnvironment);

  group('OrderReferenceParser edge cases', () {
    String? number(Map<String, dynamic> json) =>
        OrderReferenceParser.orderNumber(json);

    test('the current backend payload (orderId only) shows no number', () {
      // `formatTicketResponse` on origin/develop: `orderId: id.toString()`.
      final json = {
        'id': 't',
        'conversationId': 'c',
        'orderId': _mongoId,
        'metadata': {'orderId': _mongoId},
      };
      expect(number(json), isNull);
      expect(OrderReferenceParser.orderId(json), _mongoId);
    });

    test('an id in a preferred field falls through to the next candidate', () {
      expect(
        number({
          'orderNumber': _mongoId,
          'order': {'number': _mongoId.toUpperCase()},
          'metadata': {'orderReference': _order},
        }),
        _order,
      );
    });

    test('top-level fields win over nested ones', () {
      expect(
        number({
          'orderReference': 'REF-1',
          'order': {'orderNumber': 'NESTED'},
          'metadata': {'orderNumber': 'META'},
        }),
        'REF-1',
      );
      expect(
        number({
          'order': {'orderNumber': 'A', 'number': 'B', 'reference': 'C'},
        }),
        'A',
      );
      expect(
        number({
          'order': {'reference': 'C'},
        }),
        'C',
      );
    });

    test('numeric order numbers are kept as text', () {
      expect(number({'orderNumber': 1731}), '1731');
      expect(
        number({
          'metadata': {'orderNumber': 42.0},
        }),
        '42.0',
      );
    });

    test('malformed shapes never throw and never leak an id', () {
      for (final json in <Map<String, dynamic>>[
        {},
        {'order': _mongoId},
        {'order': 12},
        {'order': <Object>[]},
        {'metadata': 'x'},
        {'metadata': null},
        {'orderNumber': true},
        {
          'orderNumber': ['01-ORD 1'],
        },
        {'orderNumber': ' $_mongoId '},
        {'orderNumber': _mongoId.toUpperCase()},
        {
          'order': {'orderNumber': null, '_id': _mongoId},
        },
      ]) {
        expect(number(json), isNull, reason: '$json');
      }
    });

    test('identifiers that only look close to a Mongo id are numbers', () {
      // 23 and 25 hex characters, or non-hex: not an ObjectId.
      expect(number({'orderNumber': _mongoId.substring(1)}), isNotNull);
      expect(number({'orderNumber': '${_mongoId}0'}), isNotNull);
      expect(number({'orderNumber': '64a1b2c3d4e5f6a7b8c9d0eZ'}), isNotNull);
    });

    test('orderId accepts an object, a nested order or nothing', () {
      expect(
        OrderReferenceParser.orderId({
          'orderId': {'_id': _mongoId},
        }),
        _mongoId,
      );
      expect(
        OrderReferenceParser.orderId({
          'orderId': {'id': _mongoId},
        }),
        _mongoId,
      );
      expect(
        OrderReferenceParser.orderId({
          'order': {'id': _mongoId},
        }),
        _mongoId,
      );
      expect(OrderReferenceParser.orderId({'orderId': '  '}), isNull);
      expect(OrderReferenceParser.orderId({}), isNull);
    });

    test('a realistic ticket JSON maps all the way to the inbox row', () {
      final model = SupportTicketModel.fromJson({
        'id': 't',
        'conversationId': 'c',
        'subject': 'Livraison',
        'status': 'open',
        'orderId': _mongoId,
        'order': {'_id': _mongoId, 'orderNumber': _order},
        'user': {
          'id': 'u',
          'firstName': 'Aline',
          'lastName': 'K.',
          'role': 'client',
        },
      });
      final entry = ConversationListEntry.fromTicket(model.toEntity());
      expect(entry.orderNumber, _order);
      final row = ConversationListItemData.fromEntry(entry, timeLabel: '');
      expect(row.orderNumber, _order);
      expect(row.name, isNot(contains(_mongoId)));
    });

    test('a direct conversation has no order number', () {
      final entry = ConversationListEntry.fromConversation(
        ConversationEntity(id: 'c', updatedAt: DateTime.utc(2026)),
        me: 'admin',
      );
      expect(entry.orderNumber, isNull);
    });
  });

  group('inbox snapshot', () {
    ConversationListEntry entry({String? orderNumber}) => ConversationListEntry(
      conversationId: 'c',
      title: 'Aline',
      preview: 'Bonjour',
      date: DateTime.utc(2026, 11, 14),
      isSupport: true,
      ticketId: 't',
      orderNumber: orderNumber,
    );

    test('a missing order number round-trips as null', () async {
      final storage = MapStorage();
      final store = PreferencesInboxSnapshotStore(storage);
      await store.save('me', [entry()]);
      expect((await store.load('me')).single.orderNumber, isNull);
    });

    test('snapshots saved before the field existed still load', () async {
      final storage = MapStorage();
      final encoded = PreferencesInboxSnapshotStore.encode(entry())
        ..remove('orderNumber');
      storage.values[PreferencesInboxSnapshotStore.keyFor('me')] = jsonEncode([
        encoded,
      ]);
      final loaded = await PreferencesInboxSnapshotStore(storage).load('me');
      expect(loaded.single.conversationId, 'c');
      expect(loaded.single.orderNumber, isNull);
    });

    test('a corrupted order number is dropped, not the row', () async {
      final storage = MapStorage();
      final encoded = PreferencesInboxSnapshotStore.encode(entry())
        ..['orderNumber'] = 1731;
      storage.values[PreferencesInboxSnapshotStore.keyFor('me')] = jsonEncode([
        encoded,
      ]);
      final loaded = await PreferencesInboxSnapshotStore(storage).load('me');
      expect(loaded.single.ticketId, 't');
      expect(loaded.single.orderNumber, isNull);
    });

    test('snapshots are per account', () async {
      final store = PreferencesInboxSnapshotStore(MapStorage());
      await store.save('me', [entry(orderNumber: _order)]);
      expect(await store.load('other'), isEmpty);
      expect((await store.load('me')).single.orderNumber, _order);
    });
  });

  group('SupportQueue keeps the order number', () {
    late fixtures.FakeRepository repository;

    Future<ProviderContainer> launch({InboxSnapshotStore? snapshots}) async {
      final container = ProviderContainer(
        overrides: [
          supportRepositoryProvider.overrideWith((ref) => repository),
          messageRepositoryProvider.overrideWith(
            (ref) => fixtures.FakeMessages(),
          ),
          if (snapshots != null)
            inboxSnapshotStoreProvider.overrideWithValue(snapshots),
        ],
      );
      addTearDown(container.dispose);
      container.read(currentUserProvider.notifier).set(_agent);
      final subscription = container.listen(supportQueueProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(supportQueueProvider.future);
      return container;
    }

    setUp(() {
      repository = fixtures.FakeRepository()
        ..tickets = [_ticket(orderNumber: _order)]
        ..conversations = [
          ConversationEntity(
            id: 'c',
            updatedAt: DateTime.utc(2026, 11, 13),
            lastMessage: 'Bonjour',
            supportTicketId: 't',
          ),
        ];
    });

    test('through the build, realtime activity and a read', () async {
      final container = await launch();
      ConversationListEntry row() =>
          container.read(supportQueueProvider).requireValue.single;
      expect(row().orderNumber, _order);

      final notifier = container.read(supportQueueProvider.notifier);
      notifier.recordActivity(
        MessageEntity(
          id: 'm1',
          conversationId: 'c',
          senderId: 'customer',
          content: 'Toujours rien ?',
          type: MessageType.text,
          delivery: MessageDelivery.sent,
          sentAt: DateTime.utc(2026, 11, 14),
        ),
        received: true,
      );
      expect(row().preview, contains('Toujours rien'));
      expect(row().unreadCount, 1);
      expect(row().orderNumber, _order, reason: 'realtime merge path');

      notifier.markConversationRead('c');
      expect(row().unreadCount, 0);
      expect(row().orderNumber, _order, reason: 'read path');
    });

    test('a rate-limited refresh keeps the previous rows and their order '
        'numbers', () async {
      final container = await launch();
      repository.conversationsFailure = RateLimitFailure(
        'Trop de tentatives.',
        retryAfterSeconds: 120,
      );
      container.invalidate(supportQueueProvider);
      final rows = await container.read(supportQueueProvider.future);
      expect(rows.single.orderNumber, _order);
      expect(container.read(supportQueueProvider).hasError, isFalse);
    });

    test('a successful load is snapshotted with its order number, and a '
        'cold start restores it', () async {
      final snapshots = InMemoryInboxSnapshotStore();
      await launch(snapshots: snapshots);
      await Future<void>.delayed(Duration.zero);
      expect((await snapshots.load('admin')).single.orderNumber, _order);

      repository.conversationsFailure = RateLimitFailure(
        'Trop de tentatives.',
        retryAfterSeconds: 120,
      );
      final cold = await launch(snapshots: snapshots);
      expect(
        cold.read(supportQueueProvider).requireValue.single.orderNumber,
        _order,
      );
    });
  });

  group('search matches the order number', () {
    testWidgets('desktop workspace filters by order number', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final entries = [
        ConversationListEntry(
          conversationId: 'a',
          title: 'Aline',
          preview: 'Bonjour',
          date: DateTime(2026, 2),
          ticketId: 't1',
          isSupport: true,
          orderNumber: _order,
        ),
        ConversationListEntry(
          conversationId: 'b',
          title: 'Bruno',
          preview: 'Salut',
          date: DateTime(2026, 1),
          ticketId: 't2',
          isSupport: true,
          orderNumber: '01-ORD 999',
        ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPlatformProvider.overrideWithValue(AppPlatform.macos),
            supportQueueProvider.overrideWith(() => _StubQueue(entries)),
            pinnedConversationsProvider.overrideWith(_NoPins.new),
            for (final e in entries) ...[
              typingUsersProvider(
                e.conversationId,
              ).overrideWith((ref) => Stream.value({})),
              conversationPresenceProvider(
                e.conversationId,
              ).overrideWith((ref) => Stream.value({})),
            ],
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: Scaffold(body: DesktopWorkspaceShell()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      List<String> ids() => tester
          .widget<ConversationListPanel>(find.byType(ConversationListPanel))
          .conversations
          .map((c) => c.id)
          .toList();
      expect(ids(), ['a', 'b']);

      final search = find.descendant(
        of: find.byType(ConversationListPanel),
        matching: find.byType(TextField),
      );
      await tester.enterText(search, 'ab12cd');
      await tester.pump();
      expect(ids(), ['a'], reason: 'case-insensitive tail of the number');
      await tester.enterText(search, 'ord 999');
      await tester.pump();
      expect(ids(), ['b']);
      await tester.enterText(search, _mongoId);
      await tester.pump();
      expect(ids(), isEmpty);
    });

    testWidgets('android phone list filters by order number', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final entries = [
        ConversationListEntry(
          conversationId: 'a',
          title: 'Aline',
          preview: 'Bonjour',
          date: DateTime(2026, 2),
          ticketId: 't1',
          isSupport: true,
          orderNumber: _order,
        ),
        ConversationListEntry(
          conversationId: 'b',
          title: 'Bruno',
          preview: 'Salut',
          date: DateTime(2026, 1),
          ticketId: 't2',
          isSupport: true,
        ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPlatformProvider.overrideWithValue(AppPlatform.android),
            supportQueueProvider.overrideWith(() => _StubQueue(entries)),
            pinnedConversationsProvider.overrideWith(_NoPins.new),
            currentUserIdProvider.overrideWithValue('admin'),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: ConversationsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Aline'), findsOneWidget);
      expect(find.text('Bruno'), findsOneWidget);
      expect(find.byKey(ConversationTitle.orderKey), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'AB12CD');
      await tester.pump();
      expect(find.text('Aline'), findsOneWidget);
      expect(find.text('Bruno'), findsNothing);
    });
  });
}

class _StubQueue extends SupportQueue {
  _StubQueue(this.entries);
  final List<ConversationListEntry> entries;
  @override
  Future<List<ConversationListEntry>> build() async => entries;
}

class _NoPins extends PinnedConversations {
  @override
  Set<String> build() => {};
}
