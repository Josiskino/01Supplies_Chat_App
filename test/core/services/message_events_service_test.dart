import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supplies_chat_app/core/abstract/api_client_interface.dart';
import 'package:supplies_chat_app/core/auth/auth_gate.dart';
import 'package:supplies_chat_app/core/providers/auth/auth_provider.dart';
import 'package:supplies_chat_app/core/providers/auth/auth_status_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/core/providers/realtime/realtime_provider.dart';
import 'package:supplies_chat_app/core/providers/request/api_provider.dart';
import 'package:supplies_chat_app/core/services/message_events_service.dart';
import 'package:supplies_chat_app/core/services/pusher_service.dart';
import 'package:supplies_chat_app/core/utils/api_types.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_entity.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_list_entry.dart';

class FakeClient implements ApiClientInterface {
  final receipts = <List<String>>[];
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
    if (path.endsWith('/delivered')) {
      receipts.add(List<String>.from((data as Map)['messageIds'] as List));
    }
    return ApiSuccess(data: fromJson({}), statusCode: 200);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Session extends AuthStatusNotifier {
  @override
  AuthGateStatus build() => AuthGateStatus.authenticated;
  void change(AuthGateStatus value) => state = value;
}

class Queue extends SupportQueue {
  static int loads = 0;
  void reassign([String assignee = 'another']) {
    state = AsyncData([
      ConversationListEntry(
        conversationId: 'c',
        title: 'x',
        preview: '',
        date: DateTime(2026),
        ticketId: 'ticket',
        assigneeId: assignee,
      ),
    ]);
  }

  @override
  Future<List<ConversationListEntry>> build() async {
    loads++;
    return [
      ConversationListEntry(
        conversationId: 'c',
        title: 'x',
        preview: '',
        date: DateTime(2026),
      ),
    ];
  }
}

class FakePusher extends PusherService {
  final callbacks = <String, Map<String, Set<PusherEventHandler>>>{};
  final states = StreamController<RealtimeConnectionState>.broadcast(
    sync: true,
  );
  int connections = 0;
  @override
  Stream<RealtimeConnectionState> get connectionStates => states.stream;
  @override
  Future<void> connect({
    required String apiKey,
    required String cluster,
    required PusherAuthorizer authorizer,
  }) async {
    connections++;
  }

  @override
  Future<void> disconnect() async {
    callbacks.clear();
  }

  @override
  Future<void> dispose() async {
    await states.close();
  }

  @override
  Future<void> bindEvent({
    required String channelName,
    required String eventName,
    required PusherEventHandler handler,
  }) async {
    callbacks
        .putIfAbsent(channelName, () => {})
        .putIfAbsent(eventName, () => {})
        .add(handler);
  }

  @override
  Future<void> unbindEvent({
    required String channelName,
    required String eventName,
    PusherEventHandler? handler,
  }) async {
    callbacks[channelName]?[eventName]?.remove(handler);
  }

