import 'package:flutter/foundation.dart';
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

class FakeSpeech implements SupportSpeechLevels {
  final remote = ValueNotifier<double>(0);
  final muted = ValueNotifier<bool>(false);
  @override
  ValueListenable<double> get remoteLevel => remote;
  @override
  ValueListenable<double> get localLevel => const AlwaysStoppedAnimation(0);
  @override
  ValueListenable<bool> get remoteMuted => muted;
}

Widget host(FakeCallController controller, {SupportSpeechLevels? speech}) =>
    ProviderScope(
      overrides: [
        supportCallControllerProvider.overrideWith(() => controller),
        supportCallSpeechProvider.overrideWithValue(speech),
      ],
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

  testWidgets('the caller avatar carries the halo and a muted peer is shown', (
    tester,
  ) async {
    final speech = FakeSpeech();
    final controller = FakeCallController(
      SupportCallState(
        isAgent: true,
        identity: 'agent',
        mediaConnected: true,
        active: supportCall(agentId: 'agent', connectedAt: DateTime.now()),
      ),
    );
    await tester.pumpWidget(host(controller, speech: speech));
    expect(find.byType(SpeakingHalo), findsOneWidget);
    expect(find.text('Son micro est coupé'), findsNothing);
    speech.muted.value = true;
    await tester.pump();
    expect(find.text('Son micro est coupé'), findsOneWidget);
    speech.remote.value = 0.8;
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
  });

  test('the speaker control follows the real audio route', () {
    final l10n = lookupAppLocalizations(const Locale('fr'));
    const base = SupportCallState();
    expect(callRouteLabel(l10n, base), 'Haut-parleur');
    expect(callRouteIcon(base), Icons.hearing);
    expect(callRouteLabel(l10n, base.copy(speaker: true)), 'Écouteur');
    expect(callRouteIcon(base.copy(speaker: true)), Icons.volume_up);
    final bluetooth = base.copy(audioRoute: CallAudioRoute.bluetooth);
    expect(callRouteLabel(l10n, bluetooth), 'Bluetooth');
    expect(callRouteIcon(bluetooth), Icons.bluetooth_audio);
    final wired = base.copy(audioRoute: CallAudioRoute.wired);
    expect(callRouteLabel(l10n, wired), 'Casque');
    expect(callRouteIcon(wired), Icons.headset);
  });
}
