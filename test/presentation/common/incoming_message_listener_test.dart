import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supplies_chat_app/config/router/app_router.dart';
import 'package:supplies_chat_app/core/providers/realtime/push_provider.dart';
import 'package:supplies_chat_app/core/providers/realtime/realtime_provider.dart';
import 'package:supplies_chat_app/core/services/message_events_service.dart';
import 'package:supplies_chat_app/presentation/widgets/common/incoming_message_listener.dart';

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
}
