import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supplies_chat_app/core/abstract/failure.dart';
import 'package:supplies_chat_app/core/abstract/local_storage_interface.dart';
import 'package:supplies_chat_app/core/providers/auth/auth_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/message_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/read_watermark_store.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_entity.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_entity.dart';
import 'package:supplies_chat_app/domain/entity/messaging/support_ticket_entity.dart';
import 'package:supplies_chat_app/domain/repository/messaging/message_repository.dart';

import 'inbox_data_test.dart' as fixtures;

const customer = UserEntity(
  id: 'customer',
  email: '',
  firstName: '',
  lastName: '',
  role: null,
);

UserEntity agent(String id) =>
    UserEntity(id: id, email: '', firstName: '', lastName: '', role: null);

SupportTicketEntity ticket() => SupportTicketEntity(
  id: 'ticket',
  conversationId: 'c',
  subject: '',
  description: '',
  status: TicketStatus.open,
  priority: TicketPriority.medium,
  category: 'general',
  updatedAt: DateTime.utc(2026, 11, 13),
  lastMessage: 'Hello',
  lastMessageType: 'text',
  author: customer,
);

MessageEntity msg(String id, String sender, int minute) => MessageEntity(
  id: id,
  conversationId: 'c',
  senderId: sender,
  content: 'Hello',
  type: MessageType.text,
  delivery: MessageDelivery.sent,
  sentAt: DateTime.utc(2026, 11, 13, 9, minute),
);

class PagedMessages extends fixtures.FakeMessages {
  /// Newest page first, as the API serves them.
  List<List<MessageEntity>> pages = [];
  final requested = <int>[];
  @override
  Future<Either<Failure, List<MessageEntity>>> fetchMessages(
    FetchMessagesParams params,
  ) async {
    calls++;
    requested.add(params.page);
    return right(
      params.page <= pages.length ? pages[params.page - 1] : const [],
    );
  }
}

class MapStorage implements LocalStorageInterface {
  final values = <String, String>{};
  @override
  Future<String> getString(String key) async => values[key] ?? '';
  @override
  Future<bool> setString(String key, String value) async {
    values[key] = value;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ReadWatermarkStore store;
  late fixtures.FakeRepository repository;
  late fixtures.FakeMessages messages;

  setUp(() {
    store = InMemoryReadWatermarkStore();
    repository = fixtures.FakeRepository()..tickets = [ticket()];
  });

  /// One app launch, signed in as [me].
  Future<ProviderContainer> launch(String me) async {
    final container = ProviderContainer(
      overrides: [
        supportRepositoryProvider.overrideWith((ref) => repository),
        messageRepositoryProvider.overrideWith((ref) => messages),
        readWatermarkStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    container.read(currentUserProvider.notifier).set(agent(me));
    final subscription = container.listen(supportQueueProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(supportQueueProvider.future);
    return container;
  }

  Future<int> unread(ProviderContainer container) async =>
      (await container.read(supportQueueProvider.future)).single.unreadCount;

  test(
    'a read the API refused to record survives a restart on this device',
    () async {
      messages = fixtures.FakeMessages()
        ..messages = [msg('m1', 'customer', 1), msg('m2', 'customer', 2)];
      final first = await launch('admin-a');
      expect(await unread(first), 2);

      first
          .read(supportQueueProvider.notifier)
          .markConversationRead('c', through: DateTime.utc(2026, 11, 13, 9, 2));
      expect(await unread(first), 0);
      await Future<void>.delayed(Duration.zero);
      first.dispose();

      final restarted = await launch('admin-a');
      expect(await unread(restarted), 0);
    },
  );

  test(
    'a message after the stored read stays unread after a restart',
    () async {
      messages = fixtures.FakeMessages()..messages = [msg('m1', 'customer', 1)];
      final first = await launch('admin-a');
      first
          .read(supportQueueProvider.notifier)
          .markConversationRead('c', through: DateTime.utc(2026, 11, 13, 9, 1));
      await Future<void>.delayed(Duration.zero);
      first.dispose();

      messages.messages = [...messages.messages, msg('m2', 'customer', 5)];
      final restarted = await launch('admin-a');
      expect(await unread(restarted), 1);
    },
  );

  test('stored reads belong to the account that made them', () async {
    messages = fixtures.FakeMessages()..messages = [msg('m1', 'customer', 1)];
    final first = await launch('admin-a');
    first
        .read(supportQueueProvider.notifier)
        .markConversationRead('c', through: DateTime.utc(2026, 11, 13, 9, 1));
    await Future<void>.delayed(Duration.zero);
    first.dispose();

    final other = await launch('admin-b');
    expect(await unread(other), 1);
  });

  test('the read-through timestamp never moves backwards', () async {
    messages = fixtures.FakeMessages()
      ..messages = [msg('m1', 'customer', 1), msg('m2', 'customer', 2)];
    final container = await launch('admin-a');
    final queue = container.read(supportQueueProvider.notifier);
    queue.markConversationRead('c', through: DateTime.utc(2026, 11, 13, 9, 2));
    queue.markConversationRead('c', through: DateTime.utc(2026, 11, 13, 9, 1));
    await Future<void>.delayed(Duration.zero);
    expect(
      (await store.load('admin-a'))['c'],
      DateTime.utc(2026, 11, 13, 9, 2),
    );
  });

  group('PreferencesReadWatermarkStore', () {
    test('round-trips timestamps per account', () async {
      final storage = MapStorage();
      final prefs = PreferencesReadWatermarkStore(storage);
      await prefs.save('a', {'c': DateTime.utc(2026, 11, 13, 9)});
      expect(await prefs.load('a'), {'c': DateTime.utc(2026, 11, 13, 9)});
      expect(await prefs.load('b'), isEmpty);
    });

    test('corrupt data costs only the local read state', () async {
      final storage = MapStorage()
        ..values[PreferencesReadWatermarkStore.keyFor('a')] = '{not json';
      expect(await PreferencesReadWatermarkStore(storage).load('a'), isEmpty);
    });

    test('keeps only the most recent reads', () async {
      final storage = MapStorage();
      final prefs = PreferencesReadWatermarkStore(storage);
      final start = DateTime.utc(2026);
      await prefs.save('a', {
        for (var i = 0; i < PreferencesReadWatermarkStore.maxEntries + 5; i++)
          'c$i': start.add(Duration(minutes: i)),
      });
      final loaded = await prefs.load('a');
      expect(loaded, hasLength(PreferencesReadWatermarkStore.maxEntries));
      expect(loaded.containsKey('c0'), isFalse);
    });
  });
}
