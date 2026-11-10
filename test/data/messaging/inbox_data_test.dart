import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supplies_chat_app/core/abstract/failure.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/core/providers/auth/auth_provider.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_entity.dart';
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
  List<ConversationEntity> conversations = [];
  @override
  Future<Either<Failure, List<SupportTicketEntity>>> fetchQueue(
    FetchQueueParams params,
  ) async => right([]);
  @override
  Future<Either<Failure, List<ConversationEntity>>>
  fetchConversations() async => failConversations
      ? left(NetworkFailure('Réessayez.'))
      : right(conversations);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
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
          ConversationEntity(id: 'other', updatedAt: DateTime.utc(2026, 2)),
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
      expect(immediate.first.preview, '📷 Photo');
      container.invalidate(supportQueueProvider);
      final refreshed = await container.read(supportQueueProvider.future);
      expect(refreshed.first.conversationId, 'older');
      expect(refreshed.first.preview, '📷 Photo');
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
        '📷 Photo',
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
        ConversationEntity(id: 'other', updatedAt: DateTime.utc(2026, 2)),
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
        ConversationEntity(id: 'other', updatedAt: DateTime.utc(2026, 2)),
      ];
      final switched = await container.read(supportQueueProvider.future);
      expect(switched.first.conversationId, 'other');
      expect(switched.last.preview, 'different session');
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
          ConversationEntity(id: 'c', updatedAt: DateTime.utc(2026)),
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
