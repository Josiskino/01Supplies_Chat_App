import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_calls/support.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/presentation/pages/call/call_screen.dart';

class FakeCallController extends SupportCallController {
  FakeCallController(this.initial);
  final SupportCallState initial;
  String? accepted;
  String? rejected;
  bool? muted;
  bool? speaker;
  bool ended = false;
  @override
  Future<void> setMuted([bool? value]) async {
    muted = value;
  }

  @override
  Future<void> setSpeaker([bool? value]) async {
    speaker = value;
  }

  @override
  Future<void> end() async {
    ended = true;
  }

  @override
  SupportCallState build() => initial;
  @override
  Future<void> accept([String? callId]) async {
    accepted = callId;
  }

  @override
  Future<void> reject([String? callId]) async {
    rejected = callId;
  }
}

SupportCall supportCall({
  String id = 'call',
  SupportCallStatus status = SupportCallStatus.accepted,
  bool isCallback = false,
  Set<String> offers = const {},
  String? agentId,
  DateTime? connectedAt,
  DateTime? endedAt,
}) {
  final now = DateTime.now();
  return SupportCall(
    id: id,
    isCallback: isCallback,
    caller: const SupportCallActor(
      id: 'client',
      name: 'Ama Test',
      role: 'client',
    ),
    context: const SupportCallContext(
      conversationId: 'conversation',
      reference: '01DEL-123',
      kind: 'delivery',
    ),
    status: status,
    createdAt: now,
    expiresAt: now.add(const Duration(seconds: 45)),
    connectedAt: connectedAt,
    endedAt: endedAt,
    agentId: agentId,
    agentName: agentId == null ? null : 'Afi',
    offers: offers,
  );
}

Widget host(FakeCallController controller) => ProviderScope(
  overrides: [supportCallControllerProvider.overrideWith(() => controller)],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: Locale('fr'),
    home: CallScreen(),
  ),
);

void main() {
  testWidgets('terminal support call shows outcome without live controls', (
    tester,
  ) async {
    final controller = FakeCallController(
      SupportCallState(
        isAgent: true,
        identity: 'agent',
        active: supportCall(
          status: SupportCallStatus.unavailable,
          endedAt: DateTime.now(),
        ),
      ),
    );
    await tester.pumpWidget(host(controller));
    expect(find.textContaining('Support indisponible'), findsOneWidget);
    expect(find.text('Connexion audio…'), findsNothing);
    expect(find.text('Raccrocher'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('accepted audio controls invoke the real controller', (
    tester,
  ) async {
    final controller = FakeCallController(
      SupportCallState(
        isAgent: true,
        identity: 'agent',
        active: supportCall(
          agentId: 'agent',
          connectedAt: DateTime.now().subtract(const Duration(seconds: 65)),
        ),
      ),
    );
    await tester.pumpWidget(host(controller));
    expect(find.text('1 min 5 s'), findsOneWidget);
    // The agent is not told they are talking "with" themselves.
    expect(find.text('Répondu par Afi'), findsNothing);
    await tester.tap(find.text('Couper le micro'));
    expect(controller.muted, isTrue);
    await tester.tap(find.text('Haut-parleur'));
    expect(controller.speaker, isTrue);
    await tester.tap(find.text('Raccrocher'));
    expect(controller.ended, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('incoming offer is answered and declined by its id', (
    tester,
  ) async {
    final offer = supportCall(
      id: 'real',
      status: SupportCallStatus.ringing,
      offers: {'agent'},
    );
    final controller = FakeCallController(
      SupportCallState(
        isAgent: true,
        identity: 'agent',
        active: offer,
        incoming: [offer],
      ),
    );
    await tester.pumpWidget(host(controller));
    expect(find.text('Ama Test'), findsOneWidget);
    expect(find.text('01DEL-123'), findsOneWidget);
    expect(find.text('Appel audio entrant'), findsOneWidget);
    for (final label in ['Inviter', 'Caméra', 'Plus', '@awa', '00:00']) {
      expect(find.text(label), findsNothing);
    }
    await tester.tap(find.text('Répondre'));
    await tester.pump();
    expect(controller.accepted, 'real');
    await tester.tap(find.text('Refuser'));
    expect(controller.rejected, 'real');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('outgoing callback shows ringing, not audio connection', (
    tester,
  ) async {
    final controller = FakeCallController(
      SupportCallState(
        isAgent: true,
        identity: 'agent',
        active: supportCall(
          status: SupportCallStatus.ringing,
          isCallback: true,
          agentId: 'agent',
        ),
      ),
    );
    await tester.pumpWidget(host(controller));
    expect(find.text('Sonnerie…'), findsOneWidget);
    expect(find.text('Connexion audio…'), findsNothing);
    expect(find.text('Répondre'), findsNothing);
    expect(find.text('Raccrocher'), findsOneWidget);
    expect(find.text('Ouvrir la conversation'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('error codes are localized, never shown raw', (tester) async {
    final controller = FakeCallController(
      SupportCallState(
        isAgent: true,
        identity: 'agent',
        error: 'other_device',
        active: supportCall(
          status: SupportCallStatus.ended,
          endedAt: DateTime.now(),
        ),
      ),
    );
    await tester.pumpWidget(host(controller));
    expect(find.text('Appel pris sur un autre appareil'), findsOneWidget);
    expect(find.text('other_device'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
