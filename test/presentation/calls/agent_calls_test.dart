import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_calls/support.dart';
import 'package:supplies_chat_app/core/calls/agent_calls.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations_fr.dart';
import 'package:supplies_chat_app/presentation/pages/calls/call_copy.dart';
import 'package:supplies_chat_app/presentation/pages/calls/widgets/agent_call_widgets.dart';

class FakeActions implements AgentCallActions {
  final log = <String>[];
  bool? granted = true;
  @override
  Future<void> accept(String callId) async => log.add('accept:$callId');
  @override
  Future<void> reject(String callId) async => log.add('reject:$callId');
  @override
  Future<void> setAvailability(String mode) async => log.add('mode:$mode');
  @override
  Future<void> callback(String conversationId) async =>
      log.add('callback:$conversationId');
  @override
  Future<void> end() async => log.add('end');
  @override
  Future<bool?> microphoneGranted() async => granted;
  @override
  Future<void> requestMicrophone() async => log.add('microphone');
}

SupportCall offer(
  String id,
  String name,
  DateTime createdAt, {
  SupportCallStatus status = SupportCallStatus.ringing,
  DateTime? acceptedAt,
  bool isCallback = false,
  Set<String> declinedBy = const {},
}) => SupportCall(
  id: id,
  isCallback: isCallback,
  caller: SupportCallActor(id: 'c-$id', name: name, role: 'client'),
  context: SupportCallContext(
    conversationId: 'conv-$id',
    reference: 'REF-$id',
    kind: 'delivery',
  ),
  status: status,
  createdAt: createdAt,
  expiresAt: createdAt.add(const Duration(minutes: 2)),
  acceptedAt: acceptedAt,
  endedAt: status == SupportCallStatus.ringing
      ? null
      : createdAt.add(const Duration(minutes: 1)),
  offers: const {'agent'},
  declinedBy: declinedBy,
);

