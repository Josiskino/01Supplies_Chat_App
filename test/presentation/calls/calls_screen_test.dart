import 'package:calls_domain/calls_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplies_calls/support.dart'
    hide SupportCall, SupportCallActor, SupportCallContext, SupportCallStatus;
import 'package:supplies_chat_app/core/calls/agent_calls.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/presentation/pages/calls/calls_screen.dart';

SupportCall historyCall({
  SupportCallStatus status = SupportCallStatus.ended,
  bool answered = true,
}) {
  final now = DateTime.utc(2026, 11, 12, 10);
  return SupportCall(
    id: 'call-1',
    caller: const SupportCallActor(
      id: 'client',
      name: 'Ama Test',
      role: 'client',
    ),
    context: const SupportCallContext(
      conversationId: 'real-conversation',
      reference: '01DEL-123',
      kind: 'delivery',
    ),
    status: status,
    createdAt: now,
    expiresAt: now.add(const Duration(seconds: 45)),
    acceptedAt: answered ? now.add(const Duration(seconds: 4)) : null,
    connectedAt: answered ? now.add(const Duration(seconds: 8)) : null,
    endedAt: now.add(const Duration(seconds: 73)),
    agentId: answered ? 'colleague' : null,
    agentName: answered ? 'Afi' : null,
  );
}

class HistoryController extends SupportCallController {
  HistoryController(this.calls, {this.loaded = true});
  final bool loaded;
  int viewed = 0;
  final List<SupportCall> calls;
  @override
  SupportCallState build() =>
      SupportCallState(history: calls, historyLoaded: loaded);
  void loadedHistory() {
    state = state.copy(history: calls, historyLoaded: true);
  }

  @override
  Future<void> markHistoryViewed() async {
    viewed++;
  }

  @override
  Future<void> refreshHistory() async {}
}

void main() {
  testWidgets(
    'marks loaded history only when its tab is visible, once per visit',
    (tester) async {
      final controller = HistoryController([], loaded: false);
      final selected = ValueNotifier<int>(0);
      addTearDown(selected.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportCallsEnabledProvider.overrideWithValue(true),
            supportCallControllerProvider.overrideWith(() => controller),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: ValueListenableBuilder<int>(
              valueListenable: selected,
              builder: (_, index, _) => IndexedStack(
                index: index,
                children: [
                  const SizedBox(),
                  CallsScreen(isVisible: index == 1),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(controller.viewed, 0);
      selected.value = 1;
      await tester.pump();
      expect(
        controller.viewed,
        0,
        reason: 'initial empty state is not loaded history',
      );
      selected.value = 0;
      await tester.pump();
      controller.loadedHistory();
      await tester.pump();
      expect(
        controller.viewed,
        0,
        reason: 'background refresh must not clear missed calls',
      );
      selected.value = 1;
      await tester.pump();
      await tester.pump();
      expect(
        controller.viewed,
        1,
        reason: 'visible loaded empty history clears the aggregate',
      );
      controller.loadedHistory();
      await tester.pump();
      expect(controller.viewed, 1);
      selected.value = 0;
      await tester.pump();
      selected.value = 1;
      await tester.pump();
      await tester.pump();
      expect(controller.viewed, 2);
    },
  );

  testWidgets(
    'each occurrence stays separate and missed filter excludes colleague answers',
    (tester) async {
      final missed = historyCall(
        status: SupportCallStatus.expired,
        answered: false,
      );
      final answered = historyCall();
      // Different IDs, same caller: each server occurrence must remain a row.
      final second = SupportCall(
        id: 'call-2',
        caller: answered.caller,
        context: answered.context,
        status: answered.status,
        createdAt: answered.createdAt,
        expiresAt: answered.expiresAt,
        acceptedAt: answered.acceptedAt,
        connectedAt: answered.connectedAt,
        endedAt: answered.endedAt,
        agentId: answered.agentId,
        agentName: answered.agentName,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportCallsEnabledProvider.overrideWithValue(true),
            supportCallControllerProvider.overrideWith(
              () => HistoryController([missed, second]),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: CallsScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SupportCallHistoryRow), findsNWidgets(2));
      await tester.tap(find.text('Manqués'));
      await tester.pumpAndSettle();
      expect(find.byType(SupportCallHistoryRow), findsOneWidget);
      expect(find.text('Répondu par Afi'), findsNothing);
    },
  );

  testWidgets(
    'real history shows caller context answering agent and actual audio duration',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(body: SupportCallHistoryRow(call: historyCall())),
        ),
      );
      expect(find.text('Ama Test'), findsOneWidget);
      expect(find.text('Client · 01DEL-123'), findsOneWidget);
      expect(find.text('Répondu par Afi'), findsOneWidget);
      expect(find.text('1 min 5 s'), findsOneWidget);
      expect(find.text('Rappeler'), findsNothing);
    },
  );

  test('missed follows the single spec predicate', () {
    // Answered by a colleague: never missed for anyone.
    expect(supportCallMissedFor(historyCall(), 'agent'), isFalse);
    expect(
      supportCallMissedFor(
        historyCall(status: SupportCallStatus.expired, answered: false),
        'agent',
      ),
      isTrue,
    );
    // Caller hung up before anyone answered: missed (spec §1.5).
    expect(
      supportCallMissedFor(
        historyCall(status: SupportCallStatus.cancelled, answered: false),
        'agent',
      ),
      isTrue,
    );
  });

  testWidgets(
    'cancelled unavailable and missed calls keep distinct labels and no duration',
    (tester) async {
      for (final entry in {
        SupportCallStatus.cancelled: 'Annulé',
        SupportCallStatus.unavailable: 'Support indisponible',
        SupportCallStatus.expired: 'Manqué',
      }.entries) {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Scaffold(
              body: SupportCallHistoryRow(
                call: historyCall(status: entry.key, answered: false),
              ),
            ),
          ),
        );
        expect(find.textContaining(entry.value), findsOneWidget);
        expect(find.text('1 min 5 s'), findsNothing);
        expect(find.text('Répondu par Afi'), findsNothing);
      }
    },
  );
}
