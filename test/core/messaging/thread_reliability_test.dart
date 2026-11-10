import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supplies_chat_app/core/abstract/failure.dart';
import 'package:supplies_chat_app/core/providers/messaging/message_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/core/providers/realtime/realtime_provider.dart';
import 'package:supplies_chat_app/core/services/message_events_service.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_list_entry.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_entity.dart';
import 'package:supplies_chat_app/domain/repository/messaging/message_repository.dart';

MessageEntity message(String id) => MessageEntity(
  id: id,
  conversationId: 'c1',
  senderId: 'me',
  content: 'Hello',
  type: MessageType.text,
  delivery: MessageDelivery.sent,
  sentAt: DateTime.utc(2026, 11, 10),
);

class FakeEvents implements MessageEventsService {
  final changes = StreamController<String>.broadcast();
  @override
  Stream<String> get threadChanges => changes.stream;
  @override
  Stream<ConversationRealtimeEvent> get conversationEvents =>
      const Stream.empty();
  @override
  Future<void> watchConversation(String id) async {}
  @override
  Future<void> unwatchConversation(String id) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMessages implements MessageRepository {
  final calls = <String>[];
  final readBatches = <List<String>?>[];
  List<MessageEntity> messages = [];
  bool fail = false;
  Completer<void>? sending;
  Completer<void>? fetching;
  final older = <String, List<MessageEntity>>{};
  @override
  Future<Either<Failure, List<MessageEntity>>> fetchMessages(
    FetchMessagesParams p,
  ) async {
    await fetching?.future;
    return Right(p.before == null ? messages : (older[p.before] ?? messages));
  }

  @override
  Future<Either<Failure, MessageEntity>> sendMessage(
    SendMessageParams p,
  ) async {
    calls.add('send');
    await sending?.future;
    return fail ? Left(ForbiddenFailure('Taken over')) : Right(message('sent'));
  }

  @override
  Future<Either<Failure, Unit>> markRead(MarkReadParams p) async {
    readBatches.add(p.messageIds);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> delete(String id) async => const Right(unit);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQueue extends SupportQueue {
  FakeQueue(
    this.calls, {
    this.claimAllowed = true,
    this.support = true,
    this.appearOnSecondLoad = false,
  });
  final List<String> calls;
  final bool claimAllowed;
  final bool support;
  final bool appearOnSecondLoad;
  int loads = 0;
  @override
  Future<List<ConversationListEntry>> build() async =>
      appearOnSecondLoad && loads++ == 0
      ? []
      : [
          ConversationListEntry(
            conversationId: 'c1',
            title: 'Client',
            preview: '',
            date: DateTime.utc(2026),
            ticketId: support ? 'ticket' : null,
            assigneeId: support ? 'other-agent' : null,
          ),
        ];
  @override
  Future<bool> join({required String ticketId, required String agentId}) async {
    calls.add('claim:$ticketId:$agentId');
    return claimAllowed;
  }
}

void main() {
  late FakeMessages messages;
  late FakeEvents events;
  late ProviderContainer container;

  Future<Thread> setup({
    bool claimAllowed = true,
    bool support = true,
    bool appearOnSecondLoad = false,
  }) async {
    messages = FakeMessages();
    events = FakeEvents();
    container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('me'),
        messageRepositoryProvider.overrideWithValue(messages),
        messageEventsProvider.overrideWithValue(events),
        supportQueueProvider.overrideWith(
          () => FakeQueue(
            messages.calls,
            claimAllowed: claimAllowed,
            support: support,
            appearOnSecondLoad: appearOnSecondLoad,
          ),
        ),
      ],
    );
    final subscription = container.listen(threadProvider('c1'), (_, _) {});
    addTearDown(() {
      subscription.close();
      container.dispose();
      events.changes.close();
    });
    await container.read(supportQueueProvider.future);
    await container.read(threadProvider('c1').future);
    return container.read(threadProvider('c1').notifier);
  }

  test(
    'first support send claims before sending without manual action',
    () async {
      final thread = await setup();
      expect(await thread.send('Hello'), isTrue);
      expect(messages.calls.take(2), ['claim:ticket:me', 'send']);
    },
  );

  test('claim failure prevents message transmission', () async {
    final thread = await setup(claimAllowed: false);
    expect(await thread.send('Hello'), isFalse);
    expect(messages.calls, ['claim:ticket:me']);
  });

  test('direct send does not claim a support ticket', () async {
    final thread = await setup(support: false);
    expect(await thread.send('Hello'), isTrue);
    expect(messages.calls, ['send']);
  });

  test('takeover between claim and send does not repeatedly reclaim', () async {
    final thread = await setup();
    messages.fail = true;
    expect(await thread.send('Hello'), isFalse);
    expect(messages.calls.take(2), ['claim:ticket:me', 'send']);
    expect(messages.calls.where((v) => v.startsWith('claim:')).length, 1);
  });

  test(
    'sending the server echo already in history does not duplicate it',
    () async {
      final thread = await setup(support: false);
      messages.messages = [message('sent')];
      await thread.refresh();
      expect(await thread.send('Hello'), isTrue);
      final state =
          container.read(threadProvider('c1')).requireValue as ThreadMessages;
      expect(state.messages.map((m) => m.id), ['sent']);
    },
  );
  test(
    'read acknowledgements batch only received messages in groups of at most 100',
    () async {
      final thread = await setup(support: false);
      messages.messages = List.generate(
        150,
        (i) => MessageEntity(
          id: 'in-$i',
          conversationId: 'c1',
          senderId: 'customer',
          content: 'Hello',
          type: MessageType.text,
          delivery: MessageDelivery.sent,
          sentAt: DateTime.utc(2026),
        ),
      );
      await thread.refresh();
      await thread.markRead();
      expect(messages.readBatches.map((ids) => ids?.length), [100, 50]);
      await thread.markRead();
      expect(messages.readBatches.length, 2);
    },
  );
  test(
    'successful deletion cannot be resurrected by a stale snapshot',
    () async {
      final thread = await setup(support: false);
      messages.messages = [message('old')];
      await thread.refresh();
      expect(await thread.delete('old'), isTrue);
      await thread.refresh();
      final state =
          container.read(threadProvider('c1')).requireValue as ThreadMessages;
      expect(state.messages.where((m) => m.id == 'old'), isEmpty);
    },
  );
  test(
    'concurrent refresh callers wait until the shared refresh completes',
    () async {
      final thread = await setup(support: false);
      messages.fetching = Completer<void>();
      final first = thread.refresh();
      var finished = false;
      final second = thread.refresh().then((_) => finished = true);
      await Future<void>.delayed(Duration.zero);
      expect(finished, isFalse);
      messages.fetching!.complete();
      await Future.wait([first, second]);
      expect(finished, isTrue);
    },
  );
  test(
    'an attachment captured during another send keeps a retryable outgoing item',
    () async {
      final thread = await setup(support: false);
      messages.sending = Completer<void>();
      final first = thread.send('sending');
      await Future<void>.delayed(Duration.zero);
      expect(
        await thread.sendAttachments(
          filePaths: ['/tmp/voice-test.m4a'],
          type: MessageType.audio,
        ),
        isFalse,
      );
      final state =
          container.read(threadProvider('c1')).requireValue as ThreadMessages;
      expect(
        state.messages.where((m) => m.isFailed && m.type == MessageType.audio),
        hasLength(1),
      );
      messages.sending!.complete();
      await first;
    },
  );

  test(
    'reconnect catches up across more than one page without leaving a history gap',
    () async {
      final thread = await setup(support: false);
      messages.messages = [message('known')];
      await thread.refresh();
      MessageEntity at(String id, int minute) => MessageEntity(
        id: id,
        conversationId: 'c1',
        senderId: 'customer',
        content: id,
        type: MessageType.text,
        delivery: MessageDelivery.sent,
        sentAt: DateTime.utc(2026, 11, 10).add(Duration(minutes: minute)),
      );
      messages.messages = List.generate(50, (i) => at('recent-$i', i + 60));
      messages.older[DateTime.utc(2026, 11, 10, 1).toIso8601String()] = [
        message('known'),
        at('gap', 30),
      ];
      await thread.refresh();
      final state =
          container.read(threadProvider('c1')).requireValue as ThreadMessages;
      expect(state.messages.where((m) => m.id == 'gap'), hasLength(1));
      expect(state.messages.map((m) => m.id).toSet().length, 52);
    },
  );
  test(
    'a newly created direct conversation refreshes missing inbox metadata before sending',
    () async {
      final thread = await setup(support: false, appearOnSecondLoad: true);
      expect(await thread.send('First message'), isTrue);
      expect(messages.calls, ['send']);
    },
  );
}
