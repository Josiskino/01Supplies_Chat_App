import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supplies_chat_app/core/abstract/failure.dart';
import 'package:supplies_chat_app/core/providers/messaging/message_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_entity.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_entity.dart';
import 'package:supplies_chat_app/domain/entity/messaging/support_ticket_entity.dart';
import 'package:supplies_chat_app/domain/repository/messaging/message_repository.dart';

import 'inbox_data_test.dart' as fixtures;

SupportTicketEntity ticket(int index, {String type = 'text'}) =>
    SupportTicketEntity(
      id: 't$index',
      conversationId: 'c$index',
      subject: '',
      description: '',
      status: TicketStatus.open,
      priority: TicketPriority.medium,
      category: 'general',
      updatedAt: DateTime.utc(2026, 1, index + 1),
      lastMessage: 'Hello',
      lastMessageType: type,
      author: const UserEntity(
        id: 'peer',
        email: '',
        firstName: '',
        lastName: '',
        role: null,
      ),
    );

MessageEntity message(int index, {MessageType type = MessageType.text}) =>
    MessageEntity(
      id: 'm$index',
      conversationId: 'c0',
      senderId: 'peer',
      content: 'Hello',
      type: type,
      delivery: MessageDelivery.sent,
      sentAt: DateTime.utc(2026),
    );

class PagedMessages extends fixtures.FakeMessages {
  final pages = <int>[];
  @override
  Future<Either<Failure, List<MessageEntity>>> fetchMessages(
    FetchMessagesParams params,
  ) async {
    calls++;
    pages.add(params.page);
    return right([
      for (var i = 0; i < (params.page <= 4 ? 100 : 1); i++)
        message(params.page * 100 + i),
    ]);
  }
}

class RateLimitedMessages extends fixtures.FakeMessages {
  @override
  Future<Either<Failure, List<MessageEntity>>> fetchMessages(
    FetchMessagesParams params,
  ) async {
    calls++;
    return calls == 1
        ? left(RateLimitFailure('Retry later', retryAfterSeconds: 120))
        : right([message(1)]);
  }
}

class SystemPagedMessages extends PagedMessages {
  @override
  Future<Either<Failure, List<MessageEntity>>> fetchMessages(
    FetchMessagesParams params,
  ) async {
    calls++;
    pages.add(params.page);
    return right([
      for (var i = 0; i < (params.page <= 4 ? 100 : 1); i++)
        message(
          params.page * 100 + i,
          type: params.page <= 4 ? MessageType.system : MessageType.text,
        ),
    ]);
  }
}

void main() {
  testWidgets(
    'initial unread counts finish without receiving another message',
    (tester) async {
      final repository = fixtures.FakeRepository()
        ..tickets = [for (var i = 0; i < 9; i++) ticket(i)];
      final messages = fixtures.FakeMessages()
        ..messages = [message(1), message(2)];
      final container = ProviderContainer(
        overrides: [
          supportRepositoryProvider.overrideWith((ref) => repository),
          messageRepositoryProvider.overrideWith((ref) => messages),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(supportQueueProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(supportQueueProvider.future);
      expect(messages.calls, 4);

      await tester.pump(const Duration(seconds: 31));
      await container.read(supportQueueProvider.future);
      expect(messages.calls, 8);
      await tester.pump(const Duration(seconds: 31));
      final entries = await container.read(supportQueueProvider.future);
      expect(messages.calls, 9);
      expect(entries.every((entry) => entry.unreadCount == 2), isTrue);

      await tester.pump(const Duration(minutes: 2));
      expect(
        messages.calls,
        9,
        reason: 'Completed counts must not keep polling',
      );
    },
  );

  testWidgets(
    'unread history resumes its page after the request budget resets',
    (tester) async {
      final repository = fixtures.FakeRepository()..tickets = [ticket(0)];
      final messages = PagedMessages();
      final container = ProviderContainer(
        overrides: [
          supportRepositoryProvider.overrideWith((ref) => repository),
          messageRepositoryProvider.overrideWith((ref) => messages),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(supportQueueProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(supportQueueProvider.future);
      expect(messages.pages, [1, 2, 3, 4]);

      await tester.pump(const Duration(seconds: 31));
      final entries = await container.read(supportQueueProvider.future);
      expect(messages.pages, [1, 2, 3, 4, 5]);
      expect(entries.single.unreadCount, 401);
    },
  );

  testWidgets('automatic unread loading respects the server retry delay', (
    tester,
  ) async {
    final repository = fixtures.FakeRepository()..tickets = [ticket(0)];
    final messages = RateLimitedMessages();
    final container = ProviderContainer(
      overrides: [
        supportRepositoryProvider.overrideWith((ref) => repository),
        messageRepositoryProvider.overrideWith((ref) => messages),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(supportQueueProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(supportQueueProvider.future);
    expect(messages.calls, 1);
    await tester.pump(const Duration(seconds: 31));
    expect(messages.calls, 1);
    await tester.pump(const Duration(seconds: 91));
    final entries = await container.read(supportQueueProvider.future);
    expect(messages.calls, 2);
    expect(entries.single.unreadCount, 1);
  });

  testWidgets('reading a thread discards its pending unread history scan', (
    tester,
  ) async {
    final repository = fixtures.FakeRepository()..tickets = [ticket(0)];
    final messages = PagedMessages();
    final container = ProviderContainer(
      overrides: [
        supportRepositoryProvider.overrideWith((ref) => repository),
        messageRepositoryProvider.overrideWith((ref) => messages),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(supportQueueProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(supportQueueProvider.future);
    container.read(supportQueueProvider.notifier).markConversationRead('c0');
    await tester.pump(const Duration(seconds: 31));
    final entries = await container.read(supportQueueProvider.future);
    expect(entries.single.unreadCount, 0);
    expect(messages.calls, 4);
  });

  testWidgets('unobserved inbox stops loading unread counts', (tester) async {
    final repository = fixtures.FakeRepository()
      ..tickets = [for (var i = 0; i < 9; i++) ticket(i)];
    final messages = fixtures.FakeMessages()..messages = [message(1)];
    final container = ProviderContainer(
      overrides: [
        supportRepositoryProvider.overrideWith((ref) => repository),
        messageRepositoryProvider.overrideWith((ref) => messages),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(supportQueueProvider, (_, _) {});
    await container.read(supportQueueProvider.future);
    expect(messages.calls, 4);
    subscription.close();
    await tester.pump();
    await tester.pump(const Duration(minutes: 2));
    expect(messages.calls, 4);
  });

  testWidgets('long system-only pages cannot starve a real exchange', (
    tester,
  ) async {
    final repository = fixtures.FakeRepository()
      ..tickets = [ticket(0, type: 'system')];
    final messages = SystemPagedMessages();
    final container = ProviderContainer(
      overrides: [
        supportRepositoryProvider.overrideWith((ref) => repository),
        messageRepositoryProvider.overrideWith((ref) => messages),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(supportQueueProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(supportQueueProvider.future);
    expect(messages.calls, 4);
    await tester.pump(const Duration(seconds: 31));
    await container.read(supportQueueProvider.future);
    expect(messages.calls, 8);
    await tester.pump(const Duration(seconds: 31));
    final entries = await container.read(supportQueueProvider.future);
    expect(messages.pages, [1, 2, 3, 4, 5, 1, 2, 3, 4, 5]);
    expect(entries.single.unreadCount, 1);
  });
}
