import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supplies_chat_app/core/abstract/failure.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/message_provider.dart';
import 'package:supplies_chat_app/domain/repository/messaging/message_repository.dart';
import 'package:supplies_chat_app/core/providers/auth/auth_provider.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_entity.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_role.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_entity.dart';
import 'package:supplies_chat_app/domain/repository/messaging/support_repository.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_entity.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_list_entry.dart';
import 'package:supplies_chat_app/domain/entity/messaging/support_ticket_entity.dart';
import 'package:supplies_chat_app/data/models/messaging/conversation_model.dart';
import 'package:supplies_chat_app/core/abstract/api_client_interface.dart';
import 'package:supplies_chat_app/core/utils/api_types.dart';
import 'package:supplies_chat_app/data/datasources/remote/support_remote_datasource.dart';
import 'package:supplies_chat_app/data/models/messaging/support_ticket_model.dart';

class FakeClient extends ApiClientInterface {
  final calls = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> pages;
  FakeClient(this.pages);
  @override
  Future<ApiResult<T>> request<T>({
    String? baseUrl,
    required String path,
    required HttpMethod method,
    required JsonParser<T> fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? dataKey,
    List<MetadataConfig> metadataConfigs = const [],
    JsonParser<dynamic>? itemFromJson,
    List<String>? listPath,
  }) async {
    calls.add({'path': path, 'data': data, 'page': queryParameters?['page']});
    final page = pages[(queryParameters?['page'] as int? ?? 1) - 1];
    if (page['error'] == true) {
      return const ApiError(message: 'failed', statusCode: 503);
    }
    return ApiSuccess(
      data: fromJson(page),
      statusCode: 200,
      metadata: {
        for (final config in metadataConfigs) config.key: page[config.key],
      },
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRepository implements SupportRepository {
  bool failConversations = false;
  List<SupportTicketEntity> tickets = [];
  List<ConversationEntity> conversations = [];
  @override
  Future<Either<Failure, List<SupportTicketEntity>>> fetchQueue(
    FetchQueueParams params,
  ) async => right(tickets);
  @override
  Future<Either<Failure, List<ConversationEntity>>>
  fetchConversations() async => failConversations
      ? left(NetworkFailure('Réessayez.'))
      : right(conversations);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMessages implements MessageRepository {
  List<MessageEntity> messages = [];
  int calls = 0;
  @override
  Future<Either<Failure, List<MessageEntity>>> fetchMessages(
    FetchMessagesParams params,
  ) async {
    calls++;
    return right(messages);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'large shared inbox bounds history calls across repeated refreshes',
    () async {
      final repository = FakeRepository()
        ..tickets = [
          for (var i = 0; i < 30; i++)
            SupportTicketEntity(
              id: 't$i',
              conversationId: 'c$i',
              subject: '',
              description: '',
              status: TicketStatus.open,
              priority: TicketPriority.medium,
              category: 'general',
              updatedAt: DateTime.utc(2026, 1, i + 1),
              lastMessage: 'Hello',
              lastMessageType: 'text',
            ),
        ];
      final messages = FakeMessages();
      final container = ProviderContainer(
        overrides: [
          supportRepositoryProvider.overrideWith((ref) => repository),
          messageRepositoryProvider.overrideWith((ref) => messages),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(supportQueueProvider, (_, _) {});
      addTearDown(subscription.close);
      expect(await container.read(supportQueueProvider.future), hasLength(30));
      container.invalidate(supportQueueProvider);
      await container.read(supportQueueProvider.future);
      expect(messages.calls, 4);
    },
  );
  test(
    'shared queue counts customer unread before an admin claims it',
    () async {
      final repository = FakeRepository()
        ..tickets = [
          SupportTicketEntity(
            id: 'ticket',
            conversationId: 'c',
            subject: '',
            description: '',
            status: TicketStatus.open,
            priority: TicketPriority.medium,
            category: 'general',
            updatedAt: DateTime.utc(2026),
            lastMessage: 'Hello',
            lastMessageType: 'text',
            author: const UserEntity(
              id: 'peer',
              email: '',
              firstName: '',
              lastName: '',
              role: null,
            ),
          ),
        ];
      final messages = FakeMessages()
        ..messages = [
          for (var i = 0; i < 2; i++)
            MessageEntity(
              id: 'm$i',
              conversationId: 'c',
              senderId: 'peer',
              content: 'Hello',
              type: MessageType.text,
              delivery: MessageDelivery.sent,
              sentAt: DateTime.utc(2026),
            ),
          MessageEntity(
            id: 'admin-message',
            conversationId: 'c',
            senderId: 'another-admin',
            content: 'Hello',
            type: MessageType.text,
            delivery: MessageDelivery.sent,
            sentAt: DateTime.utc(2026),
          ),
        ];
      final container = ProviderContainer(
        overrides: [
          supportRepositoryProvider.overrideWith((ref) => repository),
          messageRepositoryProvider.overrideWith((ref) => messages),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(supportQueueProvider, (_, _) {});
      addTearDown(subscription.close);
      expect(
        (await container.read(supportQueueProvider.future)).single.unreadCount,
        2,
      );
      container.read(supportQueueProvider.notifier).markConversationRead('c');
      container.invalidate(supportQueueProvider);
      expect(
        (await container.read(supportQueueProvider.future)).single.unreadCount,
        0,
      );
    },
  );
  test(
    'hides empty rows and retains real history before a system message',
    () async {
      final repository = FakeRepository()
        ..conversations = [
          ConversationEntity(id: 'empty', updatedAt: DateTime.utc(2026)),
          ConversationEntity(
            id: 'real',
            updatedAt: DateTime.utc(2026),
            lastMessage: 'Assigned',
            lastMessageType: 'system',
          ),
        ];
      final messages = FakeMessages()
        ..messages = [
          MessageEntity(
            id: 'm',
            conversationId: 'real',
            senderId: 'peer',
            content: 'Hello',
            type: MessageType.text,
            delivery: MessageDelivery.sent,
            sentAt: DateTime.utc(2026),
          ),
        ];
      final container = ProviderContainer(
        overrides: [
          supportRepositoryProvider.overrideWith((ref) => repository),
          messageRepositoryProvider.overrideWith((ref) => messages),
        ],
      );
      addTearDown(container.dispose);
      expect(
        (await container.read(
          supportQueueProvider.future,
        )).map((e) => e.conversationId),
        ['real'],
      );
    },
  );

  test(
    'incoming unread increments once, survives stale REST and clears on read',
    () async {
      final repository = FakeRepository()
        ..conversations = [
          ConversationEntity(
            id: 'c',
            updatedAt: DateTime.utc(2026),
            lastMessage: 'old',
          ),
        ];
      final container = ProviderContainer(
        overrides: [
          supportRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(currentUserProvider.notifier)
          .set(
            const UserEntity(
              id: 'admin',
              email: '',
              firstName: '',
              lastName: '',
              role: null,
            ),
          );
      final subscription = container.listen(supportQueueProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(supportQueueProvider.future);
      final notifier = container.read(supportQueueProvider.notifier);
      final message = MessageEntity(
        id: 'incoming',
        conversationId: 'c',
        senderId: 'peer',
        content: 'Hello',
        type: MessageType.text,
        delivery: MessageDelivery.sent,
        sentAt: DateTime.utc(2026, 2),
      );
      notifier.recordActivity(message, received: true);
      notifier.recordActivity(message, received: true);
      expect(
        container.read(supportQueueProvider).requireValue.single.unreadCount,
        1,
      );
      container.invalidate(supportQueueProvider);
      expect(
        (await container.read(supportQueueProvider.future)).single.unreadCount,
        1,
      );
      notifier.markConversationRead('c');
      expect(
        container.read(supportQueueProvider).requireValue.single.unreadCount,
        0,
      );
    },
  );
  test(
    'support conversation outside ticket snapshot retains ticket identity',
    () async {
      final repository = FakeRepository()
        ..conversations = [
          ConversationModel.fromJson({
            'id': 'c',
            'type': 'support',
            'updatedAt': '2026-01-01T00:00:00Z',
            'metadata': {'supportTicketId': 't'},
            'lastMessage': {'content': 'Bonjour', 'type': 'text'},
          }).toEntity(),
        ];
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          supportRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);
      final entries = await container.read(supportQueueProvider.future);
      expect(entries.single.ticketId, 't');
      expect(entries.single.isSupport, isTrue);
      expect(entries.single.title, 'Demande de support');
    },
  );
  test(
    'new activity moves immediately and survives an older REST snapshot',
    () async {
      final repository = FakeRepository()
        ..conversations = [
          ConversationEntity(
            id: 'older',
            updatedAt: DateTime.utc(2026, 1),
            lastMessage: 'stale',
          ),
          ConversationEntity(
            id: 'other',
            updatedAt: DateTime.utc(2026, 2),
            lastMessage: 'Hello',
          ),
        ];
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          supportRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(currentUserProvider.notifier)
          .set(
            const UserEntity(
              id: 'admin',
              email: '',
              firstName: '',
              lastName: '',
              role: null,
            ),
          );
      final subscription = container.listen(supportQueueProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(supportQueueProvider.future);
      final notifier = container.read(supportQueueProvider.notifier);
      notifier.recordActivity(
        MessageEntity(
          id: 'new-message',
          conversationId: 'older',
          senderId: 'admin',
          content: '',
          type: MessageType.image,
          delivery: MessageDelivery.sent,
          sentAt: DateTime.utc(2026, 3),
        ),
      );
      final immediate = container.read(supportQueueProvider).requireValue;
      expect(immediate.first.conversationId, 'older');
      expect(immediate.first.preview, 'Vous : 📷 Photo');
      container.invalidate(supportQueueProvider);
      final refreshed = await container.read(supportQueueProvider.future);
      expect(refreshed.first.conversationId, 'older');
      expect(refreshed.first.preview, 'Vous : 📷 Photo');
      expect(refreshed.first.date, DateTime.utc(2026, 3));
      notifier.recordActivity(
        MessageEntity(
          id: 'old-message',
          conversationId: 'older',
          senderId: 'admin',
          content: 'late old event',
          type: MessageType.text,
          delivery: MessageDelivery.sent,
          sentAt: DateTime.utc(2026, 1),
        ),
      );
      expect(
        container.read(supportQueueProvider).requireValue.first.preview,
        'Vous : 📷 Photo',
      );
      notifier.recordActivity(
        MessageEntity(
          id: 'unknown',
          conversationId: 'unknown-route',
          senderId: 'admin',
          content: 'cannot invent a route',
          type: MessageType.text,
          delivery: MessageDelivery.sent,
          sentAt: DateTime.utc(2026, 4),
        ),
      );
      expect(container.read(supportQueueProvider).requireValue, hasLength(2));

      repository.conversations = [
        ConversationEntity(
          id: 'older',
          updatedAt: DateTime.utc(2026, 4),
          lastMessage: 'newer REST',
        ),
        ConversationEntity(
          id: 'other',
          updatedAt: DateTime.utc(2026, 2),
          lastMessage: 'Hello',
        ),
      ];
      container.invalidate(supportQueueProvider);
      expect(
        (await container.read(supportQueueProvider.future)).first.preview,
        'newer REST',
      );
      container
          .read(currentUserProvider.notifier)
          .set(
            const UserEntity(
              id: 'different-admin',
              email: '',
              firstName: '',
              lastName: '',
              role: null,
            ),
          );
      repository.conversations = [
        ConversationEntity(
          id: 'older',
          updatedAt: DateTime.utc(2026, 1),
          lastMessage: 'different session',
        ),
        ConversationEntity(
          id: 'other',
          updatedAt: DateTime.utc(2026, 2),
          lastMessage: 'Hello',
        ),
      ];
      final switched = await container.read(supportQueueProvider.future);
      expect(switched.first.conversationId, 'other');
      expect(switched.last.preview, 'different session');
    },
  );
  test(
    'confirmed multiline reply survives stale equal-timestamp REST',
    () async {
      final date = DateTime.utc(2026, 3);
      final repository = FakeRepository()
        ..conversations = [
          ConversationEntity(
            id: 'thread',
            updatedAt: date,
            lastMessage: 'Client ancien',
          ),
        ];
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          supportRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(currentUserProvider.notifier)
          .set(
            const UserEntity(
              id: 'admin',
              email: '',
              firstName: '',
              lastName: '',
              role: null,
            ),
          );
      final subscription = container.listen(supportQueueProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(supportQueueProvider.future);
      container
          .read(supportQueueProvider.notifier)
          .recordActivity(
            MessageEntity(
              id: 'reply',
              conversationId: 'thread',
              senderId: 'admin',
              content: 'Bonsoir.\n\nVotre commande est prête.',
              type: MessageType.text,
              delivery: MessageDelivery.sent,
              sentAt: date,
            ),
          );
      expect(
        container.read(supportQueueProvider).requireValue.single.preview,
        'Vous : Bonsoir. Votre commande est prête.',
      );
      container.invalidate(supportQueueProvider);
      expect(
        (await container.read(supportQueueProvider.future)).single.preview,
        'Vous : Bonsoir. Votre commande est prête.',
      );
    },
  );

  test(
    'REST previews identify the replying admin and normalize paragraphs',
    () {
      const sender = UserEntity(
        id: 'agent',
        email: '',
        firstName: 'Kofi',
        lastName: '',
        role: UserRole.admin,
      );
      final conversation = ConversationEntity(
        id: 'thread',
        updatedAt: DateTime.utc(2026),
        lastMessage: 'Bonsoir.\nLa commande est prête.',
        lastSender: sender,
      );
      expect(
        ConversationListEntry.fromConversation(
          conversation,
          me: 'other',
        ).preview,
        'Kofi : Bonsoir. La commande est prête.',
      );
      expect(
        ConversationListEntry.fromConversation(
          conversation,
          me: 'agent',
        ).preview,
        'Vous : Bonsoir. La commande est prête.',
      );
    },
  );

  test('support type without ticket linkage keeps its identity', () {
    final conversation = ConversationModel.fromJson({
      'id': 'unlinked-support',
      'type': 'support',
      'updatedAt': '2026-01-01T00:00:00Z',
    }).toEntity();
    final entry = ConversationListEntry.fromConversation(
      conversation,
      me: 'admin',
    );
    expect(entry.isSupport, isTrue);
    expect(entry.ticketId, isNull);
    expect(entry.title, 'Demande de support');
    final direct = ConversationListEntry.fromConversation(
      ConversationEntity(id: 'direct', updatedAt: DateTime.utc(2026)),
      me: 'admin',
    );
    expect(direct.isSupport, isFalse);
  });
  test(
    'partial refresh failure exposes error and retains previous inbox',
    () async {
      final repository = FakeRepository()
        ..conversations = [
          ConversationEntity(
            id: 'c',
            updatedAt: DateTime.utc(2026),
            lastMessage: 'Hello',
          ),
        ];
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          supportRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(supportQueueProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(supportQueueProvider.future);
      repository.failConversations = true;
      container.invalidate(supportQueueProvider);
      await expectLater(
        container.read(supportQueueProvider.future),
        throwsA(isA<Exception>()),
      );
      final state = container.read(supportQueueProvider);
      expect(state.hasError, true);
      expect(state.value?.single.conversationId, 'c');
    },
  );
  test('sparse embedded conversation never invents current activity time', () {
    final ticket = SupportTicketModel.fromJson({
      'id': 't',
      'conversationId': 'c',
      'updatedAt': '2026-01-01T00:00:00Z',
      'conversation': {'unreadCount': 3},
    }).toEntity();
    expect(ticket.displayDate.toUtc(), DateTime.utc(2026));
  });
  test(
    'pagination without metadata stops safely when the server repeats a page',
    () async {
      final client = FakeClient([
        {
          'data': [
            {'id': 'a'},
          ],
        },
        {
          'data': [
            {'id': 'a'},
          ],
        },
      ]);
      expect(
        await SupportRemoteDataSource(client).fetchConversations(limit: 1),
        isA<ApiError>(),
      );
      expect(client.calls, hasLength(2));
    },
  );
  test('claim derives identity from session and sends no body', () async {
    final client = FakeClient([{}]);
    await SupportRemoteDataSource(
      client,
    ).joinTicket(ticketId: 'ticket', agentId: 'untrusted');
    expect(client.calls.single['path'], 'messaging/support/ticket/claim');
    expect(client.calls.single['data'], isNull);
  });
  test(
    'both sources fetch remaining pages and deduplicate boundary records',
    () async {
      for (final tickets in [true, false]) {
        final client = FakeClient([
          {
            'data': [
              {'id': 'a'},
              {'id': 'b'},
            ],
            'meta': {'totalPages': 2},
          },
          {
            'data': [
              {'id': 'b'},
              {'id': 'c'},
            ],
            'meta': {'totalPages': 2},
          },
        ]);
        final source = SupportRemoteDataSource(client);
        final result = tickets
            ? await source.fetchQueue(limit: 2)
            : await source.fetchConversations(limit: 2);
        expect(client.calls.length, 2);
        expect(result.data, hasLength(3));
      }
    },
  );
  test('later-page failure is not returned as complete success', () async {
    final client = FakeClient([
      {
        'data': [
          {'id': 'a'},
        ],
        'meta': {'totalPages': 2},
      },
      {'error': true},
    ]);
    expect(
      await SupportRemoteDataSource(client).fetchQueue(limit: 1),
      isA<ApiError>(),
    );
  });
  test(
    'ticket preserves embedded activity and authoritative assigned identity',
    () {
      final ticket = SupportTicketModel.fromJson({
        'id': 't',
        'conversationId': 'c',
        'updatedAt': '2026-01-01T00:00:00Z',
        'description': 'opening',
        'assignedTo': 'new',
        'assignedAgent': {
          'id': 'new',
          'firstName': 'Current',
          'lastName': 'Agent',
        },
        'conversation': {
          'id': 'c',
          'updatedAt': '2026-02-01T00:00:00Z',
          'unreadCount': 4,
          'lastMessage': {
            'content': 'latest',
            'type': 'text',
            'createdAt': '2026-02-01T00:00:00Z',
          },
          'participants': [
            {
              'userId': 'old',
              'role': 'support_agent',
              'isActive': false,
              'user': {'id': 'old', 'firstName': 'Previous'},
            },
          ],
        },
      }).toEntity();
      expect(ticket.preview, 'latest');
      expect(ticket.displayDate.toUtc(), DateTime.utc(2026, 2, 1));
      expect(ticket.displayUnreadCount, 4);
      expect(ticket.assigneeName, 'Current Agent');
      expect(ticket.participantIds, isNot(contains('old')));
    },
  );
}
