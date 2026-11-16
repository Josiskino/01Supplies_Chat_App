import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/message_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/pinned_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/core/utils/refresh_gate.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_list_entry.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_entity.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/conversation_detail_screen.dart';
import 'package:supplies_chat_app/presentation/pages/conversations/conversations_screen.dart';

import '../../helpers/test_environment.dart';

const _failure = 'Actualisation impossible. Réessayez.';

/// Inbox whose refresh is held open until the test releases it.
class _Queue extends SupportQueue {
  int refreshes = 0;
  Completer<bool>? pending;

  @override
  Future<List<ConversationListEntry>> build() async => [
    ConversationListEntry(
      conversationId: 'c1',
      title: 'Ama Client',
      preview: 'Bonjour',
      date: DateTime.utc(2026, 11, 10),
      ticketId: 't1',
      isSupport: true,
    ),
  ];

  @override
  Future<bool> refresh() {
    refreshes++;
    return (pending = Completer<bool>()).future;
  }
}

class _Pins extends PinnedConversations {
  @override
  Set<String> build() => {};
}

/// Thread whose catch-up refresh is held open, and can fail like the real
/// one does (a `syncError` on the kept messages).
class _Thread extends Thread {
  int refreshes = 0;
  Completer<void>? pending;
  bool fail = false;

  @override
  Future<ThreadState> build(String conversationId) async => ThreadMessages([
    for (var i = 0; i < 3; i++)
      MessageEntity(
        id: 'm$i',
        conversationId: conversationId,
        senderId: i.isEven ? 'client' : 'me',
        content: 'Message $i',
        type: MessageType.text,
        delivery: MessageDelivery.read,
        sentAt: DateTime.now().subtract(Duration(minutes: 10 - i)),
      ),
  ]);

  @override
  Future<void> markRead() async {}

  @override
  Future<void> refresh() async {
    refreshes++;
    await (pending = Completer<void>()).future;
    final current = state.value;
    if (fail && current is ThreadMessages) {
      state = AsyncData(
        ThreadMessages(current.messages, syncError: 'Actualisation impossible'),
      );
    }
  }
}

void main() {
  setUpAll(setUpTestEnvironment);

  Future<void> pumpHost(
    WidgetTester tester, {
    required AppPlatform platform,
    required Widget home,
    List overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPlatformProvider.overrideWithValue(platform),
          currentUserIdProvider.overrideWithValue('me'),
          pinnedConversationsProvider.overrideWith(_Pins.new),
          ...overrides.cast(),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: home,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// Lets the Material indicator snap into place and call `onRefresh`.
  Future<void> settleIndicator(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('inbox', () {
    late _Queue queue;

    Future<void> pumpInbox(WidgetTester tester, AppPlatform platform) async {
      queue = _Queue();
      await pumpHost(
        tester,
        platform: platform,
        home: const ConversationsScreen(),
        overrides: [supportQueueProvider.overrideWith(() => queue)],
      );
    }

    testWidgets('Android: Material indicator, one refresh until data arrives', (
      tester,
    ) async {
      await pumpInbox(tester, AppPlatform.android);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(
        find.byType(CupertinoSliverRefreshControl, skipOffstage: false),
        findsNothing,
      );

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await settleIndicator(tester);
      expect(queue.refreshes, 1);
      // The spinner stays while the API has not answered.
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);

      // A second pull while the first is in flight does not refetch.
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await settleIndicator(tester);
      expect(queue.refreshes, 1);

      queue.pending!.complete(true);
      await tester.pumpAndSettle();
      expect(find.byType(RefreshProgressIndicator), findsNothing);
      expect(find.text(_failure), findsNothing);
      expect(queue.refreshes, 1);
    });

    testWidgets('Android: a failed refresh shows the error toast', (
      tester,
    ) async {
      await pumpInbox(tester, AppPlatform.android);
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await settleIndicator(tester);
      queue.pending!.complete(false);
      await tester.pumpAndSettle();

      expect(find.text(_failure), findsOneWidget);
      // The list stays on screen.
      expect(find.text('Ama Client'), findsOneWidget);
    });

    testWidgets('iOS: native sliver control, refresh on pull', (tester) async {
      await pumpInbox(tester, AppPlatform.ios);
      // Collapsed at rest: zero extent, hence "offstage" for the finder.
      expect(
        find.byType(CupertinoSliverRefreshControl, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byType(RefreshIndicator), findsNothing);

      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, 160),
        touchSlopY: 0,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(queue.refreshes, 1);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

      queue.pending!.complete(true);
      await tester.pumpAndSettle();
      expect(queue.refreshes, 1);
    });
  });

  group('thread', () {
    late _Thread thread;

    Future<void> pumpThread(WidgetTester tester, AppPlatform platform) async {
      thread = _Thread();
      await pumpHost(
        tester,
        platform: platform,
        home: const ConversationDetailScreen(conversationId: 'c1'),
        overrides: [
          supportQueueProvider.overrideWith(_Queue.new),
          threadProvider('c1').overrideWith(() => thread),
        ],
      );
    }

    /// Pull-down at the visual top of the reversed list.
    Future<void> pullThread(WidgetTester tester) async {
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await settleIndicator(tester);
    }

    testWidgets('Android: pull at the top refreshes the thread once', (
      tester,
    ) async {
      await pumpThread(tester, AppPlatform.android);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(tester.widget<ListView>(find.byType(ListView)).reverse, isTrue);

      await pullThread(tester);
      expect(thread.refreshes, 1);
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);

      await pullThread(tester);
      expect(thread.refreshes, 1);

      thread.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(RefreshProgressIndicator), findsNothing);
      expect(find.text(_failure), findsNothing);
      // The messages already shown are kept.
      expect(
        find.textContaining('Message 0', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a failed thread refresh shows the error toast', (
      tester,
    ) async {
      await pumpThread(tester, AppPlatform.android);
      thread.fail = true;
      await pullThread(tester);
      thread.pending!.complete();
      await tester.pumpAndSettle();

      expect(find.text(_failure), findsOneWidget);
      expect(
        find.textContaining('Message 0', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('iOS: reversed list uses the Cupertino activity indicator', (
      tester,
    ) async {
      await pumpThread(tester, AppPlatform.ios);
      // The sliver control cannot live in a reversed list.
      expect(
        find.byType(CupertinoSliverRefreshControl, skipOffstage: false),
        findsNothing,
      );

      await pullThread(tester);
      expect(thread.refreshes, 1);
      expect(
        find.descendant(
          of: find.byType(RefreshIndicator),
          matching: find.byType(CupertinoActivityIndicator),
        ),
        findsOneWidget,
      );
      expect(find.byType(RefreshProgressIndicator), findsNothing);

      thread.pending!.complete();
      await tester.pumpAndSettle();
    });
  });

  group('RefreshGate', () {
    test('joins a refresh already in flight', () async {
      final gate = RefreshGate();
      final release = Completer<void>();
      var runs = 0;
      Future<void> task() {
        runs++;
        return release.future;
      }

      final first = gate.run(task);
      final second = gate.run(task);
      expect(runs, 1);
      expect(gate.isRefreshing, isTrue);
      release.complete();
      await Future.wait([first, second]);
      expect(gate.isRefreshing, isFalse);

      await gate.run(() async => runs++);
      expect(runs, 2);
    });

    test('a failing refresh releases the gate', () async {
      final gate = RefreshGate();
      await expectLater(
        gate.run(() async => throw StateError('x')),
        throwsStateError,
      );
      expect(gate.isRefreshing, isFalse);
    });
  });
}