Widget app(List<Override> overrides, Widget child) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('lists every offer oldest first and answers the tapped one', (
    tester,
  ) async {
    final now = DateTime.now().toUtc();
    final actions = FakeActions();
    final offers = [
      offer('b', 'Kofi', now.subtract(const Duration(seconds: 10))),
      offer('a', 'Ama', now.subtract(const Duration(seconds: 50))),
      offer('c', 'Yao', now.subtract(const Duration(seconds: 2))),
    ];
    await tester.pumpWidget(
      app([
        agentCallsProvider.overrideWithValue(
          AgentCallsSnapshot(
            identity: 'agent',
            incoming: offers,
            availability: SupportAgentAvailability.available,
          ),
        ),
        agentCallActionsProvider.overrideWithValue(actions),
      ], const IncomingCallsPanel()),
    );
    expect(find.text('3 appels entrants'), findsOneWidget);
    expect(find.byType(IncomingCallTile), findsNWidgets(3));
    final top = [
      for (final name in ['Ama', 'Kofi', 'Yao'])
        tester.getTopLeft(find.text(name)).dy,
    ];
    expect(top[0] < top[1] && top[1] < top[2], isTrue);
    expect(find.textContaining('REF-b'), findsOneWidget);
    expect(find.textContaining('Attend depuis'), findsNWidgets(3));

    await tester.tap(find.byKey(const ValueKey('accept-b')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('decline-c')));
    await tester.pump();
    expect(actions.log, ['accept:b', 'reject:c']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('availability toggle switches between available and paused', (
    tester,
  ) async {
    final actions = FakeActions();
    await tester.pumpWidget(
      app([
        agentCallsProvider.overrideWithValue(
          const AgentCallsSnapshot(
            identity: 'agent',
            availability: SupportAgentAvailability.available,
          ),
        ),
        agentCallActionsProvider.overrideWithValue(actions),
      ], const AvailabilityToggle()),
    );
    expect(find.text('Disponible'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('availability-switch')));
    await tester.pump();
    expect(actions.log, ['mode:paused']);
  });

  testWidgets('pausing then resuming explains the microphone first', (
    tester,
  ) async {
    final actions = FakeActions()..granted = false;
    await tester.pumpWidget(
      app([
        agentCallsProvider.overrideWithValue(
          const AgentCallsSnapshot(
            identity: 'agent',
            availability: SupportAgentAvailability.paused,
          ),
        ),
        agentCallActionsProvider.overrideWithValue(actions),
      ], const AvailabilityToggle()),
    );
    expect(find.text('En pause'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('availability-switch')));
    await tester.pumpAndSettle();
    expect(find.text('Accès au microphone'), findsOneWidget);
    expect(actions.log, isEmpty);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    // Still denied after the OS prompt: availability is not switched on.
    expect(actions.log, ['microphone']);
  });

  testWidgets('busy and offline are shown but cannot be toggled', (
    tester,
  ) async {
    for (final (mode, label) in [
      (SupportAgentAvailability.busy, 'En appel'),
      (SupportAgentAvailability.offline, 'Hors ligne'),
    ]) {
      await tester.pumpWidget(
        app([
          agentCallsProvider.overrideWithValue(
            AgentCallsSnapshot(identity: 'agent', availability: mode),
          ),
          agentCallActionsProvider.overrideWithValue(FakeActions()),
        ], const AvailabilityToggle()),
      );
      expect(find.text(label), findsOneWidget);
      final toggle = tester.widget<Switch>(
        find.byKey(const ValueKey('availability-switch')),
      );
      expect(toggle.onChanged, isNull);
    }
  });

  testWidgets('waiting indicator shows the queue while in a call', (
    tester,
  ) async {
    await tester.pumpWidget(
      app([
        agentCallsProvider.overrideWithValue(
          const AgentCallsSnapshot(identity: 'agent', queueLength: 3),
        ),
      ], const CallsWaitingIndicator()),
    );
    expect(find.text('3 appels en attente'), findsOneWidget);
  });

  group('missed calls', () {
    final now = DateTime.utc(2026, 11, 13, 10);
    final missed = offer('m1', 'Ama', now, status: SupportCallStatus.expired);
    final cancelled = offer(
      'm2',
      'Kofi',
      now,
      status: SupportCallStatus.cancelled,
    );
    final answered = offer(
      'ok',
      'Yao',
      now,
      status: SupportCallStatus.ended,
      acceptedAt: now.add(const Duration(seconds: 5)),
    );
    final declined = offer(
      'no',
      'Efua',
      now,
      status: SupportCallStatus.expired,
      declinedBy: {'agent'},
    );
    final callback = offer(
      'cb',
      'Akua',
      now,
      status: SupportCallStatus.expired,
      isCallback: true,
    );

    test('one predicate: unanswered, not declined by viewer, no callback', () {
      expect(supportCallMissedFor(missed, 'agent'), isTrue);
      expect(supportCallMissedFor(cancelled, 'agent'), isTrue);
      expect(supportCallMissedFor(answered, 'agent'), isFalse);
      expect(supportCallMissedFor(declined, 'agent'), isFalse);
      expect(supportCallMissedFor(declined, 'colleague'), isTrue);
      expect(supportCallMissedFor(callback, 'agent'), isFalse);
      expect(
        supportCallMissedFor(offer('live', 'Live', now), 'agent'),
        isFalse,
      );
    });

    test('badge counts missed calls since the history was viewed', () async {
      final container = ProviderContainer(
        overrides: [
          agentCallsProvider.overrideWithValue(
            AgentCallsSnapshot(
              identity: 'agent',
              history: [missed, cancelled, answered, declined, callback],
              historyLoaded: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(missedCallsCountProvider), 2);
      container.read(missedCallsSeenProvider.notifier).state = now.add(
        const Duration(hours: 1),
      );
      expect(container.read(missedCallsCountProvider), 0);
    });
  });

  test('every call error code has a localized message', () {
    final l10n = AppLocalizationsFr();
    const codes = [
      'unauthorized',
      'forbidden',
      'unavailable',
      'busy',
      'already_taken',
      'not_found',
      'not_accepted',
      'network',
      'audio',
      'microphone_permission',
      'disabled',
      'rate_limited',
      'other_device',
    ];
    final messages = {for (final code in codes) CallCopy.error(l10n, code)};
    expect(messages.length, codes.length);
    expect(messages, isNot(contains(l10n.callErrorGeneric)));
    expect(
      CallCopy.error(l10n, 'other_device'),
      'Appel pris sur un autre appareil',
    );
    expect(CallCopy.error(l10n, 'something_new'), l10n.callErrorGeneric);
  });
}
