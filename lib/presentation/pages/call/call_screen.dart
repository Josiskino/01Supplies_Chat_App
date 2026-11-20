import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supplies_calls/support.dart';

import '../../../core/calls/agent_calls.dart';
import '../../../core/constants/app_ui_route.dart';
import '../../../core/platform/app_platform.dart';
import '../../../core/utils/localization_helper.dart';
import '../../desktop/widgets/presence_avatar.dart';
import '../calls/call_copy.dart';
import '../calls/widgets/agent_call_widgets.dart';
import 'widgets/call_backdrop.dart';

/// Audio support session. Navigation never starts or ends a call.
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key, this.title});
  final String? title;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  Timer? _clock;
  final _backdropSeed = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    // This only refreshes the display; elapsed time comes from connectedAt.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationHelper.of(context);
    final state = ref.watch(supportCallControllerProvider);
    final calls = ref.watch(agentCallsProvider);
    final actions = ref.read(agentCallActionsProvider);
    final speech = ref.watch(supportCallSpeechProvider);
    // An offer opened from the banner or a notification is not active yet.
    final incoming = calls.active == null && calls.incoming.isNotEmpty;
    final call = calls.active ?? calls.incoming.firstOrNull;
    final connected = call?.connectedAt != null;
    final canControl = call?.status == SupportCallStatus.accepted;
    final health = switch (state.health) {
      AudioHealth.healthy => null,
      AudioHealth.localPoor => l10n.callHealthLocalPoor,
      AudioHealth.remotePoor => l10n.callHealthRemotePoor,
      AudioHealth.reconnecting => l10n.callHealthReconnecting,
    };
    final otherAgent =
        call?.agentName != null &&
        call?.agentId != null &&
        call?.agentId != calls.identity;
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        backgroundColor: const Color(0xFF07070A),
        body: CallBackdrop(
          seed: _backdropSeed,
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: l10n.callMinimize,
                    onPressed: () {
                      if (context.canPop()) context.pop();
                    },
                    icon: const Icon(Icons.keyboard_arrow_down),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          if (call != null) ...[
                            // The halo lights up while the caller speaks.
                            SpeakingHalo(
                              level: speech?.remoteLevel ?? _silent,
                              size: 112,
                              color: PresenceAvatar.colorForName(
                                call.caller.name,
                              ),
                              child: PresenceAvatar(
                                name: call.caller.name,
                                avatarUrl: call.caller.avatarUrl,
                                size: 112,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              call.caller.name,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(CallCopy.role(l10n, call.caller.role)),
                            Text(
                              call.context.reference,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              key: const ValueKey('call-status'),
                              !call.isActive
                                  ? {
                                      CallCopy.status(
                                        l10n,
                                        call,
                                        viewerId: calls.identity,
                                      ),
                                      ?CallCopy.endReason(
                                        l10n,
                                        call,
                                        viewerId: calls.identity,
                                      ),
                                    }.join(' · ')
                                  : connected
                                  ? CallCopy.duration(
                                      l10n,
                                      call.durationAt(DateTime.now()),
                                    )
                                  : incoming
                                  ? l10n.callIncomingAudio
                                  : call.status == SupportCallStatus.ringing
                                  ? l10n.callStatusRinging
                                  : l10n.callConnecting,
                            ),
                            if (!call.isActive && connected)
                              Text(
                                CallCopy.duration(
                                  l10n,
                                  call.durationAt(DateTime.now()),
                                ),
                              ),
                            if (otherAgent)
                              Text(l10n.callAnsweredBy(call.agentName!)),
                            if (connected && call.isActive && speech != null)
                              ValueListenableBuilder<bool>(
                                valueListenable: speech.remoteMuted,
                                builder: (context, muted, _) => muted
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.mic_off, size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              key: const ValueKey(
                                                'call-peer-muted',
                                              ),
                                              l10n.callPeerMuted,
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              key: const ValueKey('open-conversation'),
                              onPressed: () => context.push(
                                AppUiRoute.conversationDetailPath(
                                  call.context.conversationId,
                                ),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: Text(l10n.callOpenConversation),
                            ),
                            if (calls.inCall)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: CallsWaitingIndicator(),
                              ),
                          ] else if (state.busy && state.error == null) ...[
                            // The call request is in flight: the server has
                            // not returned the call yet, so show progress
                            // instead of an empty "no call" screen.
                            const SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              key: const ValueKey('call-placing'),
                              l10n.callPlacing,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ] else
                            Text(l10n.callNoActive),
                          if (health != null && call != null && call.isActive)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(health),
                            ),
                          if (state.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                CallCopy.error(l10n, state.error!),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      if (incoming) ...[
                        FilledButton.icon(
                          onPressed: state.busy
                              ? null
                              : () => actions.reject(call!.id),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          icon: const Icon(Icons.call_end),
                          label: Text(l10n.incomingCallDecline),
                        ),
                        FilledButton.icon(
                          onPressed: state.busy
                              ? null
                              : () =>
                                    acceptIncomingCall(context, ref, call!.id),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          icon: const Icon(Icons.call),
                          label: Text(l10n.incomingCallAccept),
                        ),
                      ] else if (call != null && call.isActive) ...[
                        if (canControl) ...[
                          OutlinedButton.icon(
                            onPressed: state.busy
                                ? null
                                : () => ref
                                      .read(
                                        supportCallControllerProvider.notifier,
                                      )
                                      .setMuted(!state.muted),
                            icon: Icon(state.muted ? Icons.mic_off : Icons.mic),
                            label: Text(
                              state.muted ? l10n.callUnmute : l10n.callMute,
                            ),
                          ),
                          // Desktop has no earpiece to switch from.
                          if (!AppPlatform.current.isDesktop)
                            OutlinedButton.icon(
                              key: const ValueKey('call-speaker'),
                              onPressed: state.busy
                                  ? null
                                  : () => ref
                                        .read(
                                          supportCallControllerProvider
                                              .notifier,
                                        )
                                        .setSpeaker(!state.speaker),
                              icon: Icon(callRouteIcon(state)),
                              label: Text(callRouteLabel(l10n, state)),
                            ),
                        ],
                        FilledButton.icon(
                          onPressed: state.busy ? null : () => actions.end(),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          icon: const Icon(Icons.call_end),
                          label: Text(l10n.callHangUp),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _silent = AlwaysStoppedAnimation<double>(0);

/// Speaker control icon: the current private device (Bluetooth, headset)
/// when one is in use, otherwise the speaker / earpiece toggle.
IconData callRouteIcon(SupportCallState state) => state.speaker
    ? Icons.volume_up
    : switch (state.audioRoute) {
        CallAudioRoute.bluetooth => Icons.bluetooth_audio,
        CallAudioRoute.wired => Icons.headset,
        _ => Icons.hearing,
      };

/// Speaker control label: names the private device in use, otherwise the
/// action (switch to the other of speaker / earpiece).
String callRouteLabel(AppLocalizations l10n, SupportCallState state) =>
    state.speaker
    ? l10n.callEarpiece
    : switch (state.audioRoute) {
        CallAudioRoute.bluetooth => l10n.callAudioBluetooth,
        CallAudioRoute.wired => l10n.callAudioHeadset,
        _ => l10n.callSpeaker,
      };