  @override
  Future<bool> trigger({
    required String channelName,
    required String eventName,
    required Map<String, dynamic> data,
  }) async => true;
  void emit(String channel, String event, Map<String, dynamic> data) {
    for (final handler
        in callbacks[channel]?[event]?.toList() ?? <PusherEventHandler>[]) {
      handler(data);
    }
  }
}

UserEntity user(String id) => UserEntity(
  id: id,
  email: 'a@b.c',
  firstName: 'Agent',
  lastName: '',
  role: null,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late FakePusher pusher;
  late FakeClient client;
  late MessageEventsService service;
  Future<void> setup({Duration queueRefreshInterval = Duration.zero}) async {
    Queue.loads = 0;
    dotenv.loadFromString(envString: 'PUSHER_APP_KEY=test');
    pusher = FakePusher();
    client = FakeClient();
    container = ProviderContainer(
      overrides: [
        authStatusProvider.overrideWith(Session.new),
        apiClientProvider.overrideWithValue(client),
        supportQueueProvider.overrideWith(Queue.new),
        messageEventsProvider.overrideWith(
          (ref) => MessageEventsService(
            ref,
            pusher: pusher,
            queueRefreshInterval: queueRefreshInterval,
          ),
        ),
      ],
    );
    container.read(currentUserProvider.notifier).set(user('me'));
    service = container.read(messageEventsProvider);
    for (var i = 0; i < 10; i++) {
      await Future<void>.value();
    }
    await container.read(supportQueueProvider.future);
    for (var i = 0; i < 10; i++) {
      await Future<void>.value();
    }
  }

  tearDown(() {
    service.dispose();
    container.dispose();
  });
  test('closing foreground preserves background message delivery', () async {
    await setup();
    final received = <String>[];
    final sub = service.threadChanges.listen(received.add);
    await service.watchConversation('c');
    await service.unwatchConversation('c');
    pusher.emit('private-conversation-c', 'message.new', {'senderId': 'other'});
    for (var i = 0; i < 10; i++) {
      await Future<void>.value();
    }
    expect(received, ['c']);
    await sub.cancel();
  });
  test('account changes reconnect without an auth-status change', () async {
    await setup();
    container.read(currentUserProvider.notifier).set(user('second'));
    for (var i = 0; i < 10; i++) {
      await Future<void>.value();
    }
    expect(pusher.connections, 2);
    expect(pusher.callbacks.containsKey('private-user-me'), false);
    expect(pusher.callbacks.containsKey('private-user-second'), true);
  });
  testWidgets('remote typing expires after six seconds', (tester) async {
    await setup();
    pusher.emit('private-conversation-c', 'client-typing', {
      'userId': 'other',
      'name': 'Client',
      'isTyping': true,
    });
    expect(service.typingSnapshot('c'), {'other': 'Client'});
    await tester.pump(const Duration(seconds: 6));
    expect(service.typingSnapshot('c'), isEmpty);
  });
  test('reconnect catches up subscribed conversations', () async {
    await setup();
    final ids = <String>[];
    final sub = service.catchUpConversations.listen(ids.add);
    pusher.states.add(RealtimeConnectionState.connected);
    for (var i = 0; i < 10; i++) {
      await Future<void>.value();
    }
    expect(ids, ['c']);
    await sub.cancel();
  });
  test('reassignment revokes foreground subscriptions too', () async {
    await setup();
    await service.watchConversation('c');
    (container.read(supportQueueProvider.notifier) as Queue).reassign();
    for (var i = 0; i < 20; i++) {
      await Future<void>.value();
    }
    expect(pusher.callbacks['private-conversation-c']?['message.new'], isEmpty);
  });

  testWidgets(
    'background delivery batches only received foreign IDs up to 100',
    (tester) async {
      await setup();
      for (var i = 0; i < 205; i++) {
        pusher.emit('private-conversation-c', 'message.new', {
          'messageId': 'm$i',
          'senderId': 'other',
        });
      }
      pusher.emit('private-conversation-c', 'message.new', {
        'messageId': 'mine',
        'senderId': 'me',
      });
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(client.receipts.map((ids) => ids.length), [100, 100, 5]);
      expect(client.receipts.expand((ids) => ids), isNot(contains('mine')));
    },
  );
  testWidgets('account switch discards pending background receipts', (
    tester,
  ) async {
    await setup();
    pusher.emit('private-conversation-c', 'message.new', {
      'messageId': 'old',
      'senderId': 'other',
    });
    container.read(currentUserProvider.notifier).set(user('next'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(client.receipts, isEmpty);
  });
  test(
    'reclaim restores dormant foreground presence without reopening',
    () async {
      await setup();
      await service.watchConversation('c');
      final queue = container.read(supportQueueProvider.notifier) as Queue;
      queue.reassign();
      for (var i = 0; i < 30; i++) {
        await Future<void>.value();
      }
      expect(
        pusher.callbacks['private-conversation-c']?['message.new'],
        isEmpty,
      );
      queue.reassign('me');
      for (var i = 0; i < 30; i++) {
        await Future<void>.value();
      }
      expect(
        pusher.callbacks['private-conversation-c']?['message.new']?.length,
        1,
      );
      expect(
        pusher
            .callbacks['presence-conversation-c']?['pusher_internal:subscription_succeeded']
            ?.length,
        1,
      );
    },
  );
  test('generic support notification refreshes the staff queue', () async {
    await setup();
    final before = Queue.loads;
    pusher.emit('private-user-me', 'notification', {
      'type': 'message.new',
      'data': {'visibility': 'observer'},
    });
    // Invalidation is scheduled on Riverpod's next event-loop turn, not a
    // microtask. Reading the future forces that scheduled rebuild to finish.
    await container.read(supportQueueProvider.future);
    for (var i = 0; i < 30; i++) {
      await Future<void>.value();
    }
    expect(Queue.loads, before + 1);
  });
  testWidgets('staff queue fallback refreshes at bounded intervals', (
    tester,
  ) async {
    await setup(queueRefreshInterval: const Duration(seconds: 30));
    final before = Queue.loads;
    await tester.pump(const Duration(seconds: 29));
    expect(Queue.loads, before);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(Queue.loads, before + 1);
    service.dispose();
    // pump() only flushes microtasks. Explicit zero duration advances fake
    // time too, executing Riverpod's Timer.run auto-disposal task.
    await tester.pump(Duration.zero);
  });
}
