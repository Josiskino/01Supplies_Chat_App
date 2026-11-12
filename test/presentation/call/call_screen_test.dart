import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_calls/support.dart';
import 'package:supplies_chat_app/presentation/pages/call/call_screen.dart';

class FakeCallController extends SupportCallController {
  FakeCallController(this.initial);
  final SupportCallState initial;
  bool accepted = false;
  bool rejected = false;
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
  Future<void> accept() async {
    accepted = true;
  }

  @override
  Future<void> reject() async {
    rejected = true;
  }
}

void main() {
  testWidgets('terminal support call shows outcome without live controls', (
    tester,
  ) async {
    final now = DateTime.now();
    final controller = FakeCallController(
      SupportCallState(
        isAgent: true,
        active: SupportCall(
          id: 'unavailable',
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
          status: SupportCallStatus.unavailable,
          createdAt: now,
          expiresAt: now,
          endedAt: now,
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportCallControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: CallScreen()),
      ),
    );
    expect(find.text('Support indisponible'), findsOneWidget);
    expect(find.text('Connexion audio…'), findsNothing);
    expect(find.text('Raccrocher'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('accepted audio controls invoke the real controller', (
    tester,
  ) async {
    final now = DateTime.now();
    final controller = FakeCallController(
      SupportCallState(
        isAgent: true,
        active: SupportCall(
          id: 'connected',
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
          status: SupportCallStatus.accepted,
          createdAt: now,
          expiresAt: now,
          connectedAt: now.subtract(const Duration(seconds: 65)),
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportCallControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: CallScreen()),
      ),
    );
    expect(find.text('1 min 5 s'), findsOneWidget);
    await tester.tap(find.text('Couper le micro'));
    expect(controller.muted, isTrue);
    await tester.tap(find.text('Haut-parleur'));
    expect(controller.speaker, isTrue);
    await tester.tap(find.text('Raccrocher'));
    expect(controller.ended, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'incoming call uses real caller and answer/refuse actions without group or video fixtures',
    (tester) async {
      final now = DateTime.now();
      final controller = FakeCallController(
        SupportCallState(
          isAgent: true,
          active: SupportCall(
            id: 'real',
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
            status: SupportCallStatus.ringing,
            createdAt: now,
            expiresAt: now.add(const Duration(seconds: 45)),
          ),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportCallControllerProvider.overrideWith(() => controller),
          ],
          child: const MaterialApp(home: CallScreen()),
        ),
      );
      expect(find.text('Ama Test'), findsOneWidget);
      expect(find.text('01DEL-123'), findsOneWidget);
      expect(find.text('Appel audio entrant'), findsOneWidget);
      for (final label in ['Inviter', 'Caméra', 'Plus', '@awa', '00:00']) {
        expect(find.text(label), findsNothing);
      }
      await tester.tap(find.text('Répondre'));
      expect(controller.accepted, isTrue);
      await tester.tap(find.text('Refuser'));
      expect(controller.rejected, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
