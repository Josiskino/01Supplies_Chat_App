import 'package:calls_domain/calls_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supplies_calls/support.dart'
    hide SupportCall, SupportCallActor, SupportCallContext, SupportCallStatus;
import 'package:supplies_chat_app/config/theme/theme.dart';
import 'package:supplies_chat_app/core/calls/agent_calls.dart';
import 'package:supplies_chat_app/core/constants/app_ui_route.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations_fr.dart';
import 'package:supplies_chat_app/presentation/pages/calls/call_copy.dart';
import 'package:supplies_chat_app/presentation/pages/calls/calls_screen.dart';
import 'package:supplies_chat_app/presentation/widgets/inbox/conversation_title.dart';

import 'agent_calls_test.dart' show FakeActions;

final _at = DateTime(2026, 11, 16, 19, 45);

SupportCall _call({
  String id = 'call-1',
  String name = 'John DOE',
  String role = 'client',
  String reference = '01DEL-MVDUG32G',
  SupportCallStatus status = SupportCallStatus.ended,
  bool answered = true,
  bool callback = false,
  String? agentId = 'colleague',
  String agentName = 'Super Admin',
  Set<String> declinedBy = const {},
  DateTime? at,
}) {
  final created = at ?? _at;
  return SupportCall(
    id: id,
    isCallback: callback,
    caller: SupportCallActor(id: 'c-$id', name: name, role: role),
    context: SupportCallContext(
      conversationId: 'conv-$id',
      reference: reference,
      kind: 'delivery',
    ),
    status: status,
    createdAt: created,
    expiresAt: created.add(const Duration(seconds: 45)),
    acceptedAt: answered ? created.add(const Duration(seconds: 4)) : null,
    connectedAt: answered ? created.add(const Duration(seconds: 6)) : null,
    endedAt: created.add(const Duration(seconds: 44)),
    agentId: answered || callback ? agentId : null,
    agentName: answered || callback ? agentName : null,
    declinedBy: declinedBy,
  );
}

Widget _host(Widget child, {bool dark = false}) => Builder(
  builder: (context) => MaterialApp(
    theme: TAppTheme.lightThemeData(context),
    darkTheme: TAppTheme.darkThemeData(context),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: Scaffold(body: child),
  ),
);

String _detail(WidgetTester tester, String id) => tester
    .widget<RichText>(
      find
          .descendant(
            of: find.byKey(ValueKey('call-detail-$id')),
            matching: find.byType(RichText),
          )
          .first,
    )
    .text
    .toPlainText()
    .replaceAll('￼', '');

