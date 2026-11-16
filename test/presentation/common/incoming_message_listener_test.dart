import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supplies_chat_app/config/router/app_router.dart';
import 'package:supplies_chat_app/core/constants/app_ui_route.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/core/providers/realtime/push_provider.dart';
import 'package:supplies_chat_app/core/providers/realtime/realtime_provider.dart';
import 'package:supplies_chat_app/core/services/message_events_service.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_list_entry.dart';
import 'package:supplies_chat_app/presentation/widgets/common/incoming_message_listener.dart';
import 'package:supplies_chat_app/presentation/widgets/common/push_navigation.dart';

class _Inbox extends SupportQueue {
  _Inbox(this.entries);
  final List<ConversationListEntry> entries;
  int refreshes = 0;
  @override
  Future<List<ConversationListEntry>> build() async => entries;
  @override
  void requestRefresh() => refreshes++;
}

ConversationListEntry _entry(String conversationId, {String? ticketId}) =>
    ConversationListEntry(
      conversationId: conversationId,
      title: 'Client',
      preview: '',
      date: DateTime.utc(2026, 11, 16),
      ticketId: ticketId,
      isSupport: ticketId != null,
    );

/// App shaped like the real one: splash at `/`, shell at `/main`.
GoRouter _appRouter({String initial = AppUiRoute.main}) => GoRouter(
  initialLocation: initial,
  routes: [
    GoRoute(
      path: AppUiRoute.splash,
      builder: (_, _) => const Scaffold(body: Text('Splash')),
    ),
    GoRoute(
      path: AppUiRoute.login,
      builder: (_, _) => const Scaffold(body: Text('Login')),
    ),
    GoRoute(
      path: AppUiRoute.main,
      builder: (_, _) => const Scaffold(body: Text('Inbox')),
    ),
    GoRoute(
      path: AppUiRoute.conversationDetail,
      builder: (_, state) =>
          Scaffold(body: Text('Thread ${state.pathParameters['id']}')),
    ),
  ],
);

