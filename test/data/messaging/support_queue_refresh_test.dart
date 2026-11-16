import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supplies_chat_app/core/abstract/failure.dart';
import 'package:supplies_chat_app/core/providers/messaging/message_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_entity.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_entity.dart';
import 'package:supplies_chat_app/domain/entity/messaging/support_ticket_entity.dart';
import 'package:supplies_chat_app/domain/repository/messaging/message_repository.dart';
import 'package:supplies_chat_app/domain/repository/messaging/support_repository.dart';

class _Repository implements SupportRepository {
  bool fail = false;
  int conversationsCalls = 0;

  @override
  Future<Either<Failure, List<SupportTicketEntity>>> fetchQueue(
    FetchQueueParams params,
  ) async => right([
    SupportTicketEntity(
      id: 't1',
      conversationId: 'c1',
      subject: '',
      description: '',
      status: TicketStatus.open,
      priority: TicketPriority.medium,
      category: 'general',
      updatedAt: DateTime.utc(2026, 11, 10),
      lastMessage: 'Hello',
      lastMessageType: 'text',
    ),
  ]);

  @override
  Future<Either<Failure, List<ConversationEntity>>> fetchConversations() async {
    conversationsCalls++;
    return fail ? left(NetworkFailure('offline')) : right(const []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Messages implements MessageRepository {
  @override
  Future<Either<Failure, List<MessageEntity>>> fetchMessages(
    FetchMessagesParams params,
  ) async => right(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// `SupportQueue.refresh` backs the inbox pull-to-refresh: it must refetch
/// once, report failures (even when the list is kept on screen) and never
/// leave the spinner waiting for Riverpod's retry backoff.
void main() {
  late _Repository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _Repository();
    container = ProviderContainer(
      overrides: [
        supportRepositoryProvider.overrideWith((ref) => repository),
        messageRepositoryProvider.overrideWith((ref) => _Messages()),
      ],
    );
    addTearDown(container.dispose);
  });

  void listen() {
    final subscription = container.listen(supportQueueProvider, (_, _) {});
    addTearDown(subscription.close);
  }

  test('refetches the inbox once and reports fresh data', () async {
    listen();
    await container.read(supportQueueProvider.future);
    final before = repository.conversationsCalls;

    final fresh = await container.read(supportQueueProvider.notifier).refresh();

    expect(fresh, isTrue);
    expect(repository.conversationsCalls, before + 1);
    expect(container.read(supportQueueProvider).value, hasLength(1));
  });

  test('reports a failure while keeping the displayed list', () async {
    listen();
    await container.read(supportQueueProvider.future);
    repository.fail = true;

    final fresh = await container.read(supportQueueProvider.notifier).refresh();

    expect(fresh, isFalse);
    expect(container.read(supportQueueProvider).value, hasLength(1));
  });

  test('settles on failure without waiting for the automatic retry', () async {
    repository.fail = true;
    listen();
    // The first load fails: Riverpod keeps the state loading while it
    // schedules retries, so awaiting `future` would hang.
    await pumpEventQueue();
    expect(container.read(supportQueueProvider).hasValue, isFalse);

    final fresh = await container
        .read(supportQueueProvider.notifier)
        .refresh()
        .timeout(const Duration(seconds: 2));

    expect(fresh, isFalse);
  });
}