void main() {
  final l10n = AppLocalizationsFr();

  group('row layout', () {
    testWidgets('renders two compact lines, not a five-line block', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SupportCallHistoryRow(call: _call(), now: _at, onCallback: () {}),
        ),
      );
      final row = tester.getSize(find.byType(SupportCallHistoryRow));
      expect(row.height, lessThan(80));
      expect(find.text('John DOE'), findsOneWidget);
      expect(find.text('(01DEL-MVDUG32G)'), findsOneWidget);
      expect(_detail(tester, 'call-1'), 'Entrant · 38 s · Super Admin');
      final detail = tester.widget<Text>(
        find.byKey(const ValueKey('call-detail-call-1')),
      );
      expect(detail.maxLines, 1);
      // The old verbose lines are gone.
      expect(find.textContaining('Répondu par'), findsNothing);
      expect(find.textContaining('Client ·'), findsNothing);
      expect(find.text('Rappeler'), findsNothing, reason: 'tooltip only');
    });

    testWidgets('missed incoming calls paint the name red', (tester) async {
      await tester.pumpWidget(
        _host(
          SupportCallHistoryRow(
            call: _call(status: SupportCallStatus.expired, answered: false),
            viewerId: 'agent',
            now: _at,
          ),
        ),
      );
      final context = tester.element(find.byType(SupportCallHistoryRow));
      final name = tester.widget<Text>(find.byKey(ConversationTitle.nameKey));
      expect(name.style?.color, Theme.of(context).colorScheme.error);
      expect(_detail(tester, 'call-1'), 'Manqué');
      expect(find.byKey(const ValueKey('call-kind-missed')), findsOneWidget);
    });

    testWidgets('answered calls keep the default name colour', (tester) async {
      await tester.pumpWidget(
        _host(
          SupportCallHistoryRow(call: _call(), viewerId: 'agent', now: _at),
        ),
      );
      final context = tester.element(find.byType(SupportCallHistoryRow));
      final name = tester.widget<Text>(find.byKey(ConversationTitle.nameKey));
      expect(name.style?.color, Theme.of(context).colorScheme.onSurface);
      expect(find.byKey(const ValueKey('call-kind-incoming')), findsOneWidget);
    });

    testWidgets('short status per outcome, duration only when answered', (
      tester,
    ) async {
      final cases = <SupportCall, String>{
        _call(id: 'out', callback: true): 'Sortant · 38 s · Super Admin',
        _call(
          id: 'noanswer',
          callback: true,
          answered: false,
          status: SupportCallStatus.expired,
        ): 'Sans réponse · Super Admin',
        _call(
          id: 'refused',
          answered: false,
          status: SupportCallStatus.rejected,
          declinedBy: {'agent'},
        ): 'Refusé',
        _call(id: 'mine', agentId: 'agent'): 'Entrant · 38 s · Vous',
      };
      for (final entry in cases.entries) {
        await tester.pumpWidget(
          _host(
            SupportCallHistoryRow(call: entry.key, viewerId: 'agent', now: _at),
          ),
        );
        expect(
          _detail(tester, entry.key.id),
          entry.value,
          reason: entry.key.id,
        );
      }
    });

    testWidgets('no reference: no empty parentheses', (tester) async {
      await tester.pumpWidget(
        _host(
          SupportCallHistoryRow(
            call: _call(reference: ' '),
            now: _at,
          ),
        ),
      );
      expect(find.byKey(ConversationTitle.orderKey), findsNothing);
      expect(find.textContaining('()'), findsNothing);
    });

    testWidgets('call-back button fires the action and exposes "Rappeler"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          SupportCallHistoryRow(
            call: _call(),
            now: _at,
            onCallback: () => taps++,
          ),
        ),
      );
      expect(find.byTooltip('Rappeler'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Rappeler')),
        matchesSemantics(label: 'Rappeler', isButton: true, hasTapAction: true),
      );
      await tester.tap(find.byKey(const ValueKey('callback-call-1')));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('no button without action, slot kept when reserved', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              SupportCallHistoryRow(
                key: const ValueKey('a'),
                call: _call(id: 'a'),
                now: _at,
                onCallback: () {},
              ),
              SupportCallHistoryRow(
                key: const ValueKey('b'),
                call: _call(id: 'b'),
                now: _at,
                reserveCallbackSlot: true,
              ),
            ],
          ),
        ),
      );
      expect(find.byKey(const ValueKey('callback-b')), findsNothing);
      // Times line up whether the row can call back or not.
      expect(
        tester.getTopRight(find.byKey(const ValueKey('call-time-a'))).dx,
        tester.getTopRight(find.byKey(const ValueKey('call-time-b'))).dx,
      );
    });

    for (final dark in [false, true]) {
      testWidgets('no overflow at 320 px with long names and references '
          '(${dark ? 'dark' : 'light'})', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _host(
            dark: dark,
            MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 568),
                textScaler: TextScaler.linear(1.3),
              ),
              child: Column(
                children: [
                  SupportCallHistoryRow(
                    call: _call(
                      name: 'Ama Kossiwa Mensah-Agbodjan Lawson Akakpo',
                      reference: '01-ORD 1731600000000AB12CD',
                      agentName: 'Super Administrateur Régional',
                      callback: true,
                    ),
                    now: _at,
                    onCallback: () {},
                  ),
                  SupportCallHistoryRow(
                    call: _call(
                      id: 'call-2',
                      name: 'Restaurant Le Grand Baobab de Lomé',
                      role: 'vendor',
                      status: SupportCallStatus.expired,
                      answered: false,
                    ),
                    now: _at.add(const Duration(days: 40)),
                    reserveCallbackSlot: true,
                  ),
                ],
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final row = tester.getSize(find.byType(SupportCallHistoryRow).first);
        expect(row.width, 320);
        expect(row.height, lessThan(96));
      });
    }
  });

  group('time column', () {
    test('today shows the hour', () {
      expect(CallCopy.historyTime(l10n, _at, now: _at), '19:45');
      expect(
        CallCopy.historyTime(
          l10n,
          DateTime(2026, 11, 16, 0, 5),
          now: DateTime(2026, 11, 16, 23, 59),
        ),
        '00:05',
      );
    });

    test('yesterday, across a month boundary too', () {
      expect(
        CallCopy.historyTime(l10n, _at, now: DateTime(2026, 11, 17, 0, 1)),
        'Hier',
      );
      expect(
        CallCopy.historyTime(
          l10n,
          DateTime(2026, 10, 31, 23),
          now: DateTime(2026, 11, 1, 8),
        ),
        'Hier',
      );
    });

    test('older shows day/month, with the year when it differs', () {
      expect(
        CallCopy.historyTime(l10n, DateTime(2026, 11, 12, 19, 45), now: _at),
        '12/11',
      );
      expect(
        CallCopy.historyTime(l10n, DateTime(2025, 12, 30), now: _at),
        '30/12/25',
      );
    });
  });

  group('calls screen', () {
    Widget screen(FakeActions actions, List<SupportCall> history) {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CallsScreen()),
          GoRoute(
            path: AppUiRoute.call,
            builder: (_, _) => const Text('call-screen'),
          ),
          GoRoute(
            path: '/conversation/:id',
            builder: (_, _) => const Text('conversation-screen'),
          ),
        ],
      );
      return ProviderScope(
        overrides: [
          supportCallsEnabledProvider.overrideWithValue(true),
          agentCallActionsProvider.overrideWithValue(actions),
          agentCallsProvider.overrideWithValue(
            AgentCallsSnapshot(
              identity: 'agent',
              history: history,
              historyLoaded: true,
              availability: SupportAgentAvailability.available,
            ),
          ),
          supportCallControllerProvider.overrideWith(_IdleController.new),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
        ),
      );
    }

    testWidgets('call-back button calls the customer back on its thread', (
      tester,
    ) async {
      final actions = FakeActions();
      await tester.pumpWidget(screen(actions, [_call()]));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('callback-call-1')));
      await tester.pumpAndSettle();
      expect(actions.log, ['callback:conv-call-1']);
      expect(find.text('call-screen'), findsOneWidget);
    });

    testWidgets('drivers get no call-back button', (tester) async {
      await tester.pumpWidget(screen(FakeActions(), [_call(role: 'driver')]));
      await tester.pump();
      expect(find.byKey(const ValueKey('callback-call-1')), findsNothing);
    });

    testWidgets('Tous / Manqués filter still narrows the list', (tester) async {
      await tester.pumpWidget(
        screen(FakeActions(), [
          _call(id: 'answered'),
          _call(
            id: 'missed',
            status: SupportCallStatus.expired,
            answered: false,
          ),
        ]),
      );
      await tester.pump();
      expect(find.byType(SupportCallHistoryRow), findsNWidgets(2));
      await tester.tap(find.text('Manqués'));
      await tester.pumpAndSettle();
      expect(find.byType(SupportCallHistoryRow), findsOneWidget);
      expect(find.byKey(const ValueKey('missed')), findsOneWidget);
      await tester.tap(find.text('Tous'));
      await tester.pumpAndSettle();
      expect(find.byType(SupportCallHistoryRow), findsNWidgets(2));
    });

    testWidgets('last row clears the floating tab bar', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 600),
            padding: EdgeInsets.only(bottom: 98),
          ),
          child: screen(FakeActions(), [_call()]),
        ),
      );
      await tester.pump();
      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.padding?.resolve(TextDirection.ltr).bottom, greaterThan(98));
    });
  });
}

class _IdleController extends SupportCallController {
  @override
  SupportCallState build() => const SupportCallState();

  @override
  Future<void> refreshHistory() async {}

  @override
  Future<void> markHistoryViewed() async {}
}