Future<void> _pumpApp(
  WidgetTester tester,
  GoRouter router,
  Stream<PushRoute> opened, {
  _Inbox? inbox,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appRouterProvider.overrideWithValue(router),
        pushRouteProvider.overrideWith((ref) => opened),
        incomingMessageProvider.overrideWith(
          (ref) => const Stream<IncomingMessage>.empty(),
        ),
        if (inbox != null) supportQueueProvider.overrideWith(() => inbox),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (_, child) => MessagingApplicationLayer(child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final cupertino in [false, true]) {
    testWidgets(
      '${cupertino ? 'Cupertino' : 'Material'} foreground banner opens its thread',
      (tester) async {
        final incoming = StreamController<IncomingMessage>();
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('Inbox')),
            ),
            GoRoute(
              path: '/conversation/:id',
              builder: (_, state) =>
                  Scaffold(body: Text('Thread ${state.pathParameters['id']}')),
            ),
          ],
        );
        addTearDown(incoming.close);
        addTearDown(router.dispose);
        Widget wrap(BuildContext context, Widget? child) =>
            MessagingApplicationLayer(child: child!);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appRouterProvider.overrideWithValue(router),
              pushRouteProvider.overrideWith(
                (ref) => const Stream<PushRoute>.empty(),
              ),
              incomingMessageProvider.overrideWith((ref) => incoming.stream),
            ],
            child: cupertino
                ? CupertinoApp.router(
                    routerConfig: router,
                    localizationsDelegates: const [
                      DefaultMaterialLocalizations.delegate,
                    ],
                    builder: wrap,
                  )
                : MaterialApp.router(routerConfig: router, builder: wrap),
          ),
        );
        await tester.pumpAndSettle();
        incoming.add(
          const IncomingMessage(
            conversationId: 'thread-42',
            author: 'Amina',
            preview: 'New message',
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('New message'), findsOneWidget);
        await tester.tap(find.text('Ouvrir'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Thread thread-42'), findsOneWidget);
        expect(router.canPop(), isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('opened push navigates from the application builder wrapper', (
    tester,
  ) async {
    final opened = StreamController<PushRoute>();
    final router = GoRouter(
      initialLocation: AppUiRoute.main,
      routes: [
        GoRoute(
          path: AppUiRoute.main,
          builder: (_, _) => const Scaffold(body: Text('Inbox')),
        ),
        GoRoute(
          path: '/conversation/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Thread ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(opened.close);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRouterProvider.overrideWithValue(router),
          pushRouteProvider.overrideWith((ref) => opened.stream),
          incomingMessageProvider.overrideWith(
            (ref) => const Stream<IncomingMessage>.empty(),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (_, child) => MessagingApplicationLayer(child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();

    opened.add(
      const PushRoute(conversationId: 'thread-42', title: 'Conversation'),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Thread thread-42'), findsOneWidget);
    // Native imperative pushes need not update the platform URL.
    expect(router.canPop(), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('push navigation', () {
    test('waits while the router is on the splash or login', () {
      expect(canOpenPushedConversation(''), isFalse);
      expect(canOpenPushedConversation(AppUiRoute.splash), isFalse);
      expect(canOpenPushedConversation(AppUiRoute.login), isFalse);
      expect(canOpenPushedConversation(AppUiRoute.main), isTrue);
      expect(
        canOpenPushedConversation(AppUiRoute.conversationDetailPath('x')),
        isTrue,
      );
    });

    test('resolves a ticket-only route through the inbox', () {
      final inbox = [_entry('direct'), _entry('support', ticketId: 't1')];
      expect(
        resolvePushConversationId(
          const PushRoute(conversationId: 'c', ticketId: 't1'),
          inbox,
        ),
        'c',
      );
      expect(
        resolvePushConversationId(const PushRoute(ticketId: 't1'), inbox),
        'support',
      );
      expect(
        resolvePushConversationId(const PushRoute(ticketId: 'gone'), inbox),
        isNull,
      );
      expect(resolvePushConversationId(const PushRoute(), inbox), isNull);
    });

    testWidgets('cold start: a tap queued on the splash opens after main', (
      tester,
    ) async {
      final opened = StreamController<PushRoute>();
      final router = _appRouter(initial: AppUiRoute.splash);
      addTearDown(opened.close);
      addTearDown(router.dispose);
      await _pumpApp(tester, router, opened.stream);
      expect(find.text('Splash'), findsOneWidget);

      opened.add(const PushRoute(conversationId: 'conv-1'));
      await tester.pumpAndSettle();
      // Still restoring the session: nothing is pushed above the splash.
      expect(find.text('Splash'), findsOneWidget);
      expect(find.text('Thread conv-1'), findsNothing);

      // The auth redirect replaces the splash with the shell.
      router.go(AppUiRoute.main);
      await tester.pumpAndSettle();
      expect(find.text('Thread conv-1'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Inbox'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('support ticket push opens its conversation', (tester) async {
      final opened = StreamController<PushRoute>();
      final router = _appRouter();
      final inbox = _Inbox([_entry('support-conv', ticketId: 'ticket-7')]);
      addTearDown(opened.close);
      addTearDown(router.dispose);
      await _pumpApp(tester, router, opened.stream, inbox: inbox);
      // Load the inbox the way the shell does.
      final container = ProviderScope.containerOf(
        tester.element(find.text('Inbox')),
      );
      final keep = container.listen(supportQueueProvider, (_, _) {});
      addTearDown(keep.close);
      await tester.pumpAndSettle();

      opened.add(const PushRoute(ticketId: 'ticket-7'));
      await tester.pumpAndSettle();
      expect(find.text('Thread support-conv'), findsOneWidget);
      expect(inbox.refreshes, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('conversation missing from the inbox opens and refreshes it', (
      tester,
    ) async {
      final opened = StreamController<PushRoute>();
      final router = _appRouter();
      final inbox = _Inbox([_entry('known')]);
      addTearDown(opened.close);
      addTearDown(router.dispose);
      await _pumpApp(tester, router, opened.stream, inbox: inbox);
      final container = ProviderScope.containerOf(
        tester.element(find.text('Inbox')),
      );
      final keep = container.listen(supportQueueProvider, (_, _) {});
      addTearDown(keep.close);
      await tester.pumpAndSettle();

      opened.add(const PushRoute(conversationId: 'new-direct'));
      await tester.pumpAndSettle();
      expect(find.text('Thread new-direct'), findsOneWidget);
      expect(inbox.refreshes, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('unresolvable ticket and repeated tap do not navigate', (
      tester,
    ) async {
      final opened = StreamController<PushRoute>();
      final router = _appRouter();
      addTearDown(opened.close);
      addTearDown(router.dispose);
      await _pumpApp(tester, router, opened.stream);

      opened.add(const PushRoute(ticketId: 'unknown'));
      await tester.pumpAndSettle();
      expect(find.text('Inbox'), findsOneWidget);
      expect(router.canPop(), isFalse);

      opened.add(const PushRoute(conversationId: 'conv-2'));
      await tester.pumpAndSettle();
      opened.add(const PushRoute(conversationId: 'conv-2'));
      await tester.pumpAndSettle();
      expect(find.text('Thread conv-2'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      // Only one copy of the thread was pushed.
      expect(find.text('Inbox'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
